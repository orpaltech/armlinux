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

FIRMWARE_URL="git://github.com/raspberrypi/firmware.git"
FIRMWARE_BRANCH="next"
FIRMWARE_NAME="raspberrypi"

# you can directly specify tolchain paths
# UBOOT_CROSS_COMPILE=  
# KERNEL_CROSS_COMPILE=                                           
# CROSS_COMPILE= 

QEMU_BINARY="/usr/bin/qemu-aarch64-static"

BOOTSCR_LOAD_ADDR=0x1FFEBC00
# Load our device tree below CMA range
BOOTSCR_FDT_ADDR=0x1FFEFC00

# The option should be overriden to change GPU support in QT5
QT5_OPENGL_OPTION="-opengl es2"

# Extra debian packages to be installed for RaspberryPi
APT_BOARD_PACKAGES="rng-tools"

# All RaspberryPi has the built-in Wi-Fi adapter
SUPPORT_WLAN="yes"

# Raspberry-specific clean options
CLEAN_OPTIONS="${CLEAN_OPTIONS} mesa-vc4"
