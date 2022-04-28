FROM debian:bullseye

LABEL org.opencontainers.image.licenses="GPL-3.0" \
      org.opencontainers.image.source="https://github.com/mcanouil/docker-versioned" \
      org.opencontainers.image.authors="Mickaël Canouil <https://mickael.canouil.fr/>"

ENV R_VERSION=4.2.0
ENV R_HOME=/usr/local/lib/R
ENV CRAN=https://cran.r-project.org
ENV LANG=en_GB.UTF-8
ENV TZ=Etc/UTC
ENV PANDOC_VERSION=2.14.2

COPY assets /docker_scripts

RUN chmod --recursive +x /docker_scripts
RUN /docker_scripts/install_lang.sh
RUN /docker_scripts/install_r.sh
RUN /docker_scripts/install_pandoc.sh
RUN /docker_scripts/install_git.sh
RUN /docker_scripts/install_gitlfs.sh
RUN /docker_scripts/install_python.sh
RUN /docker_scripts/install_msfonts.sh

CMD ["R"]

