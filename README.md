
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Version-stable Docker images for R \>= 4.0.0

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![License](https://img.shields.io/github/license/mcanouil/docker-versioned)](LICENSE)
[![GitHub
tag](https://img.shields.io/github/tag/mcanouil/docker-versioned.svg?label=latest%20tag)](https://github.com/mcanouil/docker-versioned)
[![Write Config
Files](https://github.com/mcanouil/docker-versioned/actions/workflows/setup.yml/badge.svg)](https://github.com/mcanouil/docker-versioned/actions/workflows/setup.yml)  
[![Build & Push Devel
images](https://github.com/mcanouil/docker-versioned/actions/workflows/devel.yml/badge.svg)](https://github.com/mcanouil/docker-versioned/actions/workflows/devel.yml)
[![Build & Push Core
images](https://github.com/mcanouil/docker-versioned/actions/workflows/core.yml/badge.svg)](https://github.com/mcanouil/docker-versioned/actions/workflows/core.yml)
[![Build & Push UMR
images](https://github.com/mcanouil/docker-versioned/actions/workflows/umr.yml/badge.svg)](https://github.com/mcanouil/docker-versioned/actions/workflows/umr.yml)
[![Build & Push Server
images](https://github.com/mcanouil/docker-versioned/actions/workflows/server.yml/badge.svg)](https://github.com/mcanouil/docker-versioned/actions/workflows/server.yml)
<!-- badges: end -->

This is a repository for building Docker images.

| Image                                                | Description                                                                | R                                                                                                                               | Pull                                                                                                       |
| :--------------------------------------------------- | :------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------ | :--------------------------------------------------------------------------------------------------------- |
| [r-ver](https://hub.docker.com/r/mcanouil/r-ver)     | Reproducible builds with predefined version of R                           | [![](https://img.shields.io/docker/v/mcanouil/r-ver.svg?sort=semver&label=latest)](https://hub.docker.com/r/mcanouil/r-ver)     | [![](https://img.shields.io/docker/pulls/mcanouil/r-ver.svg)](https://hub.docker.com/r/mcanouil/r-ver)     |
| [umr1283](https://hub.docker.com/r/mcanouil/umr1283) | Reproducible builds with predefined version of R and some (genetics) tools | [![](https://img.shields.io/docker/v/mcanouil/umr1283.svg?sort=semver&label=latest)](https://hub.docker.com/r/mcanouil/umr1283) | [![](https://img.shields.io/docker/pulls/mcanouil/umr1283.svg)](https://hub.docker.com/r/mcanouil/umr1283) |
| [rstudio](https://hub.docker.com/r/mcanouil/rstudio) | RStudio server for umr1283 image                                           | [![](https://img.shields.io/docker/v/mcanouil/rstudio.svg?sort=semver&label=latest)](https://hub.docker.com/r/mcanouil/rstudio) | [![](https://img.shields.io/docker/pulls/mcanouil/rstudio.svg)](https://hub.docker.com/r/mcanouil/rstudio) |
| [ssh](https://hub.docker.com/r/mcanouil/ssh)         | SSH server for umr1283 image                                               | [![](https://img.shields.io/docker/v/mcanouil/ssh.svg?sort=semver&label=latest)](https://hub.docker.com/r/mcanouil/ssh)         | [![](https://img.shields.io/docker/pulls/mcanouil/ssh.svg)](https://hub.docker.com/r/mcanouil/ssh)         |
| [shiny](https://hub.docker.com/r/mcanouil/shiny)     | Shiny server for umr1283 image                                             | [![](https://img.shields.io/docker/v/mcanouil/shiny.svg?sort=semver&label=latest)](https://hub.docker.com/r/mcanouil/shiny)     | [![](https://img.shields.io/docker/pulls/mcanouil/shiny.svg)](https://hub.docker.com/r/mcanouil/shiny)     |

*Note: Based on
[rocker-org/rocker-versioned2](https://github.com/rocker-org/rocker-versioned2)
build workflow.*
