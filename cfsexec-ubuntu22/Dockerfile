#########################################################
# This adds all the needed packages to execute a cFS build in QEMU
#
# This variant of the container may be built on a Debian-style base
# that uses dpkg and apt as the package management system
#########################################################

ARG BASE_IMAGE=ubuntu:22.04
FROM ${BASE_IMAGE} AS cfsexec-ubuntu22

ARG EXTRA_PKGS=""

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        sudo ca-certificates curl lsb-release dumb-init jq \
        python3-minimal liblua5.3 libexpat1 libjson-c5 xz-utils \
        ${EXTRA_PKGS} && \
    rm -rf /var/cache/apt

ENTRYPOINT ["/usr/bin/dumb-init", "--" ]