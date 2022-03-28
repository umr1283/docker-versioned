#!/bin/bash
set -e

R_VERSION=${1:-${R_VERSION:-"latest"}}

apt-get update && apt-get -y install lsb-release

DEBIAN_VERSION=${DEBIAN_VERSION:-`lsb_release -sc`}
LANG=${LANG:-en_GB.UTF-8}
CRAN=${CRAN:-https://cran.r-project.org}
TZ=${TZ:-Etc/UTC}

ARCH=$(uname -m)

export DEBIAN_FRONTEND=noninteractive

## Set up and install R
R_HOME=${R_HOME:-/usr/local/lib/R}

apt-get update \
  && apt-get install -y --no-install-recommends \
    bash-completion \
    ca-certificates \
    devscripts \
    file \
    fonts-texgyre \
    g++ \
    gfortran \
    gsfonts \
    libblas-dev \
    libbz2-* \
    libcurl4 \
    libicu* \
    liblapack-dev \
    libpcre2* \
    libjpeg-turbo* \
    libpangocairo-* \
    libpng16* \
    libreadline8 \
    libtiff* \
    liblzma* \
    make \
    unzip \
    zip \
    zlib1g \
    tk

BUILDDEPS="curl \
    default-jdk \
    libbz2-dev \
    libcairo2-dev \
    libcurl4-openssl-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libicu-dev \
    libpcre2-dev \
    libpng-dev \
    libreadline-dev \
    libtiff5-dev \
    liblzma-dev \
    libx11-dev \
    libxt-dev \
    perl \
    rsync \
    subversion \
    tcl-dev \
    tk-dev \
    texinfo \
    texlive-extra-utils \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-latex-recommended \
    texlive-latex-extra \
    x11proto-core-dev \
    xauth \
    xfonts-base \
    xvfb \
    wget \
    zlib1g-dev"

apt-get install -y --no-install-recommends $BUILDDEPS

## Download R from 0-Cloud CRAN mirror or CRAN
function download_r_src() {
  wget "https://cloud.r-project.org/src/$1" -O "R.tar.gz" ||
    wget "https://cran.r-project.org/src/$1" -O "R.tar.gz"
}

if [ "$R_VERSION" == "devel" ]; then
  download_r_src "base-prerelease/R-devel.tar.gz"
elif [ "$R_VERSION" == "patched" ]; then
  download_r_src "base-prerelease/R-latest.tar.gz"
elif [ "$R_VERSION" == "latest" ]; then
  download_r_src "base/R-latest.tar.gz"
else
  download_r_src "base/R-${R_VERSION%%.*}/R-${R_VERSION}.tar.gz"
fi

tar xzf "R.tar.gz"
cd R-*/

R_PAPERSIZE=letter \
  R_BATCHSAVE="--no-save --no-restore" \
  R_BROWSER=xdg-open \
  PAGER=/usr/bin/pager \
  PERL=/usr/bin/perl \
  R_UNZIPCMD=/usr/bin/unzip \
  R_ZIPCMD=/usr/bin/zip \
  R_PRINTCMD=/usr/bin/lpr \
  LIBnn=lib \
  AWK=/usr/bin/awk \
  CFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g" \
  CXXFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g" \
  ./configure --enable-R-shlib \
    --enable-memory-profiling \
    --with-readline \
    --with-blas \
    --with-lapack \
    --with-tcltk \
    --with-recommended-packages

make
make install
make clean

## Add a library directory (for user-installed packages)
mkdir -p ${R_HOME}/site-library
chown root:staff ${R_HOME}/site-library
chmod g+ws ${R_HOME}/site-library

echo "R_LIBS=\${R_LIBS-'${R_HOME}/site-library:${R_HOME}/library'}" >> ${R_HOME}/etc/Renviron.site
echo 'LANGUAGE="${LANG}"' >> ${R_HOME}/etc/Renviron.site
echo "R_LIBS_USER=~/R/library" >> ${R_HOME}/etc/Renviron.site
echo 'TZ="${TZ}"' >> ${R_HOME}/etc/Renviron.site
echo "R_MAX_NUM_DLLS=300" >> ${R_HOME}/etc/Renviron.site
echo "RENV_PATHS_CACHE=/renv_cache" >> ${R_HOME}/etc/Renviron.site

echo  "options(
  repos = c(CRAN = \"${CRAN}\"),
  download.file.method = \"libcurl\",
  HTTPUserAgent = sprintf(\"R/%s R (%s)\", getRversion(), paste(getRversion(), R.version$platform, R.version$arch, R.version$os))
)" >> ${R_HOME}/etc/Rprofile.site

echo 'Sys.umask("0002")' >> ${R_HOME}/etc/Rprofile.site

if ! dpkg -l | grep -q libopenblas-dev; then
  apt-get update && apt-get install -y --no-install-recommends libopenblas-dev
  update-alternatives --set "libblas.so.3-${ARCH}-linux-gnu" "/usr/lib/${ARCH}-linux-gnu/openblas-pthread/libblas.so.3"
fi

# Clean up
cd /
rm -rf /tmp/*
rm -rf R-*
apt-get remove --purge -y $BUILDDEPS
apt-get autoremove -y
apt-get autoclean -y
rm -rf /var/lib/apt/lists/*
