#
# RaspberryPi CM4 armhf configuration
#
source "${BASH_SOURCE%/*}/rpi.inc"

BOARD_URL="https://www.raspberrypi.com/products/compute-module-4/"

SOC_NAME="Broadcom BCM2711"
SOC_PLATFORM=bcm2711
RPI_MODEL=4

UBOOT_CONFIG="rpi_4_32b_defconfig"
#UBOOT_USER_CONFIG=

KERNEL_BUILD_FAMILY_CONFIG="linux-rpi-cm4-io-arm.config"
#KERNEL_BUILD_BOARD_CONFIG=

DTB_FILE="broadcom/bcm2711-rpi-cm4-io.dtb"

QT_DEVICE_CONFIG="linux-rpi4-arm64-vc4-g++"

# WiFi/Bluetooth adapter is optional for CM4
SUPPORT_WLAN=no
