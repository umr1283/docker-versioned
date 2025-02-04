FROM docker.io/umr1283/r-ver:4.4.1

LABEL org.opencontainers.image.licenses="GPL-3.0" \
      org.opencontainers.image.source="https://github.com/umr1283/docker-versioned" \
      org.opencontainers.image.authors="Mickaël Canouil <https://mickael.canouil.fr/>"

ENV UMR1283_VERSION=1.10.4
ENV PANDOC_VERSION=3.1.11.1
ENV BCFTOOLS_VERSION=1.15.1
ENV QUARTO_VERSION=1.5.6
ENV ODBC_VERSION=8.0.27
ENV S6_VERSION=v2.2.0.3

COPY assets /docker_scripts

RUN chmod --recursive +x /docker_scripts
RUN /docker_scripts/install_libs.sh
RUN /docker_scripts/install_pandoc.sh
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
