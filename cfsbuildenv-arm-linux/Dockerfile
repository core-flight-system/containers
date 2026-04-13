#########################################################
# This adds all the needed packages to build CFS
# for an embedded Linux target using Yocto
#########################################################

ARG SDK_IMAGE=arm-linux-sdk:test
ARG BASE_IMAGE=cfsbuildenv-linux:test

FROM ${SDK_IMAGE} AS arm-linux-sdk
FROM ${BASE_IMAGE} AS cfsbuildenv-arm-linux

# Bring the SDK entirely from the sdk image,
COPY --from=arm-linux-sdk /opt /opt
