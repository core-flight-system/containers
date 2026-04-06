#########################################################
# Build the Yocto SDK image - contains QEMU riscv64 and mips toolchains
#########################################################

ARG BASE_IMAGE=cfsbuildenv-linux:test
FROM ${BASE_IMAGE} AS yocto-sdk-builder

ARG YOCTO_BRANCH=scarthgap

COPY yocto-sdk/meta-cfecfs meta-cfecfs
RUN git clone git://git.openembedded.org/meta-openembedded -b ${YOCTO_BRANCH} --depth 1
RUN git clone git://git.yoctoproject.org/poky -b ${YOCTO_BRANCH} --depth 1
RUN sudo apt-get update && \
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        locales chrpath cpio diffstat lz4 zstd wget 
RUN echo 'en_US.UTF-8 UTF-8' | sudo tee /etc/locale.gen && sudo locale-gen

ENV HOME=/home/docker
ENV BUILDDIR="${HOME}/build-cfs"
ENV OE_ADDED_PATHS="${HOME}/poky/scripts:${HOME}/poky/bitbake/bin:"
ENV BB_ENV_PASSTHROUGH_ADDITIONS="ALL_PROXY BBPATH_EXTRA BB_LOGCONFIG BB_NO_NETWORK BB_NUMBER_THREADS BB_SETSCENE_ENFORCE BB_SRCREV_POLICY DISTRO FTPS_PROXY FTP_PROXY GIT_PROXY_COMMAND HTTPS_PROXY HTTP_PROXY MACHINE NO_PROXY PARALLEL_MAKE SCREENDIR SDKMACHINE SOCKS5_PASSWD SOCKS5_USER SSH_AGENT_PID SSH_AUTH_SOCK STAMPS_DIR TCLIBC TCMODE all_proxy ftp_proxy ftps_proxy http_proxy https_proxy no_proxy"

RUN mkdir -p ${BUILDDIR}
COPY yocto-sdk/conf ${BUILDDIR}/conf
RUN ls -lR ${BUILDDIR} && cat ${BUILDDIR}/conf/bblayers.conf
RUN env PYTHONPATH=${HOME}/poky/bitbake/lib \
        PATH=${OE_ADDED_PATHS}${PATH} \
        BBPATH=${BUILDDIR} \
        MACHINE=qemuriscv64 \
        bitbake core-image-cfecfs --runall=fetch

FROM yocto-sdk-builder AS yocto-build-qemuriscv64
RUN env PYTHONPATH=${HOME}/poky/bitbake/lib \
        PATH=${OE_ADDED_PATHS}${PATH} \
        BBPATH=${BUILDDIR} \
        MACHINE=qemuriscv64 \
        bitbake core-image-cfecfs 
RUN env PYTHONPATH=${HOME}/poky/bitbake/lib \
        PATH=${OE_ADDED_PATHS}${PATH} \
        BBPATH=${BUILDDIR} \
        MACHINE=qemuriscv64 \
        bitbake core-image-cfecfs -c populate_sdk

RUN ls -lR build-cfs/tmp/deploy
RUN build-cfs/tmp/deploy/sdk/sh -y
#FROM yocto-sdk-installer AS yocto-sdk-qemuriscv64
#
## Fetch SDK binary packages
#ADD https://developer.nasa.gov/cFS/yocto-sandbox/releases/download/v0.0.1-testing/poky-glibc-x86_64-core-image-cfecfs-riscv64-qemuriscv64-toolchain-5.0.12.sh /root/qemuriscv64-toolchain.sh
#
#RUN chmod a+x root/qemuriscv64-toolchain.sh
#
## Install SDK
#RUN /root/qemuriscv64-toolchain.sh -y
#
#
#FROM yocto-sdk-installer AS yocto-sdk-qemumips
#
## Fetch SDK binary packages
#ADD https://developer.nasa.gov/cFS/yocto-sandbox/releases/download/v0.0.1-testing/poky-glibc-x86_64-core-image-cfecfs-mips32r2-qemumips-toolchain-5.0.12.sh /root/qemumips-toolchain.sh
#
#RUN chmod a+x root/qemumips-toolchain.sh
#
## Install SDK
#RUN /root/qemumips-toolchain.sh -y
#
#FROM scratch AS yocto-sdk
#
#COPY --from=yocto-sdk-qemuriscv64 /opt /opt
#COPY --from=yocto-sdk-qemumips /opt /opt
#
