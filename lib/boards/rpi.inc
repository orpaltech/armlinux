source "${BASH_SOURCE%/*}/rpi-common.inc"

#
# Default RaspberryPi armhf configuration
#
SOC_ARCH=arm

DEBIAN_RELEASE_ARCH=armhf
KERNEL_ARCH=${SOC_ARCH}
UBOOT_ARCH="${SOC_ARCH}"
LINUX_PLATFORM="arm-linux-gnueabihf"

# Meson build tool parameters
MESON_CPU_FAMILY="arm"
MESON_CPU="armv7hl"

# you can directly specify tolchain paths
#UBOOT_CROSS_COMPILE=
#KERNEL_CROSS_COMPILE=
#CROSS_COMPILE=

KERNEL_BUILD_CONFIG="bcm2835_defconfig"
#KERNEL_BUILD_FAMILY_CONFIG=
#KERNEL_BUILD_BOARD_CONFIG=

QEMU_BINARY="/usr/bin/qemu-arm-static"

# U-boot script variables, only used if [BOOTLOADER = uboot]
BOOTSCR_LOAD_ADDR=0x02200000
#BOOTSCR_RAMDISK_ADDR=0x00a00000
# load device tree at the specified address, or leave blank to use device tree prepared by 1st stage bootloader
BOOTSCR_FDT_ADDR=0x02600000
# load kernel at the specified address, or leave blank for automatic address assignment
BOOTSCR_KERNEL_ADDR=

KERNEL_MKIMAGE_WRAP=yes
# use compressed (gzip, etc) or uncompressed (none) kernel image 
KERNEL_MKIMAGE_COMPRESS=none
KERNEL_MKIMAGE_LOADADDR=0x00100000

# must be yes for arm 32bit
KERNEL_IMAGE_COMPRESSED=yes
