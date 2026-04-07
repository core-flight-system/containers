SUMMARY = "A package group to support CFE/CFS and related dependencies"
PR = "r1"

#
# packages which content depend on MACHINE_FEATURES need to be MACHINE_ARCH
#
PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit packagegroup

PROVIDES = "${PACKAGES}"
PACKAGES = ' packagegroup-cfecfs'

SUMMARY_packagegroup-cfecfs = "Libraries to support CFE/CFS with EDS"


# Time synchronization - this adds dependency to oe "networking" layer
RDEPENDS_packagegroup-cfecfs += "ntp"

# Graphics and image processing libraries
RDEPENDS_packagegroup-cfecfs += "openjpeg libjpeg-turbo libpng"

# SSH and related tools for remote access
RDEPENDS_packagegroup-cfecfs += "packagegroup-core-ssh-dropbear"

# Useful tools for file transfer
RDEPENDS_packagegroup-cfecfs += "lrzsz rsync"

# Filesystem and MTD device tools
#RDEPENDS_packagegroup-cfecfs += "mtd-utils e2fsprogs dosfstools"

# Generic file compression tools/libraries
RDEPENDS_packagegroup-cfecfs += "zlib libbz2 xz gzip bzip2 lz4"

# Support for CFE/STRS OE using embedded webserver/FCGI/JSON
RDEPENDS_packagegroup-cfecfs += "fcgi json-c lighttpd lua"

# Additional lighttpd modules
RDEPENDS_packagegroup-cfecfs += "lighttpd-module-fastcgi lighttpd-module-compress lighttpd-module-alias lighttpd-module-access lighttpd-module-accesslog"



