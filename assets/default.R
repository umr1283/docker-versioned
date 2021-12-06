message(timestamp(quiet = TRUE))
### Project Setup ==================================================================================
library(here)
project_name <- sub("(.*)_[^_]*\\.Rproj$", "\\1", list.files(here(), pattern = ".Rproj$"))
output_directory <- here("outputs", "99-new_script")
dir.create(output_directory, recursive = TRUE, showWarnings = FALSE, mode = "0775")


### Load Packages ==================================================================================
suppressPackageStartupMessages({
  # library(ggplot2)
})


### Tables and Figures Theme =======================================================================
# theme_set(theme_minimal(base_family = "Verdana"))


### Functions ======================================================================================


### Analysis =======================================================================================


### Complete =======================================================================================
message("Success!", appendLF = TRUE)
message(timestamp(quiet = TRUE))
