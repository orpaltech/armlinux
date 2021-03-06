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

# you can directly specify tolchain paths
# UBOOT_CROSS_COMPILE=  
# KERNEL_CROSS_COMPILE=                                           
# CROSS_COMPILE= 

QEMU_BINARY="/usr/bin/qemu-aarch64-static"

# ARM64 trusted firmware
FIRMWARE_URL="https://github.com/ARM-software/arm-trusted-firmware.git"
FIRMWARE_BRANCH="master"
FIRMWARE_NAME="mainline-atf"

KERNEL_BUILD_CONFIG="defconfig"
KERNEL_BUILD_FAMILY_CONFIG="linux-mainline-sunxi64.config"

KERNEL_OVERLAY_DIR="allwinner/overlays"

KERNEL_MKIMAGE_WRAP="yes"
# Use compressed (gzip) or uncompressed (none) kernel image
KERNEL_MKIMAGE_COMPRESS="none"
KERNEL_MKIMAGE_LOADADDR="0x40008000"
# Use compressed (Image.gz) or uncompressed (Image) source file
KERNEL_IMAGE_SOURCE="Image"
KERNEL_IMAGE_TARGET="linux.uImage"

# No wireless support by default, boards should override
SUPPORT_WLAN="no"

# The option should be overriden if you want GPU support in QT5
QT5_OPENGL_OPTION="-no-opengl"

# sunxi aarch64-specific clean options
CLEAN_OPTIONS="${CLEAN_OPTIONS} mesa-lima"
