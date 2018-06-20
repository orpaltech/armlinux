SOC_FAMILY=rpi
SOC_GPU=vc4
OVERLAY_PREFIX=bcm2835

BOOT_DIR=/boot/firmware

FIRMWARE_URL="https://github.com/raspberrypi/firmware"
FIRMWARE_BRANCH=master
FIRMWARE_NAME=raspberrypi

KERNEL_REPO_TAG="v4.18-rc1"
# UBOOT_REPO_TAG="v2018.01"

QT5_OPENGL_OPTION="-opengl es2"

APT_EXTRA_PACKAGES="rng-tools"
