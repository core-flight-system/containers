# Example makefile for building all the images locally
# This is useful when debugging, so as to not REQUIRE the use of CI/CD to build

LOCAL_TAG ?= test
TGT_REPO ?= ghcr.io/core-flight-system/containers
REPO_TAG ?= latest

# The option --no-cache can be specified on command line if desired
EXTRA_BUILDARGS += --progress=plain

BASIC_IMAGE_SET += docker-executor
BASIC_IMAGE_SET += cfsexec-qemu
# BASIC_IMAGE_SET += yocto-sdk
BASIC_IMAGE_SET += gaisler-sparc-rcc-sdk
BASIC_IMAGE_SET += arm-linux-sdk
ALL_IMAGE_SET += $(BASIC_IMAGE_SET)

BUILDENV_IMAGE_SET += cfsbuildenv-doxygen
BUILDENV_IMAGE_SET += cfsbuildenv-mcdc
BUILDENV_IMAGE_SET += cfsbuildenv-linux
BUILDENV_IMAGE_SET += cfsbuildenv-rtems5
BUILDENV_IMAGE_SET += cfsbuildenv-rtems6
BUILDENV_IMAGE_SET += cfsbuildenv-el9
BUILDENV_IMAGE_SET += cfsbuildenv-el8
# BUILDENV_IMAGE_SET += cfsbuildenv-yocto
BUILDENV_IMAGE_SET += cfsbuildenv-arm-linux
BUILDENV_IMAGE_SET += cfsbuildenv-gaisler-sparc-rcc
ALL_IMAGE_SET += $(BUILDENV_IMAGE_SET)

# The rest of the images each need a custom rule with custom deps
ALL_IMAGE_SET += rtems5-tools
ALL_IMAGE_SET += rtems6-tools
ALL_IMAGE_SET += rtems5-rtos
ALL_IMAGE_SET += rtems6-rtos

BASIC_IMAGE_TARGETS    := $(addsuffix .image,$(BASIC_IMAGE_SET))
BUILDENV_IMAGE_TARGETS := $(addsuffix .image,$(BUILDENV_IMAGE_SET))
ALL_IMAGE_TARGETS      := $(addsuffix .image,$(ALL_IMAGE_SET))
ALL_PUSH_TARGETS       := $(addsuffix .push,$(ALL_IMAGE_SET))
ALL_PULL_TARGETS       := $(addsuffix .pull,$(ALL_IMAGE_SET))

$(ALL_IMAGE_TARGETS) $(ALL_PUSH_TARGETS) $(ALL_PULL_TARGETS): IMAGE_NAME = $(basename $(@))

#$(BUILDENV_IMAGE_TARGETS): $(BASIC_IMAGE_TARGETS)

$(BASIC_IMAGE_TARGETS):
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) -f $(subst rtems5-,rtems-,$(subst rtems6-,rtems-,$(IMAGE_NAME)))/Dockerfile .

# RTEMS 5 Tools
rtems5-tools.image:
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) \
		--build-arg RTEMS_VER=5 \
		-f rtems-tools/Dockerfile .

# RTEMS 6 Tools
rtems6-tools.image:
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) \
		--build-arg RTEMS_VER=6 \
		-f rtems-tools/Dockerfile .

# RTEMS 5 RTOS
rtems5-rtos.image: rtems5-tools.image
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) \
		--build-arg TOOLS_IMAGE=rtems5-tools:$(LOCAL_TAG) \
		--build-arg RTEMS_VER=5 \
		-f rtems-rtos/Dockerfile .

# RTEMS 6 RTOS
rtems6-rtos.image: rtems6-tools.image
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) \
		--build-arg TOOLS_IMAGE=rtems6-tools:$(LOCAL_TAG) \
		--build-arg RTEMS_VER=6 \
		-f rtems-rtos/Dockerfile .

# cFS Build Environment - RTEMS 5
cfsbuildenv-rtems5.image: rtems5-rtos.image
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) \
		--build-arg RTEMS_RTOS_IMAGE=rtems5-rtos:$(LOCAL_TAG) \
		-f cfsbuildenv-rtems/Dockerfile .

