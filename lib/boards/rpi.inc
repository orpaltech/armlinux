SOC_FAMILY="rpi"
SOC_GPU="vc4"
OVERLAY_PREFIX="bcm2835"

BOOT_DIR="/boot/firmware"

FIRMWARE_URL="https://github.com/raspberrypi/firmware"
FIRMWARE_BRANCH="master"
FIRMWARE_NAME="raspberrypi"

# The option should be overriden to change GPU support in QT5
QT5_OPENGL_OPTION="-opengl es2"

APT_BOARD_PACKAGES="rng-tools"

# Temporarily disable wireless due to broken SDHCI
ENABLE_WIRELESS="no"

# Raspberry-specific clean options
CLEAN_OPTIONS="${CLEAN_OPTIONS} mesa userland"
