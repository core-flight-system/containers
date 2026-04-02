# Example makefile for building all the images locally
# This is useful when debugging, so as to not REQUIRE the use of CI/CD to build

LOCAL_TAG ?= $(shell git rev-parse --short HEAD)
TGT_REPO ?= ghcr.io/core-flight-system/containers
REPO_TAG ?= latest

# The option --no-cache can be specified on command line if desired
EXTRA_BUILDARGS += --progress=plain

BASIC_IMAGE_SET += docker-executor
BASIC_IMAGE_SET += cfsexec-qemu
BASIC_IMAGE_SET += cfsexec-linux
BASIC_IMAGE_SET += cfsexec-ubuntu22
# BASIC_IMAGE_SET += yocto-sdk
BASIC_IMAGE_SET += gaisler-sparc-rcc-sdk
BASIC_IMAGE_SET += arm-linux-sdk
ALL_IMAGE_SET += $(BASIC_IMAGE_SET)

BUILDENV_IMAGE_SET += cfsbuildenv-doxygen
BUILDENV_IMAGE_SET += cfsbuildenv-linux
BUILDENV_IMAGE_SET += cfsbuildenv-mcdc
BUILDENV_IMAGE_SET += cfsbuildenv-rtems5
BUILDENV_IMAGE_SET += cfsbuildenv-rtems6
# BUILDENV_IMAGE_SET += cfsbuildenv-yocto
BUILDENV_IMAGE_SET += cfsbuildenv-arm-linux
BUILDENV_IMAGE_SET += cfsbuildenv-gaisler-sparc-rcc
BUILDENV_IMAGE_SET += cfsbuildenv-ubuntu22
BUILDENV_IMAGE_SET += cfsbuildenv-el9
BUILDENV_IMAGE_SET += cfsbuildenv-el8
ALL_IMAGE_SET += $(BUILDENV_IMAGE_SET)

# The rest of the images each need a custom rule with custom deps
ALL_IMAGE_SET += rtems5-tools
ALL_IMAGE_SET += rtems6-tools
ALL_IMAGE_SET += rtems5-rtos
ALL_IMAGE_SET += rtems6-rtos

ALL_BUILD_TARGETS      := $(addsuffix .build,$(ALL_IMAGE_SET))
ALL_IMAGE_TARGETS      := $(addsuffix .image,$(ALL_IMAGE_SET))
ALL_PUSH_TARGETS       := $(addsuffix .push,$(ALL_IMAGE_SET))
ALL_PULL_TARGETS       := $(addsuffix .pull,$(ALL_IMAGE_SET))
ALL_TRYPULL_TARGETS    := $(addsuffix .trypull,$(ALL_IMAGE_SET))

$(ALL_BUILD_TARGETS) $(ALL_IMAGE_TARGETS) $(ALL_PUSH_TARGETS) $(ALL_PULL_TARGETS): IMAGE_NAME = $(basename $(@))

all: $(ALL_IMAGE_TARGETS)
push: $(ALL_PUSH_TARGETS)
pull: $(ALL_PULL_TARGETS)

rtems5-rtos.build: rtems5-tools.image
rtems6-rtos.build: rtems6-tools.image
cfsbuildenv-rtems5.build: rtems5-rtos.image
cfsbuildenv-rtems6.build: rtems6-rtos.image
cfsbuildenv-arm-linux.build: arm-linux-sdk.image cfsbuildenv-linux.image
cfsbuildenv-gaisler-sparc-rcc.build: gaisler-sparc-rcc-sdk.image cfsbuildenv-linux.image


%.build:
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) -f $(subst rtems5-,rtems-,$(subst rtems6-,rtems-,$(IMAGE_NAME)))/Dockerfile .

# RTEMS 5 Tools
rtems5-tools.build:
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) \
		--build-arg RTEMS_VER=5 \
		-f rtems-tools/Dockerfile .

# RTEMS 6 Tools
rtems6-tools.build:
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) \
		--build-arg RTEMS_VER=6 \
		-f rtems-tools/Dockerfile .

# RTEMS 5 RTOS
rtems5-rtos.build:
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) \
		--build-arg TOOLS_IMAGE=rtems5-tools:$(LOCAL_TAG) \
		--build-arg RTEMS_VER=5 \
		-f rtems-rtos/Dockerfile .

# RTEMS 6 RTOS
rtems6-rtos.build:
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) \
		--build-arg TOOLS_IMAGE=rtems6-tools:$(LOCAL_TAG) \
		--build-arg RTEMS_VER=6 \
		-f rtems-rtos/Dockerfile .

