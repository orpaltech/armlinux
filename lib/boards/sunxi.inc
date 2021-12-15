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

# you can directly specify tolchains
# UBOOT_CROSS_COMPILE=${TOOLCHAINDIR}/armv7-eabihf--glibc--stable-2020.08-1/bin/arm-linux-
# KERNEL_CROSS_COMPILE=${TOOLCHAINDIR}/armv7-eabihf--glibc--stable-2020.08-1/bin/arm-linux-                             
# CROSS_COMPILE=${TOOLCHAINDIR}/armv7-eabihf--glibc--stable-2020.08-1/bin/arm-linux-

QEMU_BINARY="/usr/bin/qemu-arm-static"

KERNEL_BUILD_CONFIG="sunxi_defconfig"
KERNEL_BUILD_FAMILY_CONFIG="linux-mainline-sunxi.config"

KERNEL_OVERLAY_DIR=overlays

# On sunxi platforms ENABLE_UBOOT must always be "yes"
ENABLE_UBOOT="yes"
BOOTSCR_LOAD_ADDR=0x43000000 
BOOTSCR_FDT_ADDR=0x46000000 
#BOOTSCR_KERNEL_ADDR=0x47000000 
#BOOTSCR_RAMDISK_ADDR=0x48000000

KERNEL_MKIMAGE_WRAP=no
# Use compressed (gzip) or uncompressed (none) kernel image
KERNEL_MKIMAGE_COMPRESS=none
KERNEL_MKIMAGE_LOADADDR=0x00000000
# Use compressed (Image.gz) or uncompressed (Image) source file
#KERNEL_IMAGE_SOURCE=Image
KERNEL_IMAGE_SOURCE=zImage
# Use wrapped (linux.uImage) or normal (linuz.img) target file
#KERNEL_IMAGE_TARGET="linux.uImage"
KERNEL_IMAGE_TARGET="linuz.img"

# FELBOOT_KERNEL_ADDR=0x42000000
# FELBOOT_RAMDISK_ADDR=0x43300000
# FELBOOT_FDT_ADDR=0x43000000

# The option should be overriden if you want GPU support in QT5
QT5_OPENGL_OPTION="-no-opengl"

#
# Custom EDID binary for DRM
#
DRM_USE_FIRMWARE_EDID=no
DRM_EDID_BINARY="edid/1280x1024.bin"
DRM_CONNECTOR="HDMI-A-1"
DRM_VIDEO_MODE="1280x1024-24@60"

# No wireless support by default, board specific
SUPPORT_WLAN="no"

# sunxi-specific clean options
CLEAN_OPTIONS="${CLEAN_OPTIONS} mesa-lima"
