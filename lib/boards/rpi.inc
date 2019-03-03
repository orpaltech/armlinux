SOC_FAMILY="rpi"
SOC_GPU="vc4"
OVERLAY_PREFIX="bcm2835"

BOOT_DIR="/boot/firmware"

FIRMWARE_URL="git://github.com/raspberrypi/firmware.git"
FIRMWARE_BRANCH="next"
FIRMWARE_NAME="raspberrypi"

BOOTSCR_LOAD_ADDR=0x1FFEBC00
# Load our device tree below CMA range
BOOTSCR_FDT_ADDR=0x1FFEFC00

# The option should be overriden to change GPU support in QT5
QT5_OPENGL_OPTION="-opengl es2"

APT_BOARD_PACKAGES="rng-tools"

# All RaspberryPi has the built-in Wi-Fi adapter
SUPPORT_WIRELESS=yes

# Raspberry-specific clean options
CLEAN_OPTIONS="${CLEAN_OPTIONS} mesa userland"
