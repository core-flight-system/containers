#########################################################
# This adds all the needed packages to build CFS
# in the native configurations
#
# This variant of the container may be built on a RHEL-style base
# that uses rpm and dnf as the package management system
#########################################################

ARG BASE_IMAGE=rockylinux:9
FROM ${BASE_IMAGE} AS cfsbuildenv-rpm

ARG EXTRA_PKGS=""

# Add the EPEL key so the next dnf command does not fail
RUN export KEYFILE=$(. /etc/os-release && echo "RPM-GPG-KEY-EPEL-${VERSION_ID%%.*}") && \
    rpmkeys --import https://dl.fedoraproject.org/pub/epel/${KEYFILE}

# Note that there are no strict dependencies on EPEL packages, but 
# historically it also offered a newer version of CMake where the version in RHEL was obsolete.
RUN export EL_VERSION=$(. /etc/os-release && echo "${VERSION_ID%%.*}") && \
    dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-${EL_VERSION}.noarch.rpm && \
    /usr/bin/crb enable && \
    dnf install -y --allowerasing \
        ca-certificates curl jq openssl git rsync \
        glibc-devel libstdc++-devel gawk gcc gcc-c++ make cmake \
        python3 python3-pip python3-devel expat-devel json-c-devel lua-devel \
        ${EXTRA_PKGS} && \
    dnf clean all

# This just creates a normal user without sudo privileges
RUN useradd -m -c "Docker user" -U docker

USER docker
WORKDIR /home/docker
