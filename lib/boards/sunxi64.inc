#
# Default sunxi aarch64 configuration
#
SOC_FAMILY=sunxi
SOC_ARCH=arm64

BOOT_DIR="/boot"

DEBIAN_RELEASE_ARCH=arm64
KERNEL_ARCH=${SOC_ARCH}
UBOOT_ARCH=${SOC_ARCH}
LINUX_PLATFORM="aarch64-linux-gnu"

# Meson build tool parameters
MESON_CPU_FAMILY="aarch64"
MESON_CPU="armv8-a"

# You can directly specify tolchain paths
#UBOOT_CROSS_COMPILE=  
#KERNEL_CROSS_COMPILE=                                           
#CROSS_COMPILE= 

QEMU_BINARY="/usr/bin/qemu-aarch64-static"

# ARM64 trusted firmware
FIRMWARE_ATF_URL="https://github.com/ARM-software/arm-trusted-firmware.git"
FIRMWARE_ATF_BRANCH="master"
FIRMWARE_ATF_NAME="mainline-atf"

FIRMWARE_SCP_URL="https://github.com/crust-firmware/crust.git"
FIRMWARE_SCP_BRANCH="master"
FIRMWARE_SCP_NAME="scp-crust"

KERNEL_BUILD_CONFIG="defconfig"
KERNEL_BUILD_FAMILY_CONFIG="linux-mainline-sunxi64.config"

KERNEL_OVERLAY_DIR="allwinner/overlays"


# On sunxi platforms ENABLE_UBOOT must always be "yes"
ENABLE_UBOOT="yes"
BOOTSCR_LOAD_ADDR=0x43000000
BOOTSCR_FDT_ADDR=0x46000000
#BOOTSCR_KERNEL_ADDR=0x47000000
#BOOTSCR_RAMDISK_ADDR=0x48000000

KERNEL_MKIMAGE_WRAP=yes
# Use compressed (gzip) or uncompressed (none) kernel image
KERNEL_MKIMAGE_COMPRESS=none
KERNEL_MKIMAGE_LOADADDR=0x40000000
# Use compressed (Image.gz) or uncompressed (Image) source file
KERNEL_IMAGE_SOURCE=Image
KERNEL_IMAGE_TARGET="linux.uImage"

# No wireless by default, boards must override
SUPPORT_WLAN="no"

# The option should be overriden if you want GPU support in QT5
QT5_OPENGL_OPTION="-no-opengl"

# sunxi aarch64-specific clean options
CLEAN_OPTIONS="${CLEAN_OPTIONS} mesa-lima"
