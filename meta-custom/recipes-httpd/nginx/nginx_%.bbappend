FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

RDEPENDS:${PN} += "fcgiwrap"

SRC_URI:append = "\
    file://fcgiwrap.conf \
"

do_install:append() {
    install -m 0644 ${WORKDIR}/fcgiwrap.conf ${D}${sysconfdir}/nginx/fcgiwrap.conf
}
