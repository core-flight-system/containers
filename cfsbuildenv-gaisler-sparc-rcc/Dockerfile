#########################################################
# This adds all the needed packages to build CFS
# for an embedded Linux target using Yocto
#########################################################

ARG SDK_IMAGE=gaisler-sparc-rcc:test
ARG BASE_IMAGE=cfsbuildenv-linux:test

FROM ${SDK_IMAGE} AS gaisler-sparc-rcc-sdk
FROM ${BASE_IMAGE} AS cfsbuildenv-gaisler-sparc-rcc

# Bring the SDK entirely from the sdk image,
COPY --from=gaisler-sparc-rcc-sdk /opt /opt
