#########################################################
# This adds all the needed packages to build CFS
# documentation and guides using Doxygen
#########################################################

ARG BASE_IMAGE=debian:latest
FROM ${BASE_IMAGE} AS cfsbuildenv-doxygen

ARG EXTRA_PKGS=""

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        sudo build-essential git cmake curl lsb-release software-properties-common rsync jq \
        doxygen graphviz texlive texlive-plain-generic texlive-fonts-extra texlive-latex-extra \
        ${EXTRA_PKGS} && \
    rm -rf /var/cache/apt