#!/bin/bash
set -e

. /docker_scripts/install_s6init.sh

apt-get update && apt-get install -y openssh-server sudo

## Set up openssh-server init scripts
mkdir -p /etc/services.d/openssh-server
mkdir -p /run/sshd
# shellcheck disable=SC2016
echo '#!/usr/bin/with-contenv bash
exec /usr/sbin/sshd -D -e -p 2222' \
> /etc/services.d/openssh-server/run

echo '#!/bin/bash
/etc/init.d/ssh stop' \
> /etc/services.d/openssh-server/finish

# password access denied
sed -i "s/^[# \t]*PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/ssh_config
sed -i "s/^[# \t]*PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config
chown root:root /etc/shadow

# Install "languageserver" and "httpgd" for VScode
Rscript \
  -e 'pak::pkg_install(c("languageserver", "httpgd"))' \
  -e 'pak::pak_cleanup(force = TRUE)'

# Clean up
apt-get autoremove -y
apt-get autoclean -y
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*