#!/bin/bash
set -e

# https://dev.mysql.com/downloads/connector/odbc/

apt-get update \
  && apt-get install -y --no-install-recommends \
    lsb-release \
    dpkg \
    dpkg-dev \
    wget \
    ca-certificates \
    tdsodbc \
    odbc-postgresql \
    libsqliteodbc \
    unixodbc \
    unixodbc-dev

ODBC_VERSION=${ODBC_VERSION:-8.0.26}
DEBIAN_ODBC_VERSION=${DEBIAN_ODBC_VERSION:-`echo "$(lsb_release -si)$(lsb_release -sr)" | tr '[:upper:]' '[:lower:]'`}
ARCH=$(dpkg --print-architecture)

if [ "$ARCH" = "amd64" ]; then
  wget -q -P /tmp/ https://repo.mysql.com/apt/debian/pool/mysql-${ODBC_VERSION%.*}/m/mysql-community/mysql-community-client-plugins_${ODBC_VERSION}-1${DEBIAN_ODBC_VERSION}_${ARCH}.deb
  dpkg -i /tmp/mysql-community-client-plugins_${ODBC_VERSION}-1${DEBIAN_ODBC_VERSION}_${ARCH}.deb
  wget -q -P /tmp/ https://repo.mysql.com/apt/debian/pool/mysql-tools/m/mysql-connector-odbc/mysql-connector-odbc_${ODBC_VERSION}-1${DEBIAN_ODBC_VERSION}_${ARCH}.deb
  dpkg -i /tmp/mysql-connector-odbc_${ODBC_VERSION}-1${DEBIAN_ODBC_VERSION}_${ARCH}.deb

  apt-get update && apt-get install mysql-connector-odbc
fi

# Clean up
apt-get autoremove -y
apt-get autoclean -y
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*