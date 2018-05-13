#
# Default sunxi aarch64 configuration
#

SOC_FAMILY=sunxi
SOC_ARCH=arm64

BOOT_DIR=/boot

DEBIAN_RELEASE_ARCH=arm64
KERNEL_ARCH=${SOC_ARCH}
LINUX_PLATFORM="aarch64-linux-gnu"

CROSS_COMPILE=${CROSS_COMPILE:="${TOOLCHAINDIR}/7.2-2017.11/aarch64-linux-gnu/gcc-linaro-7.2.1-2017.11-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-"}
QEMU_BINARY="/usr/bin/qemu-aarch64-static"

FIRMWARE_URL="https://github.com/apritzel/arm-trusted-firmware.git"
FIRMWARE_BRANCH=allwinner
FIRMWARE_NAME=apritzel-atf

KERNEL_BUILD_CONFIG=defconfig
KERNEL_BUILD_USER_CONFIG="linux-mainline-sunxi64.config"

KERNEL_USE_MKIMAGE=yes
# Use compressed (gzip) or uncompressed (none) kernel image for ARM64
KERNEL_MKIMAGE_COMPRESS=none
KERNEL_MKIMAGE_LOADADDR=0x40080000
# Can use compressed (Image.gz) or uncompressed (Image) source file
KERNEL_IMAGE_SOURCE=Image
KERNEL_IMAGE_TARGET=linux.uImage

QT5_OPENGL_OPTION=-no-opengl

APT_EXTRA_PACKAGES=
