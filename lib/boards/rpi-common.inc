#
# Default RaspberryPi configuration
#
SOC_FAMILY=rpi
SOC_GPU="vc4"

OVERLAY_PREFIX="bcm2835"

# Allow bootloader selection
BOOTLOAD_OPTIONS="native uboot"
BOOTLOADER="${BOOTLOADER}"

BOOT_DIR="/boot/firmware"

FIRMWARE_URL="https://github.com/raspberrypi/firmware.git"
FIRMWARE_BRANCH="stable"
FIRMWARE_NAME="raspberrypi"

KERNEL_OVERLAY_DIR="broadcom/overlays"

# option should be overriden to change GPU support in QT
QT_OPENGL_OPTION="-opengl es2"

# Extra debian packages to be installed for RaspberryPi
APT_BOARD_PACKAGES="rng-tools fbset"

# Most RaspberryPi boards has a built-in Wi-Fi adapter
SUPPORT_WLAN="yes"

ENABLE_MESA=yes
# Raspberry-specific clean options
CLEAN_OPTIONS="${CLEAN_OPTIONS} mesa-vc4"

# Custom EDID binary for DRM
# DRM_USE_FIRMWARE_EDID="yes"
# DRM_EDID_BINARY="edid/640x480.bin"
# DRM_CONNECTOR="HDMI-A-1"
# DRM_VIDEO_MODE="640x480-24@60"
