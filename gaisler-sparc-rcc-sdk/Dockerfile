#########################################################
# Build the Yocto SDK image - contains QEMU riscv64 and mips toolchains
#########################################################

ARG BASE_IMAGE=debian:latest
FROM ${BASE_IMAGE} AS gaisler-sparc-rcc-sdk

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        curl tar xz-utils \
        ${EXTRA_PKGS} && \
    rm -rf /var/cache/apt

# Fetch SDK binary packages
RUN curl -fsL -o /root/sparc-rtems-5-gcc-10.5.0-1.3.2-linux.txz 'https://download.gaisler.com/anonftp/rcc/rcc-1.3/1.3.2/sparc-rtems-5-gcc-10.5.0-1.3.2-linux.txz'

# Install SDK
RUN mkdir -p /opt && \
    tar Jxf /root/sparc-rtems-5-gcc-10.5.0-1.3.2-linux.txz -C /opt && \
    chown -R root:root /opt/
