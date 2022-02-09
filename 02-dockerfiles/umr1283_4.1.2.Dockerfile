FROM mcanouil/r-ver:4.1.2

LABEL org.opencontainers.image.licenses="GPL-3.0" \
      org.opencontainers.image.source="https://github.com/mcanouil/docker-versioned" \
      org.opencontainers.image.authors="Mickaël Canouil <https://mickael.canouil.fr/>"

ENV UMR1283_VERSION=1.6.0
ENV BCFTOOLS_VERSION=1.14
ENV ODBC_VERSION=8.0.27
ENV S6_VERSION=v2.2.0.3

COPY assets /docker_scripts

RUN chmod --recursive +x /docker_scripts
RUN /docker_scripts/install_libs.sh
RUN /docker_scripts/install_odbc.sh
RUN /docker_scripts/install_s6init.sh
RUN /docker_scripts/install_crossmap.sh
RUN /docker_scripts/install_bcftools.sh
RUN /docker_scripts/install_vcftools.sh
RUN /docker_scripts/install_qtltools.sh
RUN /docker_scripts/install_r_packages.sh
RUN /docker_scripts/install_r_umr1283.sh

CMD ["R"]

