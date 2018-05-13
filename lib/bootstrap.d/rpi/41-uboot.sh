#
# Bootloader configuration
#

BOOT_SCR_CMD="${BOOT_DIR}/uboot.mkimage"
BOOTENV_FILE="${BOOT_DIR}/bootEnv.txt"

install_readonly "${UBOOTSRC_DIR}/u-boot.bin" "${BOOT_DIR}/u-boot.bin"


# Install and setup U-Boot command file
install_readonly "${FILES_DIR}/boot/uboot.mkimage" $BOOT_SCR_CMD

if [ "${KERNEL_ARCH}" = arm64 ] ; then
  [[ "${KERNEL_USE_MKIMAGE}" = yes ]] && BOOTCMD="bootm" || BOOTCMD="booti"
else
  BOOTCMD="bootz"
fi
printf "${BOOTCMD} \${kernel_addr_r} - \${fdt_addr}" >> $BOOT_SCR_CMD

BOOTARGS_ENV="setenv bootargs \"earlyprintk \${extraargs} ${CMDLINE}\""
sed -i "/setenv bootargs .*/c ${BOOTARGS_ENV}" $BOOT_SCR_CMD

DTB_FILE_BASENAME=$(basename $DTB_FILE)
sed -i "s/^\(setenv dtb_file \).*/\1${DTB_FILE_BASENAME}/" $BOOT_SCR_CMD

sed -i "s/^\(setenv kernel_file \).*/\1${KERNEL_IMAGE_TARGET}/" $BOOT_SCR_CMD

# Remove all leading blank lines
sed -i "/./,\$!d" $BOOT_SCR_CMD

# Generate U-Boot bootloader image
# http://www.denx.de/wiki/view/DULG/UBootScripts
# http://www.denx.de/wiki/view/DULG/UBootEnvVariables
${UBOOTSRC_DIR}/tools/mkimage -A "${KERNEL_ARCH}" -O linux -T script -C none -a 0x00000000 -e 0x00000000 -n "RPi${RPI_MODEL}" -d "${BOOT_SCR_CMD}" "${BOOT_DIR}/boot.scr"

# The raspberry firmware blobs will boot u-boot
printf "\n# boot u-boot kernel\nkernel=u-boot.bin\n" >> "${BOOT_DIR}/config.txt"


if [ "$KERNEL_ARCH" = "arm64" ] ; then
  # See:
  # https://kernelnomicon.org/?p=682
  # https://www.raspberrypi.org/forums/viewtopic.php?f=72&t=137963
  printf "\n# run in 64bit mode\narm_control=0x200\n" >> "${BOOT_DIR}/config.txt"
fi

printf "\n# enable serial console\nenable_uart=1\n" >> "${BOOT_DIR}/config.txt"

# The default bootEnv.txt
printf "# user provided boot enviroment \nextraargs=\noverlay_prefix=${OVERLAY_PREFIX}\noverlays=\n" >> $BOOTENV_FILE
