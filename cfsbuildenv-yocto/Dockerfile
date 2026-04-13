#########################################################
# This adds all the needed packages to build CFS
# for an embedded Linux target using Yocto
#########################################################

ARG YOCTO_SDK_IMAGE=yocto-sdk
ARG BASE_IMAGE=debian:trixie

FROM ${YOCTO_SDK_IMAGE} AS yocto-sdk
FROM ${BASE_IMAGE} AS cfsbuildenv-yocto

ARG EXTRA_PKGS=""

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        sudo ca-certificates curl lsb-release \
        build-essential gcc g++ gawk cmake git xsltproc jq \
        python3 python3-venv python3-dev python3-pip \
        libexpat-dev liblua5.4-dev libjson-c-dev xz-utils \
        qemu-utils bsdextrautils e2fsprogs \
        ${EXTRA_PKGS} && \
    rm -rf /var/cache/apt

# Bring the SDK entirely from the yocto-sdk image,
COPY --from=yocto-sdk /opt /opt
