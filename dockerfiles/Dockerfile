# syntax=docker/dockerfile:1.3-labs
FROM ubuntu:22.04
ARG CONTRIB_BUILD_DIR="/contrib-build"
ARG OPENMS_VERSION=3.1.0
ARG CMAKE_VERSION=3.28.1

# install build dependencies
RUN apt-get -y update \
  && apt-get install -y --no-install-recommends --no-install-suggests \
    # build system dependencies
    g++ \
    make \
    git \
    ca-certificates \
    # OpenMS build dependencies
    libsvm-dev \
    libglpk-dev \
    libzip-dev \
    zlib1g-dev \
    libxerces-c-dev \
    libbz2-dev \
    libomp-dev \
    libhdf5-dev\
    libboost-date-time1.74-dev \
    libboost-iostreams1.74-dev \
    libboost-regex1.74-dev \
    libboost-math1.74-dev \
    libboost-random1.74-dev \
    qtbase5-dev \
    libqt5svg5-dev \
    libqt5opengl5-dev \
    libeigen3-dev \
    coinor-libcoinmp-dev \
  && rm -rf /var/lib/apt/lists/* \
  && update-ca-certificates

# installing cmake
WORKDIR /tmp
ADD https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh cmake.sh
RUN <<-EOF
    set -eux
    mkdir -p /opt/cmake
    sh cmake.sh --skip-license --prefix=/opt/cmake
    ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake
    ln -s /opt/cmake/bin/ctest /usr/local/bin/ctest
    rm -rf /tmp/*
EOF

COPY . /contrib
RUN mkdir ${CONTRIB_BUILD_DIR}
WORKDIR /

# Metadata
LABEL base.image="ubuntu:22.04"
LABEL version="${OPENMS_VERSION}"
LABEL software="OpenMS (dependencies)"
LABEL software.version="${OPENMS_VERSION}-Ubuntu22.04"
LABEL description="Base image to build OpenMS: C++ libraries and tools for MS/MS data analysis"
LABEL website="http://www.openms.org/"
LABEL documentation="http://www.openms.org/"
LABEL license="http://www.openms.org/"
LABEL tags="Proteomics"

# to link to repo on github container registry
LABEL org.opencontainers.image.source https://github.com/OpenMS/contrib
