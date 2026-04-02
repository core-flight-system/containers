#########################################################
# This adds all the needed packages to execute a cFS build in QEMU
#
# This variant of the container may be built on a Debian-style base
# that uses dpkg and apt as the package management system
#########################################################

ARG BASE_IMAGE=debian:trixie
FROM ${BASE_IMAGE} AS cfsexec-qemu

ARG EXTRA_PKGS=""

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        sudo ca-certificates curl lsb-release dumb-init jq \
        qemu-system-x86 qemu-system-mips qemu-system-riscv qemu-system-arm qemu-system-ppc qemu-system-sparc \
        qemu-efi-riscv64 qemu-efi-arm qemu-efi-aarch64 \
        qemu-utils qemu-block-extra openssh-client \
        ${EXTRA_PKGS} && \
    rm -rf /var/cache/apt

ENTRYPOINT ["/usr/bin/dumb-init", "--" ]
