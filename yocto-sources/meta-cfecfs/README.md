# CFE/CFS layer for Yocto

This repository contains supplemental recipes that aid in creating embedded Linux
targets to host CFE/CFS.  Additional image targets are defined which contain the
dependencies for building and running CFS, as well as additional libraries and
tools that may be helpful for flight software deployment on Linux.

This layer may be used in conjunction with the "Poky" reference distribution from
the Yocto project to test and validate CFS on embedded linux, or as part of a
larger Yocto project based on a BSP from a hardware vendor for real deployment.

Note that for real deployment, it is expected that the image contents will need
additional customization beyond the "core-image-cfecfs" targets defined here.
This can be done by adding additional layers or by modifying the local.conf
file to customize the image.

## Getting Started

The traditional approach for Yocto is to source the `oe-init-build-env` script.
This sets up various enviroment variables in the _current_ shell to allow running
bitbake.  This layer also contains a template, and it can be used by setting
`TEMPLATECONF` before initializing the build environment.  This is only relevant
when creating new projects.

For example (to be run from the parent directory, where "meta-cfecfs" and other
layers have been cloned):
```
    export TEMPLATECONF=$PWD/meta-cfecfs/conf/templates/default
    cd poky
    source ./oe-init-build-env ../<my-build-dir>
```
Replace `<my-build-dir>` in the above with the desired name of your build directory
