#
# Common sunxi configuration
#

SOC_FAMILY=sunxi
SOC_ARCH=arm

BOOT_DIR="/boot"

DEBIAN_RELEASE_ARCH=armhf
KERNEL_ARCH="${SOC_ARCH}"
LINUX_PLATFORM="arm-linux-gnueabihf"

CROSS_COMPILE="${TOOLCHAINDIR}/${DEFAULT_TOOLCHAIN_ARMHF}"
QEMU_BINARY="/usr/bin/qemu-arm-static"

KERNEL_BUILD_CONFIG="sunxi_defconfig"
KERNEL_BUILD_USER_CONFIG="linux-mainline-sunxi.config"

KERNEL_IMAGE_SOURCE=zImage
KERNEL_IMAGE_TARGET=linuz.img

FELBOOT_KERNEL_ADDR=0x42000000
FELBOOT_RAMDISK_ADDR=0x43300000
FELBOOT_FDT_ADDR=0x43000000

# The option should be overriden if you want GPU support in QT5
QT5_OPENGL_OPTION="-no-opengl"

# Install packages required for QT5 "eglfs_kms" integration
APT_BOARD_PACKAGES="libgbm-dev,libgles2-mesa-dev,weston"

#
# Custom EDID binary for DRM
#
DRM_USE_FIRMWARE_EDID=no
DRM_EDID_BINARY="edid/1280x1024.bin"
DRM_CONNECTOR="HDMI-A-1"
DRM_VIDEO_MODE="1280x1024-24@60"
