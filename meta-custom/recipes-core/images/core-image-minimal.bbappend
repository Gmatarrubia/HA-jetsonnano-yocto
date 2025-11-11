COMMON_PACKAGES = " \
    bash \
    bridge-utils \
    hostapd \
    iptables \
    avahi-daemon \
    kernel-modules \
    openssh openssh-keygen openssh-sftp-server \
    ntp \
    packagegroup-core-boot \
    procps \
    tzdata \
    canutils \
    bluez5 \
    usbutils \
    iw \
    xdg-user-dirs \
    htop \
    nano \
    docker-homeassistant \
    lsb-release \
"

COMMON_PACKAGES:append:jetson-nano-common = " \
    tegra-wifi \
    cuda-toolkit \
    cuda-libraries \
"

IMAGE_INSTALL += "${COMMON_PACKAGES}"

IMAGE_CLASSES += "image_types_tegra"
IMAGE_FSTYPES = "tegraflash tar.gz"
IMAGE_ROOTFS_SIZE="30314751"

