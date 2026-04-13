#########################################################
# Build the Yocto SDK image - contains QEMU riscv64 and mips toolchains
#########################################################

ARG BASE_IMAGE=debian:trixie
FROM ${BASE_IMAGE} AS yocto-sdk-installer


RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        python3-minimal python3-venv python3-pip file \
        ${EXTRA_PKGS} && \
    rm -rf /var/cache/apt


FROM yocto-sdk-installer AS yocto-sdk-qemuriscv64

# Fetch SDK binary packages
ADD https://developer.nasa.gov/cFS/yocto-sandbox/releases/download/v0.0.1-testing/poky-glibc-x86_64-core-image-cfecfs-riscv64-qemuriscv64-toolchain-5.0.12.sh /root/qemuriscv64-toolchain.sh

RUN chmod a+x root/qemuriscv64-toolchain.sh

# Install SDK
RUN /root/qemuriscv64-toolchain.sh -y


FROM yocto-sdk-installer AS yocto-sdk-qemumips

# Fetch SDK binary packages
ADD https://developer.nasa.gov/cFS/yocto-sandbox/releases/download/v0.0.1-testing/poky-glibc-x86_64-core-image-cfecfs-mips32r2-qemumips-toolchain-5.0.12.sh /root/qemumips-toolchain.sh

RUN chmod a+x root/qemumips-toolchain.sh

# Install SDK
RUN /root/qemumips-toolchain.sh -y

FROM scratch AS yocto-sdk

COPY --from=yocto-sdk-qemuriscv64 /opt /opt
COPY --from=yocto-sdk-qemumips /opt /opt
