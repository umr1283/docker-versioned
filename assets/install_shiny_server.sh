#!/bin/bash
set -e

SHINY_SERVER_VERSION=${SHINY_SERVER_VERSION:-latest}
NCPUS=${NCPUS:--1}

ARCH=$(dpkg --print-architecture)

/docker_scripts/install_s6init.sh

if [ "$SHINY_SERVER_VERSION" = "latest" ]; then
  SHINY_SERVER_VERSION=$(wget -qO- https://download3.rstudio.org/ubuntu-14.04/x86_64/VERSION)
fi

# Get apt packages
apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    gdebi-core \
    libcurl4-openssl-dev \
    libcairo2-dev \
    libxt-dev \
    xtail \
    wget

# Install Shiny server
wget --no-verbose "https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-${SHINY_SERVER_VERSION}-${ARCH}.deb" -O ss-latest.deb
gdebi -n ss-latest.deb
rm ss-latest.deb

# Get R packages
Rscript \
  -e 'if (!require(pak, quietly = TRUE)) utils::install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform$pkgType, R.Version()$os, R.Version()$arch))' \
  -e 'pak::pkg_install(c("shiny", "rmarkdown", "renv"))' \
  -e 'pak::pak_cleanup(force = TRUE)'

# Set up directories and permissions
if [ -x "$(command -v rstudio-server)" ]; then
  DEFAULT_USER=${DEFAULT_USER:-rstudio}
  adduser ${DEFAULT_USER} shiny
fi

cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/
chown shiny:shiny /var/lib/shiny-server
mkdir -p /var/log/shiny-server
chown shiny:shiny /var/log/shiny-server

# create init scripts
mkdir -p /etc/services.d/shiny-server
cat > /etc/services.d/shiny-server/run << 'EOF'
#!/usr/bin/with-contenv bash
## load /etc/environment vars first:
for line in $( cat /etc/environment ) ; do export $line > /dev/null; done
if [ "$APPLICATION_LOGS_TO_STDOUT" != "false" ]; then
    exec xtail /var/log/shiny-server/ &
fi
exec shiny-server 2>&1
EOF
chmod +x /etc/services.d/shiny-server/run

## Set our dynamic variables in Renviron.site to be reflected by RStudio Server or Shiny Server
exclude_vars="HOME PASSWORD RSTUDIO_VERSION"
for file in /var/run/s6/container_environment/*
do
  sed -i "/^${file##*/}=/d" ${R_HOME}/etc/Renviron.site
  regex="(^| )${file##*/}($| )"
  [[ ! $exclude_vars =~ $regex ]] && echo "${file##*/}=$(cat $file)" >> ${R_HOME}/etc/Renviron.site || echo "skipping $file"
done

# ## only file-owner (root) should read container_environment files:
# chmod --quiet 600 /var/run/s6/container_environment/*

# Clean up
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/downloaded_packages
