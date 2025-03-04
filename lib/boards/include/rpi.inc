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

# Required to build openssl
OPENSSL_PLATFORM="linux-armv4 -march=armv7-a"

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
# Say "yes" if you want u-boot to use FDT prepared by the 1st stage bootloader. 
# Leave blank to use default behavior.
#BOOTSCR_FDT_FIRST_STAGE= 
# load device tree at the specified address, or leave blank if FDT prepared by 1st stage bootloader is used
BOOTSCR_FDT_ADDR=0x02600000
# load kernel at the specified address, or leave blank for automatic address assignment
BOOTSCR_KERNEL_ADDR=

KERNEL_MKIMAGE_WRAP=yes
KERNEL_MKIMAGE_LEGACY_FORMAT=yes
# use compressed (gzip, etc) or uncompressed (none) kernel image 
KERNEL_MKIMAGE_COMPRESS=none
KERNEL_MKIMAGE_LOADADDR=0x00100000

# must be yes for arm 32bit
KERNEL_IMAGE_COMPRESSED=yes
