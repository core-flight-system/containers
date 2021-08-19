from ubuntu:18.04
ENV DEBIAN_FRONTEND=noninteractive

# Basic dependencies
run apt-get update && apt-get install -y git make

# rtems dependencies
run apt-get install -y flex bison texinfo python-dev g++ unzip

# QEMU dependencies
run apt-get install -y qemu-system-i386


# setup and compile RTEMS BSP
run mkdir -p ${HOME}/rtems-5 \
  && cd ${HOME} \
  && git clone -b 5 git://git.rtems.org/rtems-source-builder.git \
  && cd rtems-source-builder/rtems \
  && ../source-builder/sb-set-builder --prefix=$HOME/rtems-5 5/rtems-i386 \
# clone and bootstrap RTEMS source tree
  && cd ${HOME} \
  && git clone -b 5 git://git.rtems.org/rtems.git \
  && export PATH=$HOME/rtems-5/bin:$PATH \
  && cd rtems && ./bootstrap \
# Build and install RTEMS pc686 BSP
  && cd ${HOME} \
  && mkdir b-pc686 \
  && cd b-pc686 \
  && ../rtems/configure --target=i386-rtems5 \
    --enable-rtemsbsp=pc686 \
    --prefix=${HOME}/rtems-5 \
    --enable-networking \
    --enable-cxx \
    --disable-posix \
    --disable-deprecated \
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
