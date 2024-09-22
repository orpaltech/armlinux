#
# Default sunXi aarch64 configuration
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
FIRMWARE_ATF_TAG="v2.10.0"
FIRMWARE_ATF_NAME="mainline-atf"

FIRMWARE_SCP_URL="https://github.com/crust-firmware/crust.git"
FIRMWARE_SCP_BRANCH="master"
FIRMWARE_SCP_NAME="scp-crust"

KERNEL_BUILD_CONFIG="defconfig"
KERNEL_BUILD_FAMILY_CONFIG="linux-sunxi64.config"

KERNEL_OVERLAY_DIR="allwinner/overlays"


# On sunxi platforms BOOTLOADER must always be "uboot"
BOOTLOAD_OPTIONS="uboot"
BOOTLOADER=uboot

# U-boot booting script variables
BOOTSCR_LOAD_ADDR=0x43000000
#BOOTSCR_RAMDISK_ADDR=0x48000000
# use to load device tree at the specified address (leave blank for auto)
BOOTSCR_FDT_ADDR=0x46000000
# uncomment line below to at the specified address (leave blank for auto)
BOOTSCR_KERNEL_ADDR=

KERNEL_MKIMAGE_WRAP=no
# Use compressed (gzip) or uncompressed (none) kernel image
KERNEL_MKIMAGE_COMPRESS=none
KERNEL_MKIMAGE_LOADADDR=0x47000000

# can be: "yes" - compressed (Image.gz, etc), otherwise uncompressed (Image)
KERNEL_IMAGE_COMPRESSED=no

# No wireless by default, boards must override
SUPPORT_WLAN="no"

# The option should be overriden if you want GPU support in QT5
QT_OPENGL_OPTION="-no-opengl"

ENABLE_MESA=yes
APT_REMOVE_PACKAGES="libwayland-dev,libgbm-dev"
# sunxi aarch64-specific clean options
CLEAN_OPTIONS="${CLEAN_OPTIONS} mesa-lima"
