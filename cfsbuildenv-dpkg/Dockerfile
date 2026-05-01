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
ARG CLANG_VERSION=19

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        sudo ca-certificates curl lsb-release software-properties-common gnupg \
        build-essential git gcc g++ gawk cmake lcov xsltproc rsync jq file \
        python3 python3-venv python3-dev python3-pip openssh-client \
        libexpat-dev liblua5.3-dev libjson-c-dev xz-utils cppcheck wget \
        ${EXTRA_PKGS} && \
    rm -rf /var/cache/apt

RUN curl -fsL https://apt.llvm.org/llvm.sh >> /root/llvm.sh && bash /root/llvm.sh ${CLANG_VERSION}

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
	clang-${CLANG_VERSION} clang-format-${CLANG_VERSION} clang-tools-${CLANG_VERSION} clang-tidy-${CLANG_VERSION} && \
    rm -rf /var/cache/apt