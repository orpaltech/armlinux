source "${BASH_SOURCE%/*}/rpi-common.inc"

#
# Default RaspberryPi aarch64 configuration
#
SOC_ARCH=arm64

DEBIAN_RELEASE_ARCH=arm64
KERNEL_ARCH="${SOC_ARCH}"
UBOOT_ARCH="${SOC_ARCH}"
LINUX_PLATFORM="aarch64-linux-gnu"

# Meson build tool parameters
MESON_CPU_FAMILY="aarch64"
MESON_CPU="armv8-a"

# Required to build openssl
OPENSSL_PLATFORM="linux-aarch64"

# you can directly specify tolchain paths
#UBOOT_CROSS_COMPILE=  
#KERNEL_CROSS_COMPILE=                                           
#CROSS_COMPILE= 

KERNEL_BUILD_CONFIG="defconfig"
#KERNEL_BUILD_FAMILY_CONFIG=
#KERNEL_BUILD_BOARD_CONFIG=

QEMU_BINARY="/usr/bin/qemu-aarch64-static"

# U-boot script variables, only used if [BOOTLOADER = uboot]
BOOTSCR_LOAD_ADDR=0x02200000
#BOOTSCR_RAMDISK_ADDR=0x00a00000
# load device tree at the specified address, or leave blank to use device tree prepared by 1st stage bootloader
BOOTSCR_FDT_ADDR=0x02600000
# load kernel at the specified address, or leave blank for automatic address assignment
BOOTSCR_KERNEL_ADDR=

KERNEL_MKIMAGE_WRAP=no
# Use compressed (gzip) or uncompressed (none) kernel image
KERNEL_MKIMAGE_COMPRESS=none
KERNEL_MKIMAGE_LOADADDR=0

# can be: "yes" - compressed (Image.gz, etc), otherwise uncompressed (Image)
KERNEL_IMAGE_COMPRESSED=no
