#!/bin/bash
set -e

BCFTOOLS_VERSION=${BCFTOOLS_VERSION:-1.13}

apt-get update &&
  apt-get install -y --no-install-recommends \
    ca-certificates \
    bzip2 \
    libbz2-dev \
    liblzma-dev \
    wget \
    autoconf \
    automake \
    make

wget -q -P /tmp/ https://github.com/samtools/bcftools/releases/download/${BCFTOOLS_VERSION}/bcftools-${BCFTOOLS_VERSION}.tar.bz2 &&
  tar -C /tmp/ -xjf /tmp/bcftools-${BCFTOOLS_VERSION}.tar.bz2 &&
  cd /tmp/bcftools-${BCFTOOLS_VERSION} &&
  autoreconf -i &&
  ./configure --prefix=/usr &&
  make &&
  make install &&
  rm -rf /tmp/bcftools-${BCFTOOLS_VERSION}

wget -q -P /tmp/ https://github.com/samtools/htslib/releases/download/${BCFTOOLS_VERSION}/htslib-${BCFTOOLS_VERSION}.tar.bz2 &&
  tar -C /tmp/ -xjf /tmp/htslib-${BCFTOOLS_VERSION}.tar.bz2 &&
  cd /tmp/htslib-${BCFTOOLS_VERSION} &&
  autoreconf -i &&
  ./configure --prefix=/usr &&
  make &&
  make install &&
  rm -rf /tmp/htslib-${BCFTOOLS_VERSION}

# Clean up
apt-get autoremove -y
apt-get autoclean -y
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
