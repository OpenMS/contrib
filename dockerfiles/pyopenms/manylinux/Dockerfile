FROM quay.io/pypa/manylinux2014_x86_64
ARG CONTRIB_BUILD_DIR="/contrib-build"
ARG OPENMS_VERSION="latest"

# make source files from context available in docker
COPY . /contrib

RUN yum install -y \
    # build system dependencies
    wget \
    xz \
    libtool \
    cmake3 \
    # OpenMS and PyOpenMS build dependencies
    libsvm-devel \
    glpk-devel \
    libzip-devel \
    zlib-devel \
    xerces-c-devel \
    bzip2-devel \
    hdf5-devel \
    qt5-qtbase-devel \
    qt5-qtsvg-devel \
    eigen3-devel \
    python-devel
# TODO: do we need sqlite-devel?
# TODO: can we install boost from yum?
# TODO: is coin-or-CoinUtils-devel useful?
# TODO: do we need KissFFT? It's not installed in the regular contrib Dockerfile

RUN ln -s /usr/bin/cmake3 /usr/bin/cmake

# builds contrib for the current checked out branch
# during cleanup: removes archives
WORKDIR ${CONTRIB_BUILD_DIR}
RUN cmake -DBUILD_TYPE="BOOST;COINOR;KISSFFT;OPENMP" ../contrib && rm -rf archives src

WORKDIR /

# Metadata
LABEL base.image="manylinux2014_x86_64"
LABEL version="${OPENMS_VERSION}"
LABEL software="OpenMS (dependencies for manylinux2014)"
LABEL software.version="$OPENMS_VERSION-manylinux2014"
LABEL description="Base image to build OpenMS: C++ libraries and tools for MS/MS data analysis"
LABEL website="https://www.openms.org/"
LABEL documentation="https://www.openms.org/"
LABEL license="https://www.openms.org/"
LABEL tags="Proteomics"

# to link to repo on github container registry
LABEL org.opencontainers.image.source https://github.com/OpenMS/contrib
