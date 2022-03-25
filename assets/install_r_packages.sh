#!/bin/bash
set -e

apt-get update && apt-get install -y --no-install-recommends \
  cmake \
  libudunits2-dev \
  libcurl4-openssl-dev \
  libxml2-dev \
  libfontconfig1-dev \
  libssl-dev \
  libsasl2-dev \
  libharfbuzz-dev \
  libfribidi-dev \
  libfreetype6-dev \
  libpng-dev \
  libtiff5-dev \
  libjpeg-dev \
  libv8-dev \
  libxt6 \
  libgdal-dev \
  libgmp-dev \
  librsvg2-dev

Rscript -e 'if (!require(pak)) install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform$pkgType, R.Version()$os, R.Version()$arch))'

Rscript -e 'pak::pkg_install(c(
  "udunits2", "units", "devtools", "usethis", "here",
  "renv", "ragg", "svglite", "rhub", "rsconnect",
  "reprex", "palmerpenguins", "data.table",
  "R.utils", "bit64", "tidyverse", "tinytex",
  "gt", "styler", "miniUI", "prompt", "gert"
))'

Rscript -e 'pak::pak_cleanup(force = TRUE)'

# Clean up
apt-get autoremove -y
apt-get autoclean -y
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
