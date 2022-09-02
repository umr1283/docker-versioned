FROM docker.io/umr1283/umr1283:devel

LABEL org.opencontainers.image.licenses="GPL-3.0" \
      org.opencontainers.image.source="https://github.com/umr1283/docker-versioned" \
      org.opencontainers.image.authors="Mickaël Canouil <https://mickael.canouil.fr/>"

RUN /docker_scripts/install_ssh.sh

EXPOSE 2222

CMD ["/init"]
