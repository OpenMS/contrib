FROM quay.io/pypa/manylinux_2_28_x86_64

# Defaults, can be overwritten from outside
ARG OPENMS_BRANCH="master" 
ARG OPENMS_VERSION="latest"

# Make source files from context available in docker
COPY . /contrib

RUN yum install -y wget
RUN yum install -y xz qt6-qtbase-devel qt6-qtsvg-devel
RUN yum install -y libtool cmake3

# Build contrib for the current checked out branch
# During cleanup: removes archives
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
