#########################################################
# This adds all the needed packages to build CFS
# for the the RTEMS operating system
#########################################################

ARG RTEMS_RTOS_IMAGE=rtems-rtos
ARG BASE_IMAGE=debian:latest

FROM ${RTEMS_RTOS_IMAGE} AS rtems-rtos
FROM ${BASE_IMAGE} AS cfsbuildenv-rtems

ARG EXTRA_PKGS=""

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        ca-certificates curl lsb-release software-properties-common jq \
        build-essential gawk cmake lcov python3 python3-venv python3-dev \
        python3-pip parted dosfstools mtools bsdextrautils \
        qemu-utils qemu-system-x86 \
        ${EXTRA_PKGS} && \
    rm -rf /var/cache/apt

# This just creates a normal user without sudo privileges
RUN useradd -m -c "Docker user" -U docker

# Bring the RTEMS tree entirely from the rtems-rtos image,
COPY --chown=docker:docker --from=rtems-rtos /opt /opt
ENV PATH=/opt/rtems/bin:$PATH

USER docker
WORKDIR /home/docker
