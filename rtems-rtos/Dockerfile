#########################################################
# Build the RTEMS BSP - pc686 by default (version configurable)
#########################################################

ARG TOOLS_IMAGE=rtems-tools
ARG BASE_IMAGE=debian:latest

FROM ${TOOLS_IMAGE} AS rtems-tools
FROM ${BASE_IMAGE} AS rtems-rtos

ARG RTEMS_VER=5    # Default, gets overridden by CI
ARG RTEMS_BSP=pc686

# Basic dependencies
RUN apt-get update && env DEBIAN_FRONTEND=noninteractive apt-get install -y curl sudo \
    build-essential g++ git flex bison texinfo python3 unzip bzip2 xz-utils \
    python-is-python3 python3-dev && \
    rm -rf /var/cache/apt

# Copy the RTEMS tools from the /opt
COPY --from=rtems-tools /opt /opt

# Create a non-root user to do the RTOS build
RUN useradd -m -c "Docker user" -U -G sudo docker && \
    echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers

USER docker
WORKDIR /home/docker
ENV PATH=/opt/rtems/bin:$PATH

# Clone RTEMS source
RUN . /opt/rtems/rtems-tools-info && \
    git clone -b ${RTEMS_VER} --depth 1 https://gitlab.rtems.org/rtems/rtos/rtems.git

# Conditional build based on RTEMS version
RUN . /opt/rtems/rtems-tools-info && \
    cd rtems && \
    if [ "${RTEMS_VER}" = "6" ]; then \
        echo "Building RTEMS 6 with waf..."; \
        echo "[${RTEMS_ARCH}/${RTEMS_BSP}]" > config.ini && \
        echo "BUILD_NETWORKING = True" >> config.ini && \
        echo "BUILD_TESTS = False" >> config.ini && \
        echo "BUILD_SAMPLES = False" >> config.ini && \
        python3 ./waf configure \
            --prefix=/opt/rtems-${RTEMS_VER} && \
        python3 ./waf build && \
        sudo python3 ./waf install; \
    else \
        echo "Building RTEMS 5 with autotools..."; \
        ./bootstrap && \
        cd .. && \
        mkdir b-${RTEMS_BSP} && \
        cd b-${RTEMS_BSP} && \
        ../rtems/configure --target=${RTEMS_ARCH}-rtems${RTEMS_VER} \
            --enable-rtemsbsp=${RTEMS_BSP} \
            --prefix=/opt/rtems-${RTEMS_VER} \
            --enable-networking \
            --enable-cxx \
            --disable-posix \
            --disable-deprecated && \
        make && \
        sudo make install; \
    fi