# cFS Build Environment - RTEMS 6
cfsbuildenv-rtems6.image: rtems6-rtos.image
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) \
		--build-arg RTEMS_RTOS_IMAGE=rtems6-rtos:$(LOCAL_TAG) \
		-f cfsbuildenv-rtems/Dockerfile .

cfsbuildenv-doxygen.image:
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) -f cfsbuildenv-doxygen/Dockerfile .

cfsbuildenv-mcdc.image:
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) -f cfsbuildenv-mcdc/Dockerfile .

cfsbuildenv-linux.image cfsbuildenv-ubuntu22.image:
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) -f cfsbuildenv-dpkg/Dockerfile .

cfsbuildenv-el8.image cfsbuildenv-el9.image:
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) -f cfsbuildenv-rpm/Dockerfile .

cfsbuildenv-yocto.image:
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) \
		--build-arg YOCTO_SDK_IMAGE=yocto-sdk:$(LOCAL_TAG) \
		-f cfsbuildenv-yocto/Dockerfile .

cfsbuildenv-arm-linux.image: arm-linux-sdk.image cfsbuildenv-linux.image
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) \
		--build-arg BASE_IMAGE=cfsbuildenv-linux:$(LOCAL_TAG) \
		--build-arg SDK_IMAGE=arm-linux-sdk:$(LOCAL_TAG) \
		-f cfsbuildenv-arm-linux/Dockerfile .

cfsbuildenv-gaisler-sparc-rcc.image: gaisler-sparc-rcc-sdk.image cfsbuildenv-linux.image
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) \
		--build-arg BASE_IMAGE=cfsbuildenv-linux:$(LOCAL_TAG) \
		--build-arg SDK_IMAGE=gaisler-sparc-rcc-sdk:$(LOCAL_TAG) \
		-f cfsbuildenv-gaisler-sparc-rcc/Dockerfile .

cfsexec-linux.image cfsexec-ubuntu22.image:
	docker build $(EXTRA_BUILDARGS) -t $(IMAGE_NAME):$(LOCAL_TAG) -f cfsexec-dpkg/Dockerfile .

$(ALL_PUSH_TARGETS):
	docker tag $(IMAGE_NAME):$(LOCAL_TAG) $(TGT_REPO)/$(IMAGE_NAME):$(REPO_TAG)
	docker push $(TGT_REPO)/$(IMAGE_NAME):$(REPO_TAG)

$(ALL_PULL_TARGETS):
	docker pull $(TGT_REPO)/$(IMAGE_NAME):$(REPO_TAG)

push: $(ALL_PUSH_TARGETS)
pull: $(ALL_PULL_TARGETS)
all: $(ALL_IMAGE_TARGETS)

BASE_IMAGE_TGTS += arm-linux-sdk.image 
BASE_IMAGE_TGTS += cfsbuildenv-doxygen.image 
BASE_IMAGE_TGTS += docker-executor.image 
BASE_IMAGE_TGTS += gaisler-sparc-rcc-sdk.image 
BASE_IMAGE_TGTS += rtems5-rtos.image 
BASE_IMAGE_TGTS += rtems5-tools.image
BASE_IMAGE_TGTS += rtems6-rtos.image 
BASE_IMAGE_TGTS += rtems6-tools.image
BASE_IMAGE_TGTS += cfsbuildenv-rtems5.image 
BASE_IMAGE_TGTS += cfsbuildenv-rtems6.image 
BASE_IMAGE_TGTS += cfsbuildenv-linux.image 
BASE_IMAGE_TGTS += cfsexec-linux.image

$(BASE_IMAGE_TGTS): EXTRA_BUILDARGS += --build-arg BASE_IMAGE=debian:bookworm

cfsbuildenv-el8.image: EXTRA_BUILDARGS += --build-arg BASE_IMAGE=rockylinux:8 
cfsbuildenv-el9.image: EXTRA_BUILDARGS += --build-arg BASE_IMAGE=rockylinux:9

cfsbuildenv-ubuntu22.image cfsexec-ubuntu22.image: EXTRA_BUILDARGS += --build-arg BASE_IMAGE=ubuntu:jammy
