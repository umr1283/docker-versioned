FROM mcanouil/r-ver:4.0.2

LABEL org.opencontainers.image.licenses="GPL-3.0" \
      org.opencontainers.image.source="https://github.com/mcanouil/docker-versioned" \
      org.opencontainers.image.authors="Mickaël Canouil <https://mickael.canouil.fr/>"

ENV UMR1283_VERSION=1.8.3
ENV BCFTOOLS_VERSION=1.15.1
ENV QUARTO_VERSION=0.9.377
ENV ODBC_VERSION=8.0.27
ENV S6_VERSION=v2.2.0.3

COPY assets /docker_scripts

RUN chmod --recursive +x /docker_scripts
RUN /docker_scripts/install_libs.sh
RUN /docker_scripts/install_odbc.sh
RUN /docker_scripts/install_s6v2.sh
RUN /docker_scripts/install_crossmap.sh
RUN /docker_scripts/install_bcftools.sh
RUN /docker_scripts/install_vcftools.sh
RUN /docker_scripts/install_qtltools.sh
RUN /docker_scripts/install_r_packages.sh
RUN /docker_scripts/install_r_umr1283.sh
RUN /docker_scripts/install_quarto.sh
RUN /docker_scripts/set_bash_default.sh

CMD ["R"]

