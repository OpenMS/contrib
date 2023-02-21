FROM quay.io/pypa/manylinux2014_x86_64

#defaults, can be overwritten from outside
ARG OPENMS_BRANCH="develop" 
ARG OPENMS_VERSION="latest"

RUN yum install -y wget
RUN yum install -y xz qt5-qtbase-devel 
RUN yum install -y qt5-qtbase-devel qt5-qtsvg qt5-qtsvg-devel python-devel 
# RUN yum install -y libsvm-devel glpk-devel libzip-devel zlib-devel xerces-c-devel bzip2-devel sqlite-devel hdf5-devel
RUN yum install -y libtool

RUN yum install -y cmake3
RUN ln -s /usr/bin/cmake3 /usr/bin/cmake

# install contrib based on the OpenMS branch used! TODO: set context in action then we can get rid of the clone
RUN git clone https://github.com/OpenMS/contrib.git --branch "$OPENMS_BRANCH" --single-branch && \
    mkdir contrib-build && \
    cd contrib-build && \
    cmake -DBUILD_TYPE=ALL ../contrib && \
    rm -rf archives src && \
    cp -r . /contrib-build &&\
    cd /

WORKDIR /

# Metadata
LABEL base.image="manylinux2014_x86_64"
LABEL version="1.0"
LABEL software="OpenMS (dependencies for manylinux2014)"
LABEL software.version="$OPENMS_VERSION"
LABEL description="C++ libraries and tools for MS/MS data analysis"
LABEL website="http://www.openms.org/"
LABEL documentation="http://www.openms.org/"
LABEL license="http://www.openms.org/"
LABEL tags="Proteomics"
