#!/bin/bash
set -e

. /docker_scripts/install_s6v2.sh

apt-get update && apt-get install -y openssh-server sudo man

## Set up openssh-server init scripts
mkdir -p /etc/services.d/openssh-server
mkdir -p /run/sshd
# shellcheck disable=SC2016
echo -e '#!/usr/bin/with-contenv bash\nexec /usr/sbin/sshd -D -e -p 2222\n' >/etc/services.d/openssh-server/run

echo -e '#!/bin/bash\n/etc/init.d/ssh stop\n' >/etc/services.d/openssh-server/finish

# password access denied
# sed -i "s/^[# \t]*PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/ssh_config
# sed -i "s/^[# \t]*PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config
chown root:root /etc/shadow

# Install "languageserver" and "httpgd" for VScode
Rscript \
  -e 'if (!require(pak, quietly = TRUE)) install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform$pkgType, R.Version()$os, R.Version()$arch))' \
  -e 'pak::pkg_install(c("languageserver", "httpgd"))' \
  -e 'pak::pak_cleanup(force = TRUE)'

# Clean up
apt-get autoremove -y
apt-get autoclean -y
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
