#!/usr/bin/env Rscript

# Inspired from https://github.com/rocker-org/rocker-versioned2

#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)

library(data.table)
library(rversions)
library(httr2)
library(jsonlite)
library(yaml)
source("build/utils.R")
options(width = 120)

write_stacks(
  docker_repository = unlist(strsplit(args[[1]], ",")),
  stack_file = "01-stacks/devel.json",
  min_version = "4.0",
  debian = args[[2]],
  registry = "docker.io"
)

write_dockerfiles(
  stack_directory = "01-stacks",
  dockerfiles_directory = "02-dockerfiles"
)

write_compose(
  stack_file = "01-stacks/devel.json",
  compose_file = "03-compose/devel.yml",
  dockerfiles_directory = "02-dockerfiles"
)

write_bakejsons(
  stack_directory = "01-stacks",
  dockerfiles_directory = "02-dockerfiles",
  bake_directory = "04-bakefiles",
  registry = "docker.io"
)

write_matrix(
  bake_directory = "04-bakefiles",
  matrix_path = "05-matrix/github_action_matrix_all.json",
  latest = FALSE
)

write_matrix(
  bake_directory = "04-bakefiles",
  matrix_path = "05-matrix/github_action_matrix_latest.json",
  latest = TRUE
)
