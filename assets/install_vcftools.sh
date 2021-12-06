#!/bin/bash
set -e

apt-get update
apt-get install -y --no-install-recommends vcftools

# Clean up
apt-get autoremove -y
apt-get autoclean -y
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
