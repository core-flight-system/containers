FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libgmp-dev \
    libmpfr-dev \
    libmpc-dev \
    wget \
    tar \
    gcc \
    g++ \
    make \
    git \
    cmake \
    lcov \
    python3 \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Configure dynamic linker to include /usr/local/lib (for GCC libraries)
RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/gcc.conf && ldconfig

# Download and build GCC
RUN wget http://ftp.gnu.org/gnu/gcc/gcc-14.1.0/gcc-14.1.0.tar.gz && \
    tar -xf gcc-14.1.0.tar.gz && \
    cd gcc-14.1.0 && \
    ./contrib/download_prerequisites && \
    ./configure --prefix=/usr/local/gcc-14.1.0 --enable-languages=c,c++ --disable-multilib && \
    make -j$(nproc) && \
    make install && \
    ln -sf /usr/local/gcc-14.1.0/bin/gcc /usr/bin/gcc && \
    ln -sf /usr/local/gcc-14.1.0/bin/g++ /usr/bin/g++ && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /gcc-14.1.0

# Set the GCC binary path globally for the build process
ENV PATH=/usr/local/gcc-14.1.0/bin:$PATH