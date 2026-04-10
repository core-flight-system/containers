#########################################################
# Build the Yocto SDK image - contains QEMU riscv64 and mips toolchains
#########################################################

ARG BASE_IMAGE=yocto-sources:latest
FROM ${BASE_IMAGE} AS yocto-build-image

ARG MACHINE=qemuriscv64
ENV MACHINE=${MACHINE}

RUN bitbake core-image-cfecfs 

RUN ls -l build-cfs/tmp/deploy/images
