.latest_debian_series <- function(date) {
  if (is.null(date)) date <- Sys.Date()
  sapply(
    X = date,
    FUN = function(idate) {
      data.table::fread("/usr/share/distro-info/debian.csv", fill = TRUE)[
        !is.na(release) & as.Date(release) <= as.Date(idate),
        data.table::last(series)
      ]
    }
  )
}

.get_latest_tag <- function(repo) {
  httr2::request(sprintf("https://api.github.com/repos/%s/git/refs/tags", repo)) |>
    httr2::req_headers("Accept" = "application/vnd.github.v3+json") |>
    httr2::req_url_query(per_page = 1, page = 1) |>
    httr2::req_perform() |>
    httr2::resp_body_json() |>
    tail(100) |>
    (function(x) {
      tags <- sapply(x, function(.x) {
         sub("refs/tags/v*", "", unlist(.x, recursive = FALSE)[["ref"]])
      })
      tags <- tags[!grepl("[[:alpha:]]", tags)]
      tags[max(numeric_version(sub("\\+", ".", tags))) == numeric_version(sub("\\+", ".", tags))]
    })()
}

.latest_rstudio_version <- function() {
  .get_latest_tag("rstudio/rstudio")
}

.latest_umr1283_version <- function() {
  .get_latest_tag("umr1283/umr1283")
}

.latest_bcftools_version <- function() {
  .get_latest_tag("samtools/bcftools")
}


.r_versions_data <- function(min_version) {
  data.table::as.data.table(rversions::r_versions())[
    i = package_version(version) >= package_version(min_version),
    j = list(
      r_version = version,
      release_date = as.Date(date),
      freeze_date = data.table::shift(as.Date(date), type = "lead") - 1
    )
  ]
}

.generate_tags <- function(
  base_name,
  r_version,
  r_latest = FALSE,
  use_latest_tag = TRUE,
  tag_suffix = "",
  latest_tag = "latest"
) {
  c(
    list(paste0(base_name, ":", r_version, tag_suffix)),
    if (r_latest & use_latest_tag) list(paste0(base_name, ":", latest_tag))
  )
}

.update_default_stacks <- function(
  docker_repository,
  stack_file,
  r_version,
  rstudio_version,
  umr1283_version,
  bcftools_version
) {
  template <- jsonlite::read_json(stack_file)

  # r-ver
  template$stack[[1]]$labels$org.opencontainers.image.title <- sub(
    "[^/]*", docker_repository,
    template$stack[[1]]$labels$org.opencontainers.image.title
  )

  # umr1283
  template$stack[[2]]$labels$org.opencontainers.image.title <- sub(
    "[^/]*", docker_repository,
    template$stack[[2]]$labels$org.opencontainers.image.title
  )
  template$stack[[2]]$FROM <- sub("[^/]*", docker_repository, template$stack[[2]]$FROM)
  template$stack[[2]]$ENV$UMR1283_VERSION <- umr1283_version
  template$stack[[2]]$ENV$BCFTOOLS_VERSION <- bcftools_version

  # RStudio
  template$stack[[3]]$labels$org.opencontainers.image.title <- sub(
    "[^/]*", docker_repository,
    template$stack[[3]]$labels$org.opencontainers.image.title
  )
  template$stack[[3]]$FROM <- sub("[^/]*", docker_repository, template$stack[[3]]$FROM)
  template$stack[[3]]$ENV$RSTUDIO_VERSION <- rstudio_version

  # ssh
  template$stack[[4]]$labels$org.opencontainers.image.title <- sub(
    "[^/]*", docker_repository,
    template$stack[[4]]$labels$org.opencontainers.image.title
  )
  template$stack[[4]]$FROM <- sub("[^/]*", docker_repository, template$stack[[4]]$FROM)

  # shiny
  template$stack[[5]]$labels$org.opencontainers.image.title <- sub(
    "[^/]*", docker_repository,
    template$stack[[5]]$labels$org.opencontainers.image.title
  )
  template$stack[[5]]$FROM <- sub("[^/]*", docker_repository, template$stack[[5]]$FROM)

  jsonlite::write_json(template, stack_file, pretty = TRUE, auto_unbox = TRUE)
  message(sprintf('Updating "%s" with latest versions.', stack_file))
  invisible(stack_file)
}

