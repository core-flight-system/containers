#########################################################
# Image capable of building CFS and providing MC/DC coverage analysis
# This requires use of a very recent GCC version
#########################################################

ARG BASE_IMAGE=docker.io/gcc:14
FROM ${BASE_IMAGE} AS gcc14-build

ARG EXTRA_PKGS=""

# Install the basic CFS build environment
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        sudo curl lsb-release apt-transport-https \
        git gawk cmake lcov xsltproc rsync jq \
        python3 python3-venv python3-dev libexpat-dev liblua5.3-dev libjson-c-dev \
        ${EXTRA_PKGS} && \
    rm -rf /var/cache/apt
