# List of additional packages to support CFE/CFS on embedded linux

# install the kernel modules
IMAGE_INSTALL += "kernel-modules"

# Time synchronization - this adds dependency to oe "networking" layer
IMAGE_INSTALL += "ntp"

# Basic startup scripts for CFS
IMAGE_INSTALL += "cfs-support"

# Connectivity networking packages
IMAGE_INSTALL += "dhcpcd packagegroup-core-ssh-dropbear"

# Useful tools for file transfer
IMAGE_INSTALL += "lrzsz rsync tftp-hpa"

# Filesystem and MTD device tools
IMAGE_INSTALL += "mtd-utils e2fsprogs dosfstools util-linux"

# Generic file compression tools/libraries
IMAGE_INSTALL += "zlib libbz2 xz gzip bzip2 lz4"

# Support for CFE/STRS OE using embedded webserver/FCGI/JSON
IMAGE_INSTALL += "fcgi json-c lighttpd lua"

# Additional lighttpd modules
IMAGE_INSTALL += "\
    lighttpd-module-auth \
    lighttpd-module-proxy \
    lighttpd-module-dirlisting \
    lighttpd-module-webdav \
    lighttpd-module-openssl \
    lighttpd-module-deflate \
    lighttpd-module-accesslog \
    lighttpd-module-status \
    "

# CFS should use a read-only root file system to enhance robustness in the possibility of
# spurious/unclean reboots
IMAGE_FEATURES += "read-only-rootfs"

# Configuration for the SDK generated with 'populate_sdk'
# Include kernel source so modules can be compiled by the SDK
TOOLCHAIN_TARGET_TASK:append = " kernel-dev"

# Include static development libraries
SDKIMAGE_FEATURES:append = " staticdev-pkgs"

# set the hostname to cfs
hostname:pn-base-files = "cfs"