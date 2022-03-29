#!/bin/bash
set -e

### Sets up S6 supervisor.

S6_VERSION=${1:-${S6_VERSION:-v3.1.0.1}}
S6_BEHAVIOUR_IF_STAGE2_FAILS=2

ARCH=$(uname -m)

if [ ! -x "$(command -v wget)" ]; then
  apt-get update && apt-get -y install wget
fi

## Set up S6 init system
if [ -f "/docker_scripts/.s6_version" ] && [ "$S6_VERSION" = "$(cat /docker_scripts/.s6_version)" ]; then
  echo "S6 already installed"
else
  apt-get update && apt-get -y install xz-utils

  DOWNLOAD_FILE=s6-overlay-noarch.tar.xz
  wget -P /tmp/ https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/$DOWNLOAD_FILE
  tar -C / -Jxpf /tmp/$DOWNLOAD_FILE
  rm -rf /tmp/$DOWNLOAD_FILE

  DOWNLOAD_FILE=s6-overlay-${ARCH}.tar.xz
  wget -P /tmp/ https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/$DOWNLOAD_FILE
  tar -C / -Jxpf /tmp/$DOWNLOAD_FILE
  rm -rf /tmp/$DOWNLOAD_FILE

  echo "$S6_VERSION" >/docker_scripts/.s6_version
fi

# Clean up
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
