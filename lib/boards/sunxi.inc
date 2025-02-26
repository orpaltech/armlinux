source "${BASH_SOURCE%/*}/sunxi-common.inc"

#
# sunXi armhf configuration
#
SOC_ARCH=arm

DEBIAN_RELEASE_ARCH=armhf
KERNEL_ARCH="${SOC_ARCH}"
UBOOT_ARCH="${SOC_ARCH}"
LINUX_PLATFORM="arm-linux-gnueabihf"

# Meson build tool parameters
MESON_CPU_FAMILY="arm"
MESON_CPU="armv7hl"

# Required for building openssl
OPENSSL_PLATFORM="linux-armv4 -march=armv7-a"

# You can directly specify tolchain paths
#UBOOT_CROSS_COMPILE=  
#KERNEL_CROSS_COMPILE=
#CROSS_COMPILE=

QEMU_BINARY="/usr/bin/qemu-arm-static"

KERNEL_BUILD_CONFIG="sunxi_defconfig"
KERNEL_BUILD_FAMILY_CONFIG="linux-sunxi.config"

# must be yes for arm 32bit
KERNEL_IMAGE_COMPRESSED=yes

# busybox configs are stored in ${CONFIGDIR}/busybox/${CONFIG}/${BUSYBOX_VERSION}/ directiory
BUSYBOX_BUILD_CONFIG="busybox-${LINUX_PLATFORM}.config"
