#########################################################
# Build the RTEMS toolchain (version configurable)
#########################################################

ARG BASE_IMAGE=debian:latest
FROM ${BASE_IMAGE} AS rtems-tools

ARG RTEMS_VER=5    # Default, gets overridden by CI
ARG RTEMS_ARCH=i386

# Basic dependencies
RUN apt-get update && env DEBIAN_FRONTEND=noninteractive apt-get install -y curl \
    build-essential g++ git cmake flex bison texinfo python3 unzip bzip2 xz-utils \
    python-is-python3 python3-dev libgmp-dev libmpfr-dev && \
    rm -rf /var/cache/apt

# Build the RTEMS toolchains
RUN git clone -b ${RTEMS_VER} --depth 1 https://gitlab.rtems.org/rtems/tools/rtems-source-builder.git && \
    cd rtems-source-builder/rtems && \
    ../source-builder/sb-set-builder --prefix=/opt/rtems-${RTEMS_VER} ${RTEMS_VER}/rtems-${RTEMS_ARCH} && \
    cd ${HOME} && rm -rf rtems-source-builder

RUN ln -s /opt/rtems-${RTEMS_VER} /opt/rtems
RUN echo "\nRTEMS_VER=${RTEMS_VER}"   \
         "\nRTEMS_ARCH=${RTEMS_ARCH}" \
         "\n" \
        > /opt/rtems-${RTEMS_VER}/rtems-tools-info
