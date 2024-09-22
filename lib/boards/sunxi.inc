#
# Common sunXi armhf configuration
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

# You can directly specify tolchain paths
#UBOOT_CROSS_COMPILE=  
#KERNEL_CROSS_COMPILE=
#CROSS_COMPILE=

QEMU_BINARY="/usr/bin/qemu-arm-static"

KERNEL_BUILD_CONFIG="sunxi_defconfig"
KERNEL_BUILD_FAMILY_CONFIG="linux-sunxi.config"

KERNEL_OVERLAY_DIR="allwinner/overlays"

# On sunxi platforms BOOTLOADER must be "uboot" only
BOOTLOAD_OPTIONS="uboot"
BOOTLOADER="uboot"

# U-boot booting script variables
BOOTSCR_LOAD_ADDR=0x43000000
#BOOTSCR_RAMDISK_ADDR=0x48000000
# use to load device tree at the specified address (leave blank for auto)
BOOTSCR_FDT_ADDR=0x46000000
# uncomment line below to at the specified address (leave blank for auto)
BOOTSCR_KERNEL_ADDR=

# must be yes for arm 32bit
KERNEL_IMAGE_COMPRESSED=yes

KERNEL_MKIMAGE_WRAP=no
# Use compressed (gzip) or uncompressed (none) kernel image
KERNEL_MKIMAGE_COMPRESS=none
KERNEL_MKIMAGE_LOADADDR=0x47000000

# FELBOOT_KERNEL_ADDR=0x42000000
# FELBOOT_RAMDISK_ADDR=0x43300000
# FELBOOT_FDT_ADDR=0x43000000

# The option should be overriden if you want GPU support in QT5
QT_OPENGL_OPTION="-no-opengl"

# No wireless support by default. Update this value in a board config file
SUPPORT_WLAN=no

ENABLE_MESA=yes
APT_REMOVE_PACKAGES="libwayland-dev,libgbm-dev"
# sunxi-specific clean options
CLEAN_OPTIONS="${CLEAN_OPTIONS} mesa-lima"
