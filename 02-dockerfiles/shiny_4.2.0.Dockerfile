FROM mcanouil/umr1283:4.2.0

LABEL org.opencontainers.image.licenses="GPL-3.0" \
      org.opencontainers.image.source="https://github.com/mcanouil/docker-versioned" \
      org.opencontainers.image.authors="Mickaël Canouil <https://mickael.canouil.fr/>"

ENV SHINY_SERVER_VERSION=latest

RUN /docker_scripts/install_shiny_server.sh

EXPOSE 3838

CMD ["/init"]

