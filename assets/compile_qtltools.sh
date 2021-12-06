apt-get update \
  && apt-get install -y --no-install-recommends \
    g++ gcc gfortran make autoconf automake libtool zlib1g-dev liblzma-dev libbz2-dev lbzip2 libgsl-dev \
    libblas-dev libx11-dev libboost*-all-dev git libreadline-dev libxt-dev libpcre2-dev libcurl4-openssl-dev \
    wget ca-certificates

mkdir /tmp/tools

wget -q -P /tmp/tools/ https://cran.r-project.org/src/base/R-4/R-4.1.2.tar.gz \
  && tar -C /tmp/tools/ -xzf /tmp/tools/R-4.1.2.tar.gz \
  && cd /tmp/tools/R-4.1.2/ \
  && ./configure \
  && cd /tmp/tools/R-4.1.2/src/nmath/standalone/ \
  && make

wget -q -P /tmp/tools/ https://github.com/samtools/htslib/releases/download/1.14/htslib-1.14.tar.bz2 \
  && tar -C /tmp/tools/ -xf /tmp/tools/htslib-1.14.tar.bz2 \
  && cd /tmp/tools/htslib-1.14/ \
  && autoreconf -i \
  && ./configure \
  && make

git clone --depth 1 --branch 1.3.1 https://github.com/qtltools/qtltools.git /tmp/tools/qtltools \
  && cd /tmp/tools/qtltools \
  && sed \
    -e 's/BOOST_INC=/BOOST_INC=\/usr\/include/' \
    -e 's/BOOST_LIB=/BOOST_LIB=\/usr\/lib\/x86_64-linux-gnu/' \
    -e 's/RMATH_INC=/RMATH_INC=\/tmp\/tools\/R-4.1.2\/src\/include/' \
    -e 's/RMATH_LIB=/RMATH_LIB=\/tmp\/tools\/R-4.1.2\/src\/nmath\/standalone/' \
    -e 's/HTSLD_INC=/HTSLD_INC=\/tmp\/tools\/htslib-1.14/' \
    -e 's/HTSLD_LIB=/HTSLD_LIB=\/tmp\/tools\/htslib-1.14/' \
    /tmp/tools/qtltools/Makefile > /tmp/tools/qtltools/Makefile_2 \
  && rm -rf /tmp/tools/qtltools/Makefile \
  && mv /tmp/tools/qtltools/Makefile_2 /tmp/tools/qtltools/Makefile

make
make install
make clean
