#
# Default RaspberryPi configuration
#
SOC_FAMILY=rpi
SOC_GPU="vc4"

OVERLAY_PREFIX="bcm2835"

# Allow bootloader selection
BOOTLOAD_OPTIONS="native uboot"
BOOTLOADER="${BOOTLOADER}"

TARGET_BOOT_DIR="/boot/firmware"

FIRMWARE_URL="https://github.com/raspberrypi/firmware.git"
FIRMWARE_BRANCH=stable
FIRMWARE_VER=1.20250326
FIRMWARE_TAG="${FIRMWARE_VER}"
FIRMWARE_NAME=raspberrypi

KERNEL_OVERLAY_DIR="broadcom/overlays"

# option should be overriden to change GPU support in QT
QT_OPENGL_OPTION="-opengl es2"

# Extra debian packages to be installed for RaspberryPi
APT_BOARD_PACKAGES="rng-tools fbset"

# Most RaspberryPi are equipped with Wi-Fi adapters
SUPPORT_WLAN=yes

# Custom EDID binary for DRM
# DRM_USE_FIRMWARE_EDID="yes"
# DRM_EDID_BINARY="edid/640x480.bin"
# DRM_CONNECTOR="HDMI-A-1"
# DRM_VIDEO_MODE="640x480-24@60"