.write_stack <- function(
  base,
  r_version,
  debian_version,
  rstudio_version,
  umr1283_version,
  cran,
  r_latest,
  default_stacks
) {
  template <- jsonlite::read_json(default_stacks)
  output_path <- sprintf("%s/%s.json", dirname(default_stacks), r_version)

  template$TAG <- r_version

  # template$group <- list(c(list(
  #   default = list(c(list(targets = c(
  #     "r-ver",
  #     "ssh",
  #     "rstudio"
  #   ))))
  # )))

  # r-ver
  template$stack[[1]]$FROM <- paste0("debian:", debian_version)
  template$stack[[1]]$ENV$R_VERSION <- r_version
  template$stack[[1]]$tags <- list(
    .generate_tags(sprintf("docker.io/%s/r-ver", base), r_version, r_latest),
    .generate_tags("docker.io/umr1283/r-ver", r_version, r_latest)
  )
  template$stack[[1]]$platforms <- list("linux/amd64", "linux/arm64")
  template$stack[[1]]$`cache-from` <- list(sprintf("docker.io/%s/r-ver:%s", base, r_version))
  template$stack[[1]]$`cache-to` <- list("type=inline")

  # umr1283
  template$stack[[2]]$FROM <- sprintf("%s/r-ver:%s", base, r_version)
  template$stack[[2]]$ENV$UMR1283_VERSION <- umr1283_version
  template$stack[[2]]$tags <- list(
    .generate_tags(sprintf("docker.io/%s/umr1283", base), r_version, r_latest),
    .generate_tags("docker.io/umr1283/umr1283", r_version, r_latest)
  )

  # rstudio
  template$stack[[3]]$FROM <- sprintf("%s/umr1283:%s", base, r_version)
  template$stack[[3]]$ENV$RSTUDIO_VERSION <- rstudio_version
  template$stack[[3]]$tags <- list(
    .generate_tags(sprintf("docker.io/%s/rstudio", base), r_version, r_latest),
    .generate_tags("docker.io/umr1283/rstudio", r_version, r_latest)
  )

  # ssh
  template$stack[[4]]$FROM <- sprintf("%s/umr1283:%s", base, r_version)
  template$stack[[4]]$tags <- list(
    .generate_tags(sprintf("docker.io/%s/ssh", base), r_version, r_latest),
    .generate_tags("docker.io/umr1283/ssh", r_version, r_latest)
  )

  # shiny
  template$stack[[5]]$FROM <- sprintf("%s/umr1283:%s", base, r_version)
  template$stack[[5]]$tags <- list(
    .generate_tags(sprintf("docker.io/%s/shiny", base), r_version, r_latest),
    .generate_tags("docker.io/umr1283/shiny", r_version, r_latest)
  )

  jsonlite::write_json(template, output_path, pretty = TRUE, auto_unbox = TRUE)

  message(sprintf('  * "%s"', output_path))
  output_path
}

write_stacks <- function(docker_repository, stack_file, min_version = "4.1", debian = NULL) {
  r_latest <- r_version <- NULL # only to get rif of "no visible binding for global variable"
  if (!dir.exists(dirname(stack_file))) {
    dir.create(dirname(stack_file), recursive = TRUE)
  }

  r_versions_dt <- .r_versions_data(min_version = min_version)[
    i = order(release_date),
    j = `:=`(r_latest = seq_len(.N) == .N)
  ]

  r_latest_version <- r_versions_dt[(r_latest), r_version]
  rstudio_latest_version <- .latest_rstudio_version()
  umr1283_latest_version <- .latest_umr1283_version()
  bcftools_latest_version <- .latest_bcftools_version()

  .update_default_stacks(
    docker_repository = docker_repository,
    stack_file = stack_file,
    r_version = r_latest_version,
    rstudio_version = rstudio_latest_version,
    umr1283_version = umr1283_latest_version,
    bcftools_version = bcftools_latest_version
  )

  message("Writing stack JSON files:")

  devnull <- r_versions_dt[
    j = stack_path := .write_stack(
      base = docker_repository,
      r_version = r_version,
      debian_version = if (is.null(debian)) .latest_debian_series(release_date) else debian,
      rstudio_version = rstudio_latest_version,
      umr1283_version = umr1283_latest_version,
      cran = "https://cran.r-project.org",
      r_latest = r_latest,
      default_stacks = stack_file
    ),
    by = "r_version"
  ]

  invisible()
}

inherit_global <- function(image, global) {
  c(image, global[!names(global) %in% names(image)])
}

