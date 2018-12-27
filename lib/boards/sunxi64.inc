#
# Default sunxi aarch64 configuration
#
SOC_FAMILY=sunxi
SOC_ARCH=arm64

BOOT_DIR="/boot"

DEBIAN_RELEASE_ARCH=arm64
KERNEL_ARCH="${SOC_ARCH}"
LINUX_PLATFORM="aarch64-linux-gnu"

CROSS_COMPILE="${TOOLCHAINDIR}/${DEFAULT_TOOLCHAIN_AARCH64}"
QEMU_BINARY="/usr/bin/qemu-aarch64-static"

FIRMWARE_URL="https://github.com/apritzel/arm-trusted-firmware.git"
FIRMWARE_BRANCH="allwinner"
FIRMWARE_NAME="apritzel-atf"

KERNEL_BUILD_CONFIG="defconfig"
KERNEL_BUILD_USER_CONFIG="linux-mainline-sunxi64.config"

KERNEL_OVERLAY_DIR="allwinner/overlays"

KERNEL_MKIMAGE_WRAP="yes"
# Use compressed (gzip) or uncompressed (none) kernel image for ARM64
KERNEL_MKIMAGE_COMPRESS="none"
KERNEL_MKIMAGE_LOADADDR=0x40080000
# Can use compressed (Image.gz) or uncompressed (Image) source file
KERNEL_IMAGE_SOURCE="Image"
KERNEL_IMAGE_TARGET="linux.uImage"

# The option should be overriden if you want GPU support in QT5
QT5_OPENGL_OPTION="-no-opengl"

# sunxi aarch64-specific clean options
CLEAN_OPTIONS="${CLEAN_OPTIONS}"