# cFS Build Environment - RTEMS 5
cfsbuildenv-rtems5.build:
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) \
		--build-arg RTEMS_RTOS_IMAGE=rtems5-rtos:$(LOCAL_TAG) \
		-f cfsbuildenv-rtems/Dockerfile .

# cFS Build Environment - RTEMS 6
cfsbuildenv-rtems6.build:
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) \
		--build-arg RTEMS_RTOS_IMAGE=rtems6-rtos:$(LOCAL_TAG) \
		-f cfsbuildenv-rtems/Dockerfile .

cfsbuildenv-doxygen.build:
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) -f cfsbuildenv-doxygen/Dockerfile .

cfsbuildenv-mcdc.build:
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) -f cfsbuildenv-mcdc/Dockerfile .

cfsbuildenv-linux.build cfsbuildenv-ubuntu22.build:
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) -f cfsbuildenv-dpkg/Dockerfile .

cfsbuildenv-el8.build cfsbuildenv-el9.build:
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) -f cfsbuildenv-rpm/Dockerfile .

cfsbuildenv-yocto.build:
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) \
		--build-arg YOCTO_SDK_IMAGE=yocto-sdk:$(LOCAL_TAG) \
		-f cfsbuildenv-yocto/Dockerfile .

cfsbuildenv-arm-linux.build:
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) \
		--build-arg BASE_IMAGE=cfsbuildenv-linux:$(LOCAL_TAG) \
		--build-arg SDK_IMAGE=arm-linux-sdk:$(LOCAL_TAG) \
		-f cfsbuildenv-arm-linux/Dockerfile .

cfsbuildenv-gaisler-sparc-rcc.build:
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) \
		--build-arg BASE_IMAGE=cfsbuildenv-linux:$(LOCAL_TAG) \
		--build-arg SDK_IMAGE=gaisler-sparc-rcc-sdk:$(LOCAL_TAG) \
		-f cfsbuildenv-gaisler-sparc-rcc/Dockerfile .

cfsexec-linux.build cfsexec-ubuntu22.build:
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) -f cfsexec-dpkg/Dockerfile .

%.push:
	docker tag $(IMAGE_NAME):$(LOCAL_TAG) $(TGT_REPO)/$(IMAGE_NAME):$(LOCAL_TAG)
	docker push $(TGT_REPO)/$(IMAGE_NAME):$(LOCAL_TAG)

%.pull:
	docker pull $(TGT_REPO)/$(IMAGE_NAME):$(REPO_TAG)

# the idea here is to check if the image was already built, and if so, just
# use the already-built image from the container repo.  This is done by commit hash.
%.image:
	docker pull $(TGT_REPO)/$(IMAGE_NAME):$(LOCAL_TAG) || $(MAKE) $(IMAGE_NAME).build

# The following is a list of images that rely on a base
# image that uses the Debian-style package management via
# apt and dpkg, e.g. Debian/Ubuntu or any derivative thereof.  
DPKG_BUILD_TARGETS += arm-linux-sdk.build 
DPKG_BUILD_TARGETS += cfsbuildenv-doxygen.build 
DPKG_BUILD_TARGETS += docker-executor.build 
DPKG_BUILD_TARGETS += gaisler-sparc-rcc-sdk.build 
DPKG_BUILD_TARGETS += rtems5-rtos.build 
DPKG_BUILD_TARGETS += rtems5-tools.build
DPKG_BUILD_TARGETS += rtems6-rtos.build 
DPKG_BUILD_TARGETS += rtems6-tools.build
DPKG_BUILD_TARGETS += cfsbuildenv-rtems5.build 
DPKG_BUILD_TARGETS += cfsbuildenv-rtems6.build 
DPKG_BUILD_TARGETS += cfsbuildenv-linux.build 
DPKG_BUILD_TARGETS += cfsexec-linux.build

$(DPKG_BUILD_TARGETS): EXTRA_BUILDARGS += --build-arg BASE_IMAGE=debian:bookworm

# These images use rocky linux as an stand-in for RHEL
# They should work on any RHEL-like distro that uses rpm/dnf package management
%-el8.build: EXTRA_BUILDARGS += --build-arg BASE_IMAGE=rockylinux:8 
%-el9.build: EXTRA_BUILDARGS += --build-arg BASE_IMAGE=rockylinux:9

# These images are intentially using the older ubuntu baseline
%-ubuntu22.build: EXTRA_BUILDARGS += --build-arg BASE_IMAGE=ubuntu:jammy

# attempt to pull the image before building it here
.SECONDEXPANSION:
$(ALL_PUSH_TARGETS): $$(IMAGE_NAME).image
