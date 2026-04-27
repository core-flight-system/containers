#########################################################
# Build the Yocto SDK image - contains QEMU riscv64 and mips toolchains
#########################################################

ARG BASE_IMAGE=cfsbuildenv-linux:test
FROM ${BASE_IMAGE} AS yocto-sources

ARG YOCTO_BRANCH=scarthgap

COPY yocto-sources/meta-cfecfs meta-cfecfs
RUN git clone https://git.openembedded.org/meta-openembedded -b ${YOCTO_BRANCH} --depth 1
RUN git clone https://git.yoctoproject.org/poky -b ${YOCTO_BRANCH} --depth 1
RUN sudo apt-get update && \
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        locales chrpath cpio diffstat lz4 zstd wget 
RUN echo 'en_US.UTF-8 UTF-8' | sudo tee /etc/locale.gen && sudo locale-gen

# These environment vars need to be set for bitbake to work
ENV HOME=/home/docker
ENV BUILDDIR="${HOME}/build-cfs"
ENV OE_ADDED_PATHS="${HOME}/poky/scripts:${HOME}/poky/bitbake/bin:"
ENV BB_ENV_PASSTHROUGH_ADDITIONS="ALL_PROXY BBPATH_EXTRA BB_LOGCONFIG BB_NO_NETWORK BB_NUMBER_THREADS BB_SETSCENE_ENFORCE BB_SRCREV_POLICY DISTRO FTPS_PROXY FTP_PROXY GIT_PROXY_COMMAND HTTPS_PROXY HTTP_PROXY MACHINE NO_PROXY PARALLEL_MAKE SCREENDIR SDKMACHINE SOCKS5_PASSWD SOCKS5_USER SSH_AGENT_PID SSH_AUTH_SOCK STAMPS_DIR TCLIBC TCMODE all_proxy ftp_proxy ftps_proxy http_proxy https_proxy no_proxy"
ENV PYTHONPATH=${HOME}/poky/bitbake/lib
ENV PATH=${OE_ADDED_PATHS}${PATH}
ENV BBPATH=${BUILDDIR}

RUN mkdir -p ${BUILDDIR}
COPY yocto-sources/conf ${BUILDDIR}/conf
RUN ls -lR ${BUILDDIR} && cat ${BUILDDIR}/conf/bblayers.conf
RUN bitbake core-image-cfecfs --runall=fetch