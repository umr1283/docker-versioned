#!/bin/bash
set -e

BEDTOOLS_VERSION=${BEDTOOLS_VERSION:-2.29.1}

apt-get update &&
  apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    make \
    g++ \
    zlib1g-dev \
    autoconf \
    automake \
    make

# Download and install bedtools
wget -q -P /tmp/ https://github.com/arq5x/bedtools2/archive/refs/tags/v${BEDTOOLS_VERSION}.tar.gz &&
  tar -C /tmp/ -xjf /tmp/bedtools2-${BEDTOOLS_VERSION}.tar.gz &&
  cd /tmp/bedtools2-${BEDTOOLS_VERSION} &&
  make &&
  cp bin/* /usr/local/bin/ &&
  cd / &&
  rm -rf /tmp/bedtools2-${BEDTOOLS_VERSION}

# Clean up
apt-get autoremove -y
apt-get autoclean -y
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*

