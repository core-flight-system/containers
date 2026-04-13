#########################################################
# Build the ARM SDK image - contains the reference toolchain from the ARM developer website
#########################################################

ARG BASE_IMAGE=debian:latest
FROM ${BASE_IMAGE} AS arm-linux-sdk

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        tar xz-utils curl ca-certificates \
        ${EXTRA_PKGS} && \
    rm -rf /var/cache/apt

# Fetch SDK binary packages
RUN curl -fsL -o /root/arm-gnu-toolchain-11.3.rel1-x86_64-arm-none-linux-gnueabihf.tar.xz 'https://developer.arm.com/-/media/Files/downloads/gnu/11.3.rel1/binrel/arm-gnu-toolchain-11.3.rel1-x86_64-arm-none-linux-gnueabihf.tar.xz?rev=65520e9cdf324eca9c02f5302c904fa4&hash=0A1256D118EB7077B4BAA5B2A44FFB72'

# Install SDK
RUN mkdir -p /opt && \
    tar Jxf /root/arm-gnu-toolchain-11.3.rel1-x86_64-arm-none-linux-gnueabihf.tar.xz -C /opt && \
    chown -R root:root /opt/
