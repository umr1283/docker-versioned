#!/bin/bash
set -e

python3 -m pip --no-cache-dir install --upgrade \
  setuptools \
  wheel \
  CrossMap

# Clean up
apt-get autoremove -y
apt-get autoclean -y
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*