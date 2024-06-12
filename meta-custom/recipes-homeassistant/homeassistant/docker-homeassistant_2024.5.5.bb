SUMMARY = "Open-source home automation platform running on Docker Compose container"
HOMEPAGE = "https://home-assistant.io/"
LICENSE = "CLOSED"

HOMEASSISTANT_USER ?= "homeassistant"
HOMEASSISTANT_USER[doc] = "User the home-assistent service runs as docker compose container."
HOMEASSISTANT_DIR ?= "/home/${HOMEASSISTANT_USER}"
HOMEASSISTANT_DIR[doc] = "Installation directory used by home-assistant."
HOMEASSISTANT_CONFIG_DIR ?= "${HOMEASSISTANT_DIR}/config"
HOMEASSISTANT_CONFIG_DIR[doc] = "Configuration directory used by home-assistant."

inherit useradd systemd

SRC_URI += "\
    file://homeassistant.service \
    file://compose.yml \
    file://backup/ \
    "

FILES:${PN} += "\
    ${HOMEASSISTANT_DIR}/* \
    ${HOMEASSISTANT_CONFIG_DIR}/* \
"

USERADD_PACKAGES = "${PN}"
GROUPADD_PARAM:${PN} = "-r docker"
USERADD_PARAM:${PN} = "--system --home ${HOMEASSISTANT_DIR} \
                       --shell /bin/false \
                       --groups dialout,docker \
                       -U ${HOMEASSISTANT_USER} \
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

    for f in "${WORKDIR}"/backup/*
    do
        install -m 0644 "${f}" "${D}${HOMEASSISTANT_DIR}/"
    done
    chown -R "${HOMEASSISTANT_USER}" "${D}${HOMEASSISTANT_DIR}"
    sed -i -e 's,@HOMEASSISTANT_DIR@,${HOMEASSISTANT_DIR},g' "${D}${HOMEASSISTANT_DIR}/compose.yml"


    # Install systemd unit files and set correct config directory
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/homeassistant.service ${D}${systemd_unitdir}/system
    sed -i -e 's,@HOMEASSISTANT_DIR@,${HOMEASSISTANT_DIR},g' ${D}${systemd_unitdir}/system/homeassistant.service
    sed -i -e 's,@HOMEASSISTANT_USER@,${HOMEASSISTANT_USER},g' ${D}${systemd_unitdir}/system/homeassistant.service
}

# Home assistant docker dependencies
RDEPENDS:${PN} = " \
    nvidia-docker \
    python3-docker-compose \
"

# Home Assistant core dependencies
# not really needed, but it could be helpful.
RDEPENDS:${PN} += " \
    python3-aiohttp (>=3.8.1) \
    python3-astral (>=2.2) \
    python3-async-timeout (>=4.0.2) \
    python3-attrs (>=21.2.0) \
    python3-atomicwrites (>=1.4.0) \
    python3-awesomeversion (>=22.2.0) \
    python3-bcrypt (>=3.1.7) \
    python3-certifi (>=2021.5.30) \
    python3-ciso8601 (>=2.2.0) \
    python3-httpx (>=0.22.0) \
    python3-ifaddr (>=0.1.7) \
    python3-jinja2 (>=3.1.1) \
    python3-pyjwt (>=2.3.0) \
    python3-cryptography (>=36.0.2) \
    python3-python-slugify (>=4.0.1) \
    python3-pyyaml (>= 6.0) \
    python3-requests (>=2.27.1) \
    python3-typing-extensions (>=3.10.0.2) \
    python3-voluptuous (>=0.13.1) \
    python3-voluptuous-serialize (>=2.5.0) \
    python3-yarl (>=1.7.2) \
    \
    python3-pynacl (>=1.5.0) \
    python3-aiodiscover (>=1.4.11) \
    python3-aiohttp-cors (>=0.7.0) \
    python3-async-upnp-client (>=0.29.0) \
    python3-fnvhash (>=0.1.0) \
    python3-hass-nabucasa (>=0.54.0) \
    python3-lru-dict (>=1.1.7) \
    python3-paho-mqtt (>=1.6.1) \
    python3-pillow (>=9.0.1) \
    python3-pip (>=21.0) \
    python3-pyserial (>=3.5)\
    python3-pyudev (>=0.22.0) \
    python3-scapy (>=2.4.5) \
    python3-sqlalchemy (>=1.4.35) \
    python3-zeroconf (>=0.38.4) \
    \
    python3-pycryptodome (>=3.6.6) \
    python3-urllib3 (>=1.26.9) \
    python3-httplib2 (>=0.19.0) \
    python3-grpcio (>=1.45.0) \
    \
    python3-regex (>=2021.8.28) \
    python3-anyio (>=3.5.0) \
    python3-h11 (>=0.12) \
    python3-httpcore (>=0.14.7) \
    python3-hyperframe (>=5.2.0) \
    python3-engineio (>=3.13.1) \
    python3-socketio (>=4.6.0) \
    python3-multidict (>=6.0.2) \
    python3-tzdata \
    \
    python3-frozenlist (>=1.1.1) \
    python3-aiosignal (>=1.1.2) \
    python3-charset-normalizer (>=2.0) \
    python3-pytz \
    python3-six (>=1.4.1) \
    python3-cffi (>=1.1) \
    python3-markupsafe (>=2.0) \
    python3-text-unidecode (>=1.3) \
    python3-idna (>=2.5) \
    python3-pycparser (>= 2.7) \
    \
    python3-aiohue \
    python3-defusedxml (>=0.6.0) \
    python3-distro (>=1.4.0) \
    python3-importlib-metadata (>=1.5.0) \
    python3-mutagen (>=1.44.0) \
    python3-netdisco (>=2.6.0) \
    python3-pymetno (>=0.5.0) \
    python3-pysonos \
    python3-ruamel-yaml (>=0.15.100) \
    python3-samsungctl (>=0.7.1) \
    python3-samsungtvws (>=1.4.0) \
    python3-samsungtv (>=1.0.0) \
    python3-ssdp (>=1.0.1) \
    python3-xmltodict (>=0.12.0) \
    python3-modules \
    python3-coronavirus \
    python3-gtts-token \
    python3-pycognito \
    python3-spotipy \
    python3-systemd \
"
