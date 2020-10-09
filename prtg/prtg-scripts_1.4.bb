SUMMARY = "PRTG scripts"
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

SRC_URI = "file://scipts/*"

FILESEXTRAPATHS_prepend := "${THISDIR}:"
SRC_URI = "file://scripts/* "


do_install() {
    install -d ${D}/var/prtg/scripts
    install -m 0755 ${THISDIR}/scripts/* ${D}/var/prtg/scripts
}
