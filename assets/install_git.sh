#!/bin/bash
set -e

apt-get update &&
  apt-get install -y --no-install-recommends \
    git \
    gpg \
    gpg-agent \
    nano &&
  rm -rf /var/lib/apt/lists/*

git config --system init.defaultBranch main
git config --system push.default matching
git config --system core.sharedRepository 0775
git config --system core.editor "nano -w"
git config --system color.ui auto
git config --system credential.helper "cache --timeout=3600"

# Clean up
apt-get autoremove -y
apt-get autoclean -y
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
