SOC_ARCH=arm
SOC_FAMILY="rpi"
SOC_GPU="vc4"
OVERLAY_PREFIX="bcm2835"

DEBIAN_RELEASE_ARCH=armhf
KERNEL_ARCH=${SOC_ARCH}
UBOOT_ARCH="${SOC_ARCH}"
LINUX_PLATFORM="arm-linux-gnueabihf"

# Meson build tool parameters
MESON_CPU_FAMILY="arm"
MESON_CPU="armv7hl"

#ENABLE_UBOOT=yes
BOOT_DIR="/boot/firmware"

FIRMWARE_URL="https://github.com/raspberrypi/firmware.git"
FIRMWARE_BRANCH="stable"
FIRMWARE_NAME="raspberrypi"

# you can directly specify tolchain paths
#UBOOT_CROSS_COMPILE=
#KERNEL_CROSS_COMPILE=
#CROSS_COMPILE=

KERNEL_BUILD_FAMILY_CONFIG="linux-mainline-rpi.config"
KERNEL_OVERLAY_DIR="overlays"

QEMU_BINARY="/usr/bin/qemu-arm-static"

# U-boot script variables, only used if [ENABLE_UBOOT = yes]
BOOTSCR_LOAD_ADDR="0x02200000"
#BOOTSCR_RAMDISK_ADDR="0x00a00000"
# Uncomment line below in order to load device tree and apply overlays
#BOOTSCR_FDT_ADDR="0x02600000"
# Uncomment line below to change load address for the kernel
#BOOTSCR_KERNEL_ADDR="0x02800000"

KERNEL_MKIMAGE_WRAP=no
# Use compressed (gzip) or uncompressed (none) kernel image for ARM64
KERNEL_MKIMAGE_COMPRESS=none
KERNEL_MKIMAGE_LOADADDR=0x00008000
# Can be compressed source (Image.gz) or uncompressed (Image)
# KERNEL_IMAGE_SOURCE=Image
# KERNEL_IMAGE_TARGET="linux.uImage"
KERNEL_IMAGE_SOURCE=zImage
KERNEL_IMAGE_TARGET=linuz.img

# The option should be overriden to change GPU support in QT
QT_OPENGL_OPTION="-opengl es2"

# Extra debian packages to be installed for RaspberryPi
APT_BOARD_PACKAGES="rng-tools fbset"

# All RaspberryPi has the built-in Wi-Fi adapter
SUPPORT_WLAN="yes"

# Raspberry-specific clean options
CLEAN_OPTIONS="${CLEAN_OPTIONS} mesa-vc4 userland"

ENABLE_RPI_USERLAND=yes
