from ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# Basic dependencies
run apt-get update && apt-get install -y git make

# rtems dependencies
run apt-get install -y flex bison texinfo python3-dev g++ unzip libgmp-dev libmpfr-dev bzip2 xz-utils

# Make python3 the default python
run ln -s /usr/bin/python3 /usr/bin/python

# Added: Python development package installation for RTEMS build dependencies
run apt-get install -y python3-dev libpython3-dev

# QEMU dependencies
run apt-get install -y qemu-system-i386

# Copy config.ini file - Note that the environment variable HOME will not work here
copy rtems-6/config.ini /config.ini

# Temporary fix for legacy network stack
copy rtems-6/testbusy.c /testbusy.c

# Setup and compile RTEMS BSP
run mkdir -p ${HOME}/rtems-6 \
  && cd ${HOME} \
  && git clone -b 6 https://gitlab.rtems.org/rtems/tools/rtems-source-builder.git \
  && cd rtems-source-builder/rtems \
  && ../source-builder/sb-set-builder --prefix=$HOME/rtems-6 6/rtems-i386
# clone RTEMS source tree
run cd ${HOME} \
  && git clone -b 6 https://gitlab.rtems.org/rtems/rtos/rtems.git \
  && export PATH=$HOME/rtems-6/bin:$PATH \
# Build RTEMS BSP 
  && cd rtems \
  && mv /config.ini . \
  && ./waf configure --prefix=${HOME}/rtems-6 \
  && ./waf \
  && ./waf install
# Get and build the legacy network stack
run cd ${HOME} \
  && git clone -b 6 https://gitlab.rtems.org/rtems/pkg/rtems-net-legacy.git \
  && cd rtems-net-legacy \
  && git submodule update --init \
  && mv /testbusy.c libtest/testbusy.c \
  && ./waf configure --prefix=$HOME/rtems-6 \
  && ./waf build install
 
# install git from source for updated version
run apt-get install -y libz-dev libssl-dev libcurl4-gnutls-dev libexpat1-dev gettext cmake
run curl -o git.tar.gz https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.26.2.tar.gz
run tar -zxf git.tar.gz && rm git.tar.gz
run cd git-* && make prefix=/usr/local && make prefix=/usr/local install

# Delete unnecessary directories now that rtems is built
run cd ${HOME} \
  && rm -rf rtems-source-builder rtems rtems-net-legacy

# Additional dependencies
run apt-get install -y -f mtools parted udev bsdmainutils

# Install dosfstools from source release
run curl -o dosfstools.tar.gz http://deb.debian.org/debian/pool/main/d/dosfstools/dosfstools_4.2.orig.tar.gz
run tar -zxf dosfstools.tar.gz && rm dosfstools.tar.gz
run cd dosfstools-* && ./configure && make && make prefix=/usr/local install

# Remove unecessary dependencies now that rtems is built
run apt-get purge -y libz-dev libssl-dev libexpat1-dev gettext unzip git flex bison texinfo curl \
  libgmp-dev libmpfr-dev bzip2 xz-utils
run apt-get autoremove -y
