# Common variables
HOMEASSISTANT_USER ?= "homeassistant"
HOMEASSISTANT_USER[doc] = "User the home-assistent service runs as docker compose container."
HOMEASSISTANT_DIR ?= "/home/${HOMEASSISTANT_USER}"
HOMEASSISTANT_DIR[doc] = "Installation directory used by home-assistant."
HOMEASSISTANT_CONFIG_DIR ?= "${HOMEASSISTANT_DIR}/config"
HOMEASSISTANT_CONFIG_DIR[doc] = "Configuration directory used by home-assistant."

inherit useradd

USERADD_PACKAGES += "${PN}"
GROUPADD_PARAM:${PN} = "-r docker"
USERADD_PARAM:${PN} = "\
    --home ${HOMEASSISTANT_DIR} \
    --shell /bin/false \
    --groups dialout,docker \
    -U ${HOMEASSISTANT_USER} \
"
