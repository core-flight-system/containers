from ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive

# Basic dependencies
run apt-get update && apt-get install -y git make curl

# rtems dependencies
run apt-get install -y flex bison texinfo python-dev g++ unzip

# QEMU dependencies
run apt-get install -y qemu-system-i386

# setup and compile RTEMS BSP
run mkdir -p ${HOME}/rtems-4.11 \
  && cd ${HOME} \
  && git clone -b 4.11 https://gitlab.rtems.org/rtems/tools/rtems-source-builder.git \
  && cd rtems-source-builder/rtems \
  
# Download gnu mpc before source builder will fail to download it
  && mkdir sources \
  && curl https://ftp.gnu.org/gnu/mpc/mpc-1.0.3.tar.gz --output sources/mpc-1.0.3.tar.gz \
  && ../source-builder/sb-set-builder --prefix=$HOME/rtems-4.11 4.11/rtems-i386 \
  
# clone and bootstrap RTEMS source tree
  && cd ${HOME} \
  && git clone -b 4.11 https://gitlab.rtems.org/rtems/rtos/rtems.git \
  && export PATH=$HOME/rtems-4.11/bin:$PATH \
  && cd rtems && ./bootstrap \
  
# Build and install RTEMS pc686 BSP
  && cd ${HOME} \
  && mkdir b-pc686 \
  && cd b-pc686 \
  && ../rtems/configure --target=i386-rtems4.11 \
    --enable-rtemsbsp=pc686 \
    --prefix=${HOME}/rtems-4.11 \
    --enable-networking \
    --enable-cxx \
    --disable-posix \
    --disable-deprecated \
    BSP_ENABLE_VGA=0 \
    CLOCK_DRIVER_USE_TSC=1 \
    USE_COM1_AS_CONSOLE=1 \
    BSP_PRESS_KEY_FOR_RESET=0 \
    BSP_RESET_BOARD_AT_EXIT=1 \
  && make \
  && make install

# install git from source for updated version
run apt-get install -y libz-dev libssl-dev libcurl4-gnutls-dev libexpat1-dev gettext cmake
run curl -o git.tar.gz https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.26.2.tar.gz
run tar -zxf git.tar.gz && rm git.tar.gz
run cd git-* && make prefix=/usr/local && make prefix=/usr/local install

# Delete unnecessary directories now that rtems is built
run cd ${HOME} \
  && rm -rf rtems-source-builder b-pc686 rtems

# Additional dependencies
run apt-get install -y -f mtools parted udev bsdmainutils

# Install dosfstools from source release
run curl -o dosfstools.tar.gz http://deb.debian.org/debian/pool/main/d/dosfstools/dosfstools_4.2.orig.tar.gz
run tar -zxf dosfstools.tar.gz && rm dosfstools.tar.gz
run cd dosfstools-* && ./configure && make && make prefix=/usr/local install

# Remove unecessary dependencies now that rtems is built
run apt-get purge -y libz-dev libssl-dev libcurl4-gnutls-dev libexpat1-dev gettext unzip git flex bison texinfo curl
run apt-get autoremove -y
