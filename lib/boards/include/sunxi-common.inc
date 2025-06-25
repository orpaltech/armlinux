#
# Common sunXi configuration
#
SOC_FAMILY=sunxi

TARGET_BOOT_DIR="/boot"

# You can directly specify tolchain paths
#UBOOT_CROSS_COMPILE=  
#KERNEL_CROSS_COMPILE=
#CROSS_COMPILE=

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


KERNEL_MKIMAGE_WRAP=no
KERNEL_MKIMAGE_LEGACY_FORMAT=yes
# Use compressed (gzip) or uncompressed (none) kernel image
KERNEL_MKIMAGE_COMPRESS=none
KERNEL_MKIMAGE_LOADADDR=0x47000000

# FELBOOT_KERNEL_ADDR=0x42000000
# FELBOOT_RAMDISK_ADDR=0x43300000
# FELBOOT_FDT_ADDR=0x43000000

# The option shall be overriden if you want OpenGL support
QT_OPENGL_OPTION="-no-opengl"
# The device config may be overriden if needed
QT_DEVICE_CONFIG=linux-arm-generic-g++

# No wireless support by default. Update this value in a board config file
SUPPORT_WLAN=no
