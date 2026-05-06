# Example makefile for building all the images locally
# This is useful when debugging, so as to not REQUIRE the use of CI/CD to build

LOCAL_TAG ?= $(shell git rev-parse --short HEAD)
TGT_REPO ?= ghcr.io/core-flight-system
REPO_TAG ?= $(LOCAL_TAG)

PULL_DEP_CMD = docker inspect  --format '{{.Id}}' $(QUALIFIED_LOCAL_NAME)
MAKE_DEP_CMD = $(MAKE) $(IMAGE_NAME).build

# If AUTOBUILD_DEPS is set, then recursively build any missing images
# that are dependencies of the target image.  If this is not set,
# then the build will fail if the dependency does not exist.  This
# must always be true at the top level or else nothing will build.
ifeq ($(MAKELEVEL),0)
# On the first level make we must build it if it is part of MAKECMDGOALS, never fetch it
BUILD_DEP_CMD = if [ "x$(findstring $(@),$(MAKECMDGOALS))" = "x" ]; then $(PULL_DEP_CMD); else $(MAKE_DEP_CMD); fi 
else ifneq ($(AUTOBUILD_DEPS),)
# On other levels, fetch if exists, otherwise build it
BUILD_DEP_CMD = $(PULL_DEP_CMD) || $(MAKE_DEP_CMD)
else
# Never build the image, only fetch it
BUILD_DEP_CMD = $(PULL_DEP_CMD)
endif

# The option --no-cache can be specified on command line if desired
EXTRA_BUILDARGS += --progress=plain

QUALIFIED_LOCAL_NAME = $(TGT_REPO)/$(IMAGE_NAME):$(LOCAL_TAG)
QUALIFIED_REPO_NAME  = $(TGT_REPO)/$(IMAGE_NAME):$(REPO_TAG)

BASIC_IMAGE_SET += docker-executor
BASIC_IMAGE_SET += cfsexec-qemu
BASIC_IMAGE_SET += cfsexec-linux
BASIC_IMAGE_SET += cfsexec-ubuntu22
BASIC_IMAGE_SET += gaisler-sparc-rcc-sdk
BASIC_IMAGE_SET += arm-linux-sdk
ALL_IMAGE_SET += $(BASIC_IMAGE_SET)

BUILDENV_IMAGE_SET += cfsbuildenv-doxygen
BUILDENV_IMAGE_SET += cfsbuildenv-linux
BUILDENV_IMAGE_SET += cfsbuildenv-mcdc
BUILDENV_IMAGE_SET += cfsbuildenv-rtems5
BUILDENV_IMAGE_SET += cfsbuildenv-rtems6
BUILDENV_IMAGE_SET += cfsbuildenv-arm-linux
BUILDENV_IMAGE_SET += cfsbuildenv-gaisler-sparc-rcc
BUILDENV_IMAGE_SET += cfsbuildenv-ubuntu22
BUILDENV_IMAGE_SET += cfsbuildenv-el9
BUILDENV_IMAGE_SET += cfsbuildenv-el8
BUILDENV_IMAGE_SET += cfsbuildenv-yocto
ALL_IMAGE_SET += $(BUILDENV_IMAGE_SET)

# Images related to the yocto build
# This is a large build and is disk and memory intensive
# This may be excluded from the daily builds for this reason
YOCTO_IMAGE_SET += yocto-sources
YOCTO_IMAGE_SET += yocto-compile-qemuriscv64
YOCTO_IMAGE_SET += yocto-image-qemuriscv64
YOCTO_IMAGE_SET += yocto-sdk-qemuriscv64
YOCTO_IMAGE_SET += yocto-compile-qemumips
YOCTO_IMAGE_SET += yocto-image-qemumips
YOCTO_IMAGE_SET += yocto-sdk-qemumips
ALL_IMAGE_SET += $(YOCTO_IMAGE_SET)

# Images related to rtems build
RTEMS_IMAGE_SET += rtems5-tools
RTEMS_IMAGE_SET += rtems6-tools
RTEMS_IMAGE_SET += rtems5-rtos
RTEMS_IMAGE_SET += rtems6-rtos
ALL_IMAGE_SET += $(RTEMS_IMAGE_SET)

ALL_BUILD_TARGETS      := $(addsuffix .build,$(ALL_IMAGE_SET))
ALL_IMAGE_TARGETS      := $(addsuffix .image,$(ALL_IMAGE_SET))
ALL_PUSH_TARGETS       := $(addsuffix .push,$(ALL_IMAGE_SET))
ALL_PULL_TARGETS       := $(addsuffix .pull,$(ALL_IMAGE_SET))

