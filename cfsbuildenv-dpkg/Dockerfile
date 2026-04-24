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
        build-essential git gcc g++ gawk cmake lcov xsltproc rsync jq file \
        python3 python3-venv python3-dev python3-pip openssh-client \
        libexpat-dev liblua5.3-dev libjson-c-dev xz-utils cppcheck clang-format wget \
        ${EXTRA_PKGS} && \
    rm -rf /var/cache/apt
