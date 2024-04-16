FROM quay.io/pypa/manylinux_2_28_x86_64

#defaults, can be overwritten from outside
ARG OPENMS_BRANCH="master" 
ARG OPENMS_VERSION="latest"

# make source files from context available in docker
COPY . /contrib

RUN yum install -y wget
RUN yum install -y xz qt5-qtbase-devel 
RUN yum install -y qt5-qtbase-devel qt5-qtsvg qt5-qtsvg-devel
# RUN yum install -y libsvm-devel glpk-devel libzip-devel zlib-devel xerces-c-devel bzip2-devel sqlite-devel hdf5-devel
RUN yum install -y libtool

RUN yum install -y cmake3
RUN ln -s /usr/bin/cmake3 /usr/bin/cmake

# builds contrib for the current checked out branch
# during cleanup: removes archives
RUN mkdir contrib-build
RUN ls -l
WORKDIR /contrib-build
RUN ls -l
RUN cmake -DBUILD_TYPE=ALL ../contrib && rm -rf archives src
    
WORKDIR /

# Metadata
LABEL base.image="manylinux_2_28_x86_64"
LABEL version="1.0"
LABEL software="OpenMS (dependencies for manylinux_2_28)"
LABEL software.version="$OPENMS_VERSION"
LABEL description="C++ libraries and tools for MS/MS data analysis"
LABEL website="http://www.openms.org/"
LABEL documentation="http://www.openms.org/"
LABEL license="http://www.openms.org/"
LABEL tags="Proteomics"