# The pipeline targets exclude yocto
ALL_PIPELINE_SET = $(BASIC_IMAGE_SET) $(BUILDENV_IMAGE_SET) $(YOCTO_IMAGE_SET) $(RTEMS_IMAGE_SET)

$(ALL_BUILD_TARGETS) $(ALL_IMAGE_TARGETS) $(ALL_PUSH_TARGETS) $(ALL_PULL_TARGETS): IMAGE_NAME = $(basename $(@))

all: $(ALL_IMAGE_TARGETS)
push: $(ALL_PUSH_TARGETS)
pull: $(ALL_PULL_TARGETS)

all-pipeline: $(addsuffix .image,$(ALL_PIPELINE_SET))
push-pipeline: $(addsuffix .push,$(ALL_PIPELINE_SET))
pull-pipeline: $(addsuffix .pull,$(ALL_PIPELINE_SET))

check:
	env

rtems5-rtos.image: rtems5-tools.image
rtems6-rtos.image: rtems6-tools.image
cfsbuildenv-rtems5.image: rtems5-rtos.image
cfsbuildenv-rtems6.image: rtems6-rtos.image
cfsbuildenv-arm-linux.image: arm-linux-sdk.image cfsbuildenv-linux.image
cfsbuildenv-gaisler-sparc-rcc.image: gaisler-sparc-rcc-sdk.image cfsbuildenv-linux.image
cfsbuildenv-yocto.image: yocto-sdk-qemuriscv64.image yocto-sdk-qemumips.image


%.build:
	docker build $(EXTRA_BUILDARGS) -t $(QUALIFIED_LOCAL_NAME) -f $(subst rtems5-,rtems-,$(subst rtems6-,rtems-,$(IMAGE_NAME)))/Dockerfile .

# RTEMS 5 Tools
rtems5-tools.build:
	docker build $(EXTRA_BUILDARGS) -t $(QUALIFIED_LOCAL_NAME) \
		--build-arg RTEMS_VER=5 \
		-f rtems-tools/Dockerfile .

# RTEMS 6 Tools
rtems6-tools.build:
	docker build $(EXTRA_BUILDARGS) -t $(QUALIFIED_LOCAL_NAME) \
		--build-arg RTEMS_VER=6 \
		-f rtems-tools/Dockerfile .

# RTEMS 5 RTOS
rtems5-rtos.build:
	docker build $(EXTRA_BUILDARGS) -t $(QUALIFIED_LOCAL_NAME) \
		--build-arg TOOLS_IMAGE=$(TGT_REPO)/rtems5-tools:$(LOCAL_TAG) \
		--build-arg RTEMS_VER=5 \
		-f rtems-rtos/Dockerfile .

# RTEMS 6 RTOS
rtems6-rtos.build:
	docker build $(EXTRA_BUILDARGS) -t $(QUALIFIED_LOCAL_NAME) \
		--build-arg TOOLS_IMAGE=$(TGT_REPO)/rtems6-tools:$(LOCAL_TAG) \
		--build-arg RTEMS_VER=6 \
		-f rtems-rtos/Dockerfile .

# cFS Build Environment - RTEMS 5
cfsbuildenv-rtems5.build:
	docker build $(EXTRA_BUILDARGS) -t $(QUALIFIED_LOCAL_NAME) \
		--build-arg RTEMS_RTOS_IMAGE=$(TGT_REPO)/rtems5-rtos:$(LOCAL_TAG) \
		-f cfsbuildenv-rtems/Dockerfile .

# cFS Build Environment - RTEMS 6
cfsbuildenv-rtems6.build:
	docker build $(EXTRA_BUILDARGS) -t $(QUALIFIED_LOCAL_NAME) \
		--build-arg RTEMS_RTOS_IMAGE=$(TGT_REPO)/rtems6-rtos:$(LOCAL_TAG) \
		-f cfsbuildenv-rtems/Dockerfile .

cfsbuildenv-doxygen.build:
	docker build $(EXTRA_BUILDARGS) -t $(QUALIFIED_LOCAL_NAME) -f cfsbuildenv-doxygen/Dockerfile .

cfsbuildenv-mcdc.build:
	docker build $(EXTRA_BUILDARGS) -t $(QUALIFIED_LOCAL_NAME) -f cfsbuildenv-mcdc/Dockerfile .

cfsbuildenv-linux.build cfsbuildenv-ubuntu22.build:
	docker build $(EXTRA_BUILDARGS) -t $(QUALIFIED_LOCAL_NAME) -f cfsbuildenv-dpkg/Dockerfile .

