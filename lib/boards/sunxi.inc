#
# Common sunxi configuration
#

SOC_FAMILY=sunxi
SOC_ARCH=arm

BOOT_DIR="/boot"

DEBIAN_RELEASE_ARCH=armhf
KERNEL_ARCH="${SOC_ARCH}"
UBOOT_ARCH="${SOC_ARCH}"
LINUX_PLATFORM="arm-linux-gnueabihf"

# Meson build tool parameters
MESON_CPU_FAMILY="arm"
MESON_CPU="armv7hl"

# you can directly specify tolchain paths
# UBOOT_CROSS_COMPILE=  
# KERNEL_CROSS_COMPILE=                                           
# CROSS_COMPILE= 

QEMU_BINARY="/usr/bin/qemu-arm-static"

KERNEL_BUILD_CONFIG="sunxi_defconfig"
KERNEL_BUILD_FAMILY_CONFIG="linux-mainline-sunxi.config"

KERNEL_OVERLAY_DIR="overlays"

KERNEL_MKIMAGE_WRAP="no"
# Use compressed (gzip) or uncompressed (none) kernel image
KERNEL_MKIMAGE_COMPRESS="none"
KERNEL_MKIMAGE_LOADADDR="0x40008000"
# Use compressed (Image.gz) or uncompressed (Image) source file
KERNEL_IMAGE_SOURCE="zImage"
# Use wrapped (linux.uImage) or normal (linuz.img) target file
KERNEL_IMAGE_TARGET="linuz.img"

# FELBOOT_KERNEL_ADDR=0x42000000
# FELBOOT_RAMDISK_ADDR=0x43300000
# FELBOOT_FDT_ADDR=0x43000000

# The option should be overriden if you want GPU support in QT5
QT5_OPENGL_OPTION="-no-opengl"

#
# Custom EDID binary for DRM
#
DRM_USE_FIRMWARE_EDID="no"
DRM_EDID_BINARY="edid/1280x1024.bin"
DRM_CONNECTOR="HDMI-A-1"
DRM_VIDEO_MODE="1280x1024-24@60"

# No wireless support by default, board specific
SUPPORT_WLAN="no"

# sunxi-specific clean options
CLEAN_OPTIONS="${CLEAN_OPTIONS} mesa-lima"
