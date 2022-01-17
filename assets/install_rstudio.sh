#!/bin/bash
set -e

RSTUDIO_VERSION=${RSTUDIO_VERSION:-"latest"}

ARCH=$(dpkg --print-architecture)

apt-get update && apt-get install -y --no-install-recommends \
    file \
    git \
    libapparmor1 \
    libgc1 \
    libclang-dev \
    libcurl4-openssl-dev \
    libedit2 \
    libobjc4 \
    libssl-dev \
    libpq5 \
    lsb-release \
    psmisc \
    procps \
    python-setuptools \
    sudo \
    wget \
    ca-certificates \
    ssh-client \
    man

rm -rf /var/lib/apt/lists/*

/docker_scripts/install_s6init.sh

## Download and install RStudio server & dependencies
## Uses, in order of preference, first argument of the script, the
## RSTUDIO_VERSION variable, or the latest RStudio version.  "latest", "preview",
## or "daily" may be used.
##
## Also symlinks pandoc, pandoc-citeproc so they are available system-wide,
export PATH=/usr/lib/rstudio-server/bin:$PATH

## Download RStudio Server for Ubuntu 18+
DOWNLOAD_FILE=rstudio-server.deb

if [ "$RSTUDIO_VERSION" = "latest" ]; then
  RSTUDIO_VERSION="stable"
fi

if [ "$RSTUDIO_VERSION" = "stable" ] || [ "$RSTUDIO_VERSION" = "preview" ] || [ "$RSTUDIO_VERSION" = "daily" ]; then
  wget "https://rstudio.org/download/latest/${RSTUDIO_VERSION}/server/bionic/rstudio-server-latest-${ARCH}.deb" -O "$DOWNLOAD_FILE"
else
  wget "https://download2.rstudio.org/server/bionic/${ARCH}/rstudio-server-${RSTUDIO_VERSION/"+"/"-"}-${ARCH}.deb" -O "$DOWNLOAD_FILE" \
  || wget "https://s3.amazonaws.com/rstudio-ide-build/server/bionic/${ARCH}/rstudio-server-${RSTUDIO_VERSION/"+"/"-"}-${ARCH}.deb" -O "$DOWNLOAD_FILE"
fi

dpkg -i "$DOWNLOAD_FILE"
rm "$DOWNLOAD_FILE"

# https://github.com/rocker-org/rocker-versioned2/issues/137
rm -f /var/lib/rstudio-server/secure-cookie-key

## RStudio wants an /etc/R, will populate from $R_HOME/etc
mkdir -p /etc/R
echo "PATH=${PATH}" >> ${R_HOME}/etc/Renviron.site

## Make RStudio compatible with case when R is built from source
## (and thus is at /usr/local/bin/R), because RStudio doesn't obey
## path if a user apt-get installs a package
R_BIN=$(which R)
echo "rsession-which-r=${R_BIN}" > /etc/rstudio/rserver.conf
## use more robust file locking to avoid errors when using shared volumes:
echo "lock-type=advisory" > /etc/rstudio/file-locks

## Prepare optional configuration file to disable authentication
## To de-activate authentication, `disable_auth_rserver.conf` script
## will just need to be overwrite /etc/rstudio/rserver.conf.
## This is triggered by an env var in the user config
cp /etc/rstudio/rserver.conf /etc/rstudio/disable_auth_rserver.conf
echo "auth-none=1" >> /etc/rstudio/disable_auth_rserver.conf

## Set up RStudio init scripts
mkdir -p /etc/services.d/rstudio
# shellcheck disable=SC2016
echo '#!/usr/bin/with-contenv bash
## load /etc/environment vars first:
for line in $( cat /etc/environment ) ; do export $line > /dev/null; done
exec /usr/lib/rstudio-server/bin/rserver --server-daemonize 0' \
> /etc/services.d/rstudio/run

echo '#!/bin/bash
rstudio-server stop' \
> /etc/services.d/rstudio/finish

# Log to syslog
LOGGING="[*]
log-level=warn
logger-type=syslog
"

printf "%s" "$LOGGING" > /etc/rstudio/logging.conf

printf "\numask 0002\n" >> /etc/profile

cp /docker_scripts/rstudio-prefs.json /etc/rstudio/rstudio-prefs.json

# ## Set our dynamic variables in Renviron.site to be reflected by RStudio Server or Shiny Server
# exclude_vars="HOME PASSWORD RSTUDIO_VERSION"
# for file in /var/run/s6/container_environment/*
# do
#   sed -i "/^${file##*/}=/d" ${R_HOME}/etc/Renviron.site
#   regex="(^| )${file##*/}($| )"
#   [[ ! $exclude_vars =~ $regex ]] && echo "${file##*/}=$(cat $file)" >> ${R_HOME}/etc/Renviron.site || echo "skipping $file"
# done

# ## only file-owner (root) should read container_environment files:
# chmod --quiet 600 /var/run/s6/container_environment/*

# Clean up
apt-get autoremove -y
apt-get autoclean -y
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
