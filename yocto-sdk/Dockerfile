#########################################################
# Build the Yocto SDK image - contains QEMU riscv64 and mips toolchains
#########################################################

ARG BASE_IMAGE=yocto-compile:latest
FROM ${BASE_IMAGE} AS yocto-build-sdk        

RUN bitbake core-image-cfecfs -c populate_sdk

RUN ls -l build-cfs/tmp/deploy/sdk
RUN /bin/bash -c 'build-cfs/tmp/deploy/sdk/poky*-toolchain-*.sh -y'

FROM scratch AS yocto-sdk        
COPY --from=yocto-build-sdk /opt /opt
