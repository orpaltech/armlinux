source "${BASH_SOURCE%/*}/sunxi-common.inc"

#
# sunXi aarch64 configuration
#
SOC_ARCH=arm64

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
FIRMWARE_ATF_URL="git@github.com:ARM-software/arm-trusted-firmware.git"
# "https://github.com/ARM-software/arm-trusted-firmware.git"
FIRMWARE_ATF_BRANCH="master"
FIRMWARE_ATF_TAG="v2.10.0"
FIRMWARE_ATF_NAME="mainline-atf"

FIRMWARE_SCP_URL="git@github.com:crust-firmware/crust.git"
# "https://github.com/crust-firmware/crust.git"
FIRMWARE_SCP_BRANCH="master"
FIRMWARE_SCP_NAME="scp-crust"

KERNEL_BUILD_CONFIG="defconfig"
KERNEL_BUILD_FAMILY_CONFIG="linux-sunxi64.config"


# can be "yes" - compressed (Image.gz), or "no" - uncompressed (Image)
KERNEL_IMAGE_COMPRESSED=no
