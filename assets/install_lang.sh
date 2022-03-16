#!/bin/bash
set -e

LANG=${LANG:-en_GB.UTF-8}
LANGUAGE=${LANG}

apt-get update \
  && apt-get install -y --no-install-recommends locales \
  && sed -i "/^#.* ${LANG} /s/^#//" /etc/locale.gen \
  && locale-gen ${LANG} \
  && /usr/sbin/update-locale LANG="${LANG}" \
  && /usr/sbin/update-locale LANGUAGE="${LANG}" \
  && /usr/sbin/update-locale LC_ALL="${LANG}" \
  && /usr/sbin/update-locale LC_CTYPE="${LANG}" \
  && /usr/sbin/update-locale LC_NUMERIC="${LANG}" \
  && /usr/sbin/update-locale LC_TIME="${LANG}" \
  && /usr/sbin/update-locale LC_COLLATE="${LANG}" \
  && /usr/sbin/update-locale LC_MONETARY="${LANG}" \
  && /usr/sbin/update-locale LC_MESSAGES="${LANG}" \
  && /usr/sbin/update-locale LC_PAPER="${LANG}" \
  && /usr/sbin/update-locale LC_NAME="${LANG}" \
  && /usr/sbin/update-locale LC_ADDRESS="${LANG}" \
  && /usr/sbin/update-locale LC_TELEPHONE="${LANG}" \
  && /usr/sbin/update-locale LC_MEASUREMENT="${LANG}" \
  && /usr/sbin/update-locale LC_IDENTIFICATION="${LANG}"