paste_if <- function(element, image) {
  na.omit(c(sapply(
    X = element,
    image = image,
    FUN = function(el, image) {
      key <- sub("_.*", "", el)
      value <- unlist(image[[el]])

      if (is.null(value)) return(NA)

      if (!is.null(names(value))) {
        out <- paste0(key, " ", names(value), "=", value, collapse = "\n")
      } else {
        out <- paste0(key, " ", value, collapse = "\n")
      }

      paste0(out, "\n")
    }
  )))
}

write_dockerfiles <- function(stack_directory, dockerfiles_directory) {
  stopifnot(dir.exists(stack_directory))

  if (!dir.exists(dockerfiles_directory)) {
    dir.create(dockerfiles_directory, recursive = TRUE)
  }

  message("Writing Dockerfile files:")

  devnull <- lapply(
    X = list.files(stack_directory, pattern = "\\.json$", full.names = TRUE),
    dockerfiles_directory = dockerfiles_directory,
    FUN = function(stack_file, dockerfiles_directory) {
      stack <- jsonlite::read_json(stack_file)
      lapply(
        X = stack$stack,
        global = stack[!(names(stack) %in% c("ordered", "stack"))],
        dd = dockerfiles_directory,
        FUN = function(image, global, dd) {
          img <- inherit_global(image, global)
          path <- sprintf("%s/%s_%s.Dockerfile", dd, img$IMAGE, img$TAG)
          writeLines(
            text = paste_if(
              element = c("FROM", "LABEL", "ENV", "COPY", "RUN", "EXPOSE", "CMD", "USER"),
              image = img
            ),
            con = path
          )
          message(sprintf('  * "%s"', path))
        }
      )
    }
  )

  invisible()
}

write_compose <- function(stack_file, compose_file = "docker-compose.yml", dockerfiles_directory) {
  stopifnot(file.exists(stack_file))

  if (!dir.exists(dirname(compose_file))) dir.create(dirname(compose_file), recursive = TRUE)

  message("Writing compose YAML file:")

  json <- yaml::read_yaml(stack_file) # jsonlite::read_json(stack_file)

  org <- sub("/.*", "", json$stack[[1]]$labels$org.opencontainers.image.title)

  global <- json[!(names(json) %in% c("ordered", "stack"))]
  json_stack <- lapply(json$stack, inherit_global, global)

  ordered <- isTRUE(json$ordered)

  map_chr <- function(x, name) vapply(x, `[[`, character(1L), name)

  name <- map_chr(json_stack, "IMAGE")
  tag <-  map_chr(json_stack, "TAG")

  dockerfiles <- sprintf("%s/%s_%s.Dockerfile", dockerfiles_directory, name, tag)
  names(dockerfiles) <- name

  image <- paste(name, tag, sep = "-")

  ## we only enforce order if requested
  depends_on <- rep("", length(image))
  if (ordered) {
    depends_on <- c("", image[1:(length(image) - 1)])
  }

  not_blank <- function(x) if (x == "") return(NULL) else x
  is_empty <- function(x) length(x) == 0 || is.null(x)
  compact <- function(l) Filter(Negate(is_empty), l)

  services <- vector("list", length(dockerfiles))
  names(services) <- image
  for (i in seq_along(dockerfiles)) {
    dockerfile <- dockerfiles[[i]]
    services[[i]] <- compact(list(
      image = sub("_", ":", sub("\\.Dockerfile$", "", sub("[^/]*", org, dockerfile))),
      depends_on = compact(list(not_blank(depends_on[i]))),
      build = list(context = "..", dockerfile = dockerfile)
    ))
  }

  yaml::write_yaml(
    x = list(version = "3", services =  services),
    file = compose_file
  )

  message(sprintf('  * "%s"', compose_file))

  invisible()
}

.transpose <- function(x) {
  tmp <- x[
    j = list(content = list(as.list(.SD))),
    by = "name"
  ]
  lapply(
    X = `names<-`(tmp[["content"]], tmp[["name"]]),
    FUN = function(el) {
      unlist(`attr<-`(el, ".data.table.locked", NULL), recursive = FALSE)
    }
  )
}

.bake_list <- function(stack_file, dockerfiles_directory) {
  stack_content <- jsonlite::read_json(stack_file)
  stack_tag <- stack_content$TAG

  dt <- data.table::data.table(stack = stack_content$stack)[
    j = list(
      "name" = sapply(stack, `[[`, "IMAGE"),
      "context" = "./",
      "dockerfile" = sprintf(
        "%s/%s_%s.Dockerfile",
        dockerfiles_directory, sapply(stack, `[[`, "IMAGE"), stack_tag
      ),
      "labels" = lapply(
        X = stack,
        FUN = function(x) {
          if (grepl("/",  x[["FROM"]])) {
            pattern <- "docker.io/%s"
          } else {
            pattern <- "docker.io/library/%s"
          }
          if (!grepl(":",  x[["FROM"]])) {
            pattern <- sprintf("%s:latest", pattern)
          }

          c(
            x[["labels"]],
            "org.opencontainers.image.base.name" = sprintf(pattern, x[["FROM"]]),
            "org.opencontainers.image.version" = if (grepl("^(\\d+\\.){3}$", stack_tag)) stack_tag
          )
        }
      ),
     "tags" = lapply(
        X = stack,
        tag = stack_tag,
        FUN = function(x, tag) {
          x_field <- x[["tags"]]
          if (is.null(x_field)) {
            list(sprintf("docker.io/%s:%s", x[["labels"]][["org.opencontainers.image.title"]], tag))
          } else {
            x_field
          }
        }
      ),
      "platforms" = lapply(
        X = stack,
        FUN = function(x) {
          x_field <- x[["platforms"]]
          if (is.null(x_field)) {
            list("linux/amd64")
          } else {
            x_field
          }
        }
      ),
      "cache-from" = lapply(
        X = stack,
        FUN = function(x) {
          x_field <- x[["cache-from"]]
          if (is.null(x_field)) {
            list("")
          } else {
            x_field
          }
        }
      ),
      "cache-to" = lapply(
        X = stack,
        FUN = function(x) {
          x_field <- x[["cache-to"]]
          if (is.null(x_field)) {
            list("")
          } else {
            x_field
          }
        }
      )
    )
  ]

  (function(x, group) {
    list(
      group = if (!is.null(group)) {
        group
      } else {
        list(c(list(default = list(c(list(targets = if (length(x$name) == 1) list(x$name) else c(x$name)))))))
      },
      target = .transpose(x)
    )
  })(dt, stack_content$group)
}

write_bakejsons <- function(stack_directory, dockerfiles_directory, bake_directory) {
  stopifnot(dir.exists(stack_directory))

  if (!dir.exists(bake_directory)) {
    dir.create(bake_directory, recursive = TRUE)
  }

  message("Writing bake JSON files:")
  devnull <- lapply(
    X = list.files(path = stack_directory, pattern = "\\.json$", full.names = TRUE),
    dd = dockerfiles_directory,
    bd = bake_directory,
    FUN = function(stack_file, dd, bd) {
      bake_file <- sub(
        pattern = ".json$",
        replacement = ".docker-bake.json",
        x = sub(dirname(stack_file), bd, stack_file)
      )
      jsonlite::write_json(
        x = .bake_list(stack_file, dd),
        path = bake_file,
        pretty = TRUE,
        auto_unbox = TRUE
      )
      message(sprintf('  * "%s"', bake_file))
    }
  )

  invisible()
}

write_matrix <- function(bake_directory, matrix_path = "github_action_matrix.json", latest = FALSE) {
  stopifnot(dir.exists(bake_directory))

  if (!dir.exists(dirname(matrix_path))) {
    dir.create(dirname(matrix_path), recursive = TRUE)
  }

  message("Writing GitHub action config matrix JSON file:")

  r_versions <- unique(sapply(
    X = list.files(
      path = bake_directory,
      pattern = "(\\d+\\.){3}docker-bake.json$"
    ),
    FUN = sub,
    pattern = "\\.docker-bake.json$",
    replacement = "",
    USE.NAMES = FALSE
  ))

  jsonlite::write_json(
    x = list(
      r_version = if (latest) as.character(max(package_version(r_versions))) else r_versions,
      group = "default"
    ),
    path = matrix_path,
    pretty = TRUE,
    auto_unbox = FALSE
  )
  message(sprintf('  * "%s"', matrix_path))

  if (!latest) {
    jsonlite::write_json(
      x = list(r_version = r_versions, group = "server"),
      path = sub("\\.json", "_server.json", matrix_path),
      pretty = TRUE,
      auto_unbox = FALSE
    )
    message(sprintf('  * "%s"', sub("\\.json", "_server.json", matrix_path)))

    jsonlite::write_json(
      x = list(r_version = r_versions, group = "umr"),
      path = sub("\\.json", "_umr.json", matrix_path),
      pretty = TRUE,
      auto_unbox = FALSE
    )
    message(sprintf('  * "%s"', sub("\\.json", "_umr.json", matrix_path)))
  }

  invisible()
}
