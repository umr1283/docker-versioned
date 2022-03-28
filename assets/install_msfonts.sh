#!/bin/bash
set -e

apt-get update && apt-get -y install lsb-release

DEBIAN_VERSION=${DEBIAN_VERSION:-$(lsb_release -sc)}

echo "deb http://ftp.uk.debian.org/debian $DEBIAN_VERSION main contrib" >>/etc/apt/sources.list

apt-get update &&
  apt-get install -y --no-install-recommends \
    libmspack0 \
    cabextract \
    dpkg \
    wget \
    fontconfig \
    xfonts-utils \
    ca-certificates \
    fonts-liberation

apt-get install -y --no-install-recommends ttf-mscorefonts-installer && fc-cache -frsv

# Clean up
apt-get autoremove -y
apt-get autoclean -y
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
