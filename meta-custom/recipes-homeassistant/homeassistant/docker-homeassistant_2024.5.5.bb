SUMMARY = "Open-source home automation platform running on Docker Compose container"
HOMEPAGE = "https://home-assistant.io/"
LICENSE = "CLOSED"

inherit systemd
inherit ha-user

SRC_URI += "\
    file://homeassistant.service \
    file://compose.yml \
    file://backup/ \
    "

FILES:${PN} += "\
    ${HOMEASSISTANT_DIR}/* \
    ${HOMEASSISTANT_CONFIG_DIR}/* \
"

SYSTEMD_AUTO_ENABLE = "enable"
SYSTEMD_SERVICE:${PN} = "homeassistant.service"

do_install:append () {
    # Install docker compose stuff
    install -d -o ${HOMEASSISTANT_USER} -g homeassistant ${D}${HOMEASSISTANT_DIR}
    install -m 0644 "${WORKDIR}/compose.yml" "${D}${HOMEASSISTANT_DIR}/"
    install -d "${D}${HOMEASSISTANT_DIR}/mosquitto"
    install -d "${D}${HOMEASSISTANT_DIR}/whisper"
    install -d "${D}${HOMEASSISTANT_DIR}/data"
    install -d "${D}${HOMEASSISTANT_DIR}/piper"
    install -d "${D}${HOMEASSISTANT_DIR}/wakeword"

    cd "${WORKDIR}"/backup/
    latest_backup="$(ls -t 2> /dev/null | head -n1)"
    [ -n "$latest_backup" ] && tar -xvf "${latest_backup}" -C "${D}${HOMEASSISTANT_DIR}/"
    cd -
    chown -R "${HOMEASSISTANT_USER}" "${D}${HOMEASSISTANT_DIR}"
    sed -i -e 's,@HOMEASSISTANT_DIR@,${HOMEASSISTANT_DIR},g' "${D}${HOMEASSISTANT_DIR}/compose.yml"


    # Install systemd unit files and set correct config directory
    install -d "${D}${systemd_unitdir}/system"
    install -m 0644 ${WORKDIR}/homeassistant.service "${D}${systemd_unitdir}/system"
    sed -i -e 's,@HOMEASSISTANT_DIR@,${HOMEASSISTANT_DIR},g' "${D}${systemd_unitdir}/system/homeassistant.service"
    sed -i -e 's,@HOMEASSISTANT_USER@,${HOMEASSISTANT_USER},g' "${D}${systemd_unitdir}/system/homeassistant.service"
}

# Home assistant docker dependencies
RDEPENDS:${PN} = " \
    nvidia-docker \
    docker-compose \
    bash \
"
