FROM quay.io/pypa/manylinux2014_x86_64
ARG CONTRIB_BUILD_DIR="/contrib-build"
ARG OPENMS_VERSION="latest"

# make source files from context available in docker
COPY . /contrib

RUN yum install -y \
    wget \
    xz \
    qt5-qtbase-devel \
    qt5-qtsvg-devel \
    python-devel \
    qt5-qtsvg \
    libtool \
    cmake3
# RUN yum install -y libsvm-devel glpk-devel libzip-devel zlib-devel xerces-c-devel bzip2-devel sqlite-devel hdf5-devel
RUN ln -s /usr/bin/cmake3 /usr/bin/cmake

# builds contrib for the current checked out branch
# during cleanup: removes archives
WORKDIR ${CONTRIB_BUILD_DIR}
RUN cmake -DBUILD_TYPE=ALL ../contrib && rm -rf archives src

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