cfsbuildenv-el8.build cfsbuildenv-el9.build:
	docker build $(EXTRA_BUILDARGS) -t $(QUALIFIED_LOCAL_NAME) -f cfsbuildenv-rpm/Dockerfile .

yocto-sources.build: cfsbuildenv-linux.image
yocto-sources.build:
	docker build $(EXTRA_BUILDARGS) -t $(QUALIFIED_LOCAL_NAME) \
		--build-arg BASE_IMAGE=$(TGT_REPO)/cfsbuildenv-linux:$(LOCAL_TAG) \
		-f yocto-sources/Dockerfile .

yocto-compile-qemuriscv64.build: yocto-sources.image
yocto-compile-qemumips.build: yocto-sources.image
yocto-compile-%.build:
	docker build $(EXTRA_BUILDARGS) -t $(QUALIFIED_LOCAL_NAME) \
		--build-arg BASE_IMAGE=$(TGT_REPO)/yocto-sources:$(LOCAL_TAG) \
		--build-arg MACHINE=$(*) \
		-f yocto-compile/Dockerfile .

yocto-image-qemuriscv64.build: yocto-compile-qemuriscv64.image
yocto-image-qemumips.build: yocto-compile-qemumips.image
yocto-image-%.build:
	docker build $(EXTRA_BUILDARGS) -t $(QUALIFIED_LOCAL_NAME) \
		--build-arg BASE_IMAGE=$(TGT_REPO)/yocto-compile-$(*):$(LOCAL_TAG) \
		--build-arg MACHINE=$(*) \
		-f yocto-image/Dockerfile .

yocto-sdk-qemuriscv64.build: yocto-compile-qemuriscv64.image
yocto-sdk-qemumips.build: yocto-compile-qemumips.image
yocto-sdk-%.build:
	docker build $(EXTRA_BUILDARGS) -t $(QUALIFIED_LOCAL_NAME) \
		--build-arg BASE_IMAGE=$(TGT_REPO)/yocto-compile-$(*):$(LOCAL_TAG) \
		--build-arg MACHINE=$(*) \
		-f yocto-sdk/Dockerfile .

cfsbuildenv-yocto.build:
	docker build $(EXTRA_BUILDARGS) -t $(QUALIFIED_LOCAL_NAME) \
		--build-arg YOCTO_SDK_IMAGE_RISCV=$(TGT_REPO)/yocto-sdk-qemuriscv64:$(LOCAL_TAG) \
		--build-arg YOCTO_SDK_IMAGE_MIPS=$(TGT_REPO)/yocto-sdk-qemumips:$(LOCAL_TAG) \
		-f cfsbuildenv-yocto/Dockerfile .

cfsbuildenv-arm-linux.build:
	docker build $(EXTRA_BUILDARGS) -t $(QUALIFIED_LOCAL_NAME) \
		--build-arg BASE_IMAGE=$(TGT_REPO)/cfsbuildenv-linux:$(LOCAL_TAG) \
		--build-arg SDK_IMAGE=$(TGT_REPO)/arm-linux-sdk:$(LOCAL_TAG) \
		-f cfsbuildenv-arm-linux/Dockerfile .

cfsbuildenv-gaisler-sparc-rcc.build:
	docker build $(EXTRA_BUILDARGS) -t $(QUALIFIED_LOCAL_NAME) \
		--build-arg BASE_IMAGE=$(TGT_REPO)/cfsbuildenv-linux:$(LOCAL_TAG) \
		--build-arg SDK_IMAGE=$(TGT_REPO)/gaisler-sparc-rcc-sdk:$(LOCAL_TAG) \
		-f cfsbuildenv-gaisler-sparc-rcc/Dockerfile .

cfsexec-linux.build cfsexec-ubuntu22.build:
	docker build $(EXTRA_BUILDARGS) -t $(QUALIFIED_LOCAL_NAME) -f cfsexec-dpkg/Dockerfile .

%.push:
	docker push $(QUALIFIED_LOCAL_NAME)
	docker tag $(QUALIFIED_LOCAL_NAME) $(QUALIFIED_REPO_NAME)
	docker push $(QUALIFIED_REPO_NAME)

%.pull:
	docker pull $(QUALIFIED_REPO_NAME)

# the idea here is to check if the image was already built, and if so, just
# use the already-built image from the container repo.  This is done by commit hash.
%.image:
	docker pull $(QUALIFIED_LOCAL_NAME) || /bin/true
	$(BUILD_DEP_CMD)

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
