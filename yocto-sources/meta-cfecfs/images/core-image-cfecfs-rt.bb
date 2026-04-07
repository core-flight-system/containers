# Start with the basic minimal image from the poky upstream
# Although the name suggests minimalism, this base image actually includes quite a bit
require recipes-rt/images/core-image-rt.bb
require images/core-image-cfecfs.inc

# NOTE: set PREFERRED_PROVIDER_virtual/kernel in local.conf to use this.
# See upstream core-image-rt.bb file
