SUMMARY = "Support package for CFE/CFS"
DESCRIPTION = "This includes scripts to mount the CFS partition and start CFS on boot"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=86d3f3a95c324c9479bd8986968f4327"

SRC_URI = "file://init.d/cfs \
           file://LICENSE \
           "
S = "${WORKDIR}"

INHIBIT_DEFAULT_DEPS = "1"

do_install () {
        install -m 0755 -d ${D}/cfs
        install -m 0755 -d ${D}/${sysconfdir}/init.d
        install -m 0644 ${WORKDIR}/init.d/cfs ${D}${sysconfdir}/init.d/cfs
        #install -m 0644 ${WORKDIR}/motd ${D}${sysconfdir}/motd
}

#PACKAGES = "${PN}-doc ${PN} ${PN}-dev ${PN}-dbg"
FILES:${PN} = "/"

PACKAGE_ARCH = "${MACHINE_ARCH}"

#CONFFILES:${PN} = "${sysconfdir}/"
#CONFFILES:${PN} += "${sysconfdir}/motd ${sysconfdir}/nsswitch.conf ${sysconfdir}/profile"
#
#INSANE_SKIP:${PN} += "empty-dirs"
