#########################################################
# This adds all the needed packages to build CFS
# in the native configurations
#
# This variant of the container may be built on a Debian-style base
# that uses dpkg and apt as the package management system
#########################################################

ARG BASE_IMAGE=debian:latest
FROM ${BASE_IMAGE} AS cfsbuildenv-dpkg

ARG EXTRA_PKGS=""

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        sudo ca-certificates curl lsb-release software-properties-common \
        build-essential gcc g++ gawk cmake lcov xsltproc rsync jq file \
        python3 python3-venv python3-dev python3-pip openssh-client \
        libexpat-dev liblua5.3-dev libjson-c-dev xz-utils cppcheck clang-format \
        ${EXTRA_PKGS} && \
    rm -rf /var/cache/apt

# Create a non-root user to do the build, but grant sudo to permit adding dependencies if needed
RUN useradd -m -c "Docker user" -U -G sudo docker && \
    echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers

USER docker
WORKDIR /home/docker
