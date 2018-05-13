#
# Initial ramdisk creation
#

INITRD_IMAGE_FILE="${BOOT_DIR}/initrd.img-${KERNEL_VERSION}"
FELBOOT_BOOTSCR_SRC="${FILES_DIR}/boot/uboot-fel.mkimage"

install_exec "${FILES_DIR}/boot/mass_storage" "${ETC_DIR}/initramfs-tools/scripts/init-premount/"

chroot_exec update-initramfs -c -k ${KERNEL_VERSION}

${UBOOTSRC_DIR}/tools/mkimage -A "${KERNEL_ARCH}" -O linux -T ramdisk -C none -n uInitrd -d "${INITRD_IMAGE_FILE}" "${BOOT_DIR}/uInitrd"

sed -i "s/^\(setenv kernel_addr \).*/\1${FELBOOT_KERNEL_ADDR}/" ${FELBOOT_BOOTSCR_SRC}
sed -i "s/^\(setenv ramdisk_addr \).*/\1${FELBOOT_RANDISK_ADDR}/" ${FELBOOT_BOOTSCR_SRC}
sed -i "s/^\(setenv fdt_addr \).*/\1${FELBOOT_FDT_ADDR}/" ${FELBOOT_BOOTSCR_SRC}

${UBOOTSRC_DIR}/tools/mkimage -A "${KERNEL_ARCH}" -O linux -T script -C none -a 0x00000000 -e 0x00000000 -d "${FELBOOT_BOOTSCR_SRC}" "${BOOT_DIR}/boot-fel.scr"
