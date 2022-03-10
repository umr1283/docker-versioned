#!/bin/bash

function install_docker() {
  apt-get update \
    && apt-get install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg \
      lsb-release \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo \
      "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose \
    && apt-get autoremove -y \
    && apt-get autoclean -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/ \
    && rm -rf /tmp/*

  return 0
}
