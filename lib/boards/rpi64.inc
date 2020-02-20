SOC_ARCH=arm64
SOC_FAMILY="rpi"
SOC_GPU="vc4"
OVERLAY_PREFIX="bcm2835"

DEBIAN_RELEASE_ARCH=arm64
KERNEL_ARCH="${SOC_ARCH}"
UBOOT_ARCH="${SOC_ARCH}"
LINUX_PLATFORM="aarch64-linux-gnu"

# Meson build tool parameters
MESON_CPU_FAMILY="aarch64"
MESON_CPU="armv8-a"

BOOT_DIR="/boot/firmware"

FIRMWARE_URL="https://github.com/raspberrypi/firmware.git"
FIRMWARE_BRANCH="stable"
FIRMWARE_NAME="raspberrypi"

# you can directly specify tolchain paths
# UBOOT_CROSS_COMPILE=  
# KERNEL_CROSS_COMPILE=                                           
# CROSS_COMPILE= 

KERNEL_OVERLAY_DIR="broadcom/overlays"

QEMU_BINARY="/usr/bin/qemu-aarch64-static"

BOOTSCR_LOAD_ADDR=0x2000000
BOOTSCR_FDT_ADDR=0x2600000

KERNEL_MKIMAGE_WRAP="yes"
# Use compressed (gzip) or uncompressed (none) kernel image for ARM64
KERNEL_MKIMAGE_COMPRESS="none"
KERNEL_MKIMAGE_LOADADDR="0x00080000"
# Can be compressed source (Image.gz) or uncompressed (Image)
KERNEL_IMAGE_SOURCE="Image"
KERNEL_IMAGE_TARGET="linux.uImage"

# Custom EDID binary for DRM
DRM_USE_FIRMWARE_EDID="yes"
DRM_EDID_BINARY="edid/640x480.bin"
DRM_CONNECTOR="HDMI-A-1"
DRM_VIDEO_MODE="640x480-24@60"

# The option should be overriden to change GPU support in QT5
QT5_OPENGL_OPTION="-opengl es2"

# Extra debian packages to be installed for RaspberryPi
APT_BOARD_PACKAGES="rng-tools fbset"

# All RaspberryPi has the built-in Wi-Fi adapter
SUPPORT_WLAN="yes"

# Raspberry-specific clean options
CLEAN_OPTIONS="${CLEAN_OPTIONS} mesa-vc4"

# Userland is broken on arm64 platform
ENABLE_RPI_USERLAND=no
