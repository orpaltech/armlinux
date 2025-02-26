#
# Bootloader configuration
#

BOOT_SCR_CMD="${BOOT_DIR}/boot.scr-cmd"
BOOTENV_FILE="${BOOT_DIR}/bootEnv.txt"

# This is optional
install_readonly "${UBOOT_SOURCE_DIR}/u-boot-sunxi-with-spl.bin" "${BOOT_DIR}/u-boot-sunxi-with-spl.bin"

# Install U-Boot command file
install_readonly "${CONFIGDIR}/boot/sunxi/boot.scr-cmd" $BOOT_SCR_CMD

# detect which boot command must be used
if [ "${KERNEL_MKIMAGE_WRAP}" = yes ] ; then
  BOOTCMD="bootm"

  if [ "${KERNEL_MKIMAGE_LEGACY_FORMAT}" != yes ] ; then
    display_alert "Can't proceed with mkimage. TODO: investigation needed in order to support FTI imagges." "" "err"
    exit 1
  fi

else
  if [ "${KERNEL_ARCH}" = arm64 ] ; then
    BOOTCMD="booti"
  else
    BOOTCMD="bootz"
  fi
fi

echo "${BOOTCMD} \${kernel_addr_r} - \${fdt_addr_r}" >> $BOOT_SCR_CMD


BOOTARGS_ENV="setenv bootargs \"${CMDLINE} \${kernel_args}\""
sed -i "/setenv bootargs .*/c ${BOOTARGS_ENV}" $BOOT_SCR_CMD


DTB_FILE_BASENAME=$(basename $DTB_FILE)
sed -i "s/^\(setenv dtb_file \).*/\1${DTB_FILE_BASENAME}/" $BOOT_SCR_CMD
sed -i "s/^\(setenv kernel_file \).*/\1${KERNEL_IMAGE_TARGET}/" $BOOT_SCR_CMD

if [ ! -z "${BOOTSCR_LOAD_ADDR}" ] ; then
  sed -i "s/^\(setenv load_addr \).*/\1${BOOTSCR_LOAD_ADDR}/" $BOOT_SCR_CMD
fi
if [ ! -z "${BOOTSCR_FDT_ADDR}" ] ; then
  sed -i "s/^\(setenv fdt_addr_r \).*/\1${BOOTSCR_FDT_ADDR}/" $BOOT_SCR_CMD
fi

# Remove all leading blank lines
sed -i "/./,\$!d" $BOOT_SCR_CMD

# Generate U-Boot bootloader image
# http://www.denx.de/wiki/view/DULG/UBootScripts
# http://www.denx.de/wiki/view/DULG/UBootEnvVariables
${UBOOT_SOURCE_DIR}/tools/mkimage -A "${KERNEL_ARCH}" -O linux -T script -C none -a 0x00000000 -e 0x00000000 \
	-d "${BOOT_SCR_CMD}" "${BOOT_DIR}/boot.scr"

# The default bootEnv.txt
printf "# user provided boot environment \nkernel_args=${KERNEL_BOOT_ARGS}\noverlay_prefix=${OVERLAY_PREFIX}\noverlays=${DEFAULT_OVERLAYS}\n" >> $BOOTENV_FILE
