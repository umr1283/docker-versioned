FROM docker.io/umr1283/umr1283:4.0.2

LABEL org.opencontainers.image.licenses="GPL-3.0" \
      org.opencontainers.image.source="https://github.com/umr1283/docker-versioned" \
      org.opencontainers.image.authors="Mickaël Canouil <https://mickael.canouil.fr/>"

ENV RSTUDIO_VERSION=2022.07.2+576
ENV PATH=/usr/lib/rstudio-server/bin:$PATH

RUN /docker_scripts/install_rstudio.sh

EXPOSE 8787

CMD ["/init"]

