#########################################################
# Build the Yocto SDK image - contains QEMU riscv64 and mips toolchains
#########################################################

ARG BASE_IMAGE=yocto-compile:latest
FROM ${BASE_IMAGE} AS yocto-compile

FROM scratch AS yocto-image       
COPY --from=yocto-compile /home/docker/build-cfs/tmp/deploy/images /images