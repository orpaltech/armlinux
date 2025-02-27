#
# Bootloader configuration
#
BOOT_SCR_CMD="${BOOT_DIR}/boot.scr-cmd"
BOOTENV_FILE="${BOOT_DIR}/bootEnv.txt"
UBOOT_IMAGE="u-boot.bin"
DTB_FILE_NAME=$(basename $DTB_FILE)

if [ "${BOOTLOADER}" = uboot ] ; then
  install_readonly "${UBOOT_SOURCE_DIR}/u-boot.bin"	${BOOT_DIR}/

  # Install and setup U-Boot command file
  install_readonly "${CONFIGDIR}/boot/rpi/boot.scr-cmd"	$BOOT_SCR_CMD

  BOOTARGS_ENV="setenv bootargs \"\${kernel_args} ${CMDLINE}\""
  sed -i "/setenv bootargs .*/c ${BOOTARGS_ENV}"	$BOOT_SCR_CMD


  sed -i "s/^\(setenv kernel_file \).*/\1${KERNEL_IMAGE_TARGET}/" $BOOT_SCR_CMD

  if [ -z "${BOOTSCR_LOAD_ADDR}" ] ; then
    echo "error: must specify bootscr load address!"
    exit 1
  fi
  sed -i "s/^\(setenv load_addr \).*/\1${BOOTSCR_LOAD_ADDR}/" $BOOT_SCR_CMD

  if [ -n "${BOOTSCR_FDT_ADDR}" ] ; then
    sed -i "s/^\(setenv fdt_addr_r \).*/\1${BOOTSCR_FDT_ADDR}/" $BOOT_SCR_CMD
    sed -i "s/^\(setenv dtb_file \).*/\1${DTB_FILE_NAME}/" $BOOT_SCR_CMD
  fi

  if [ -n "${BOOTSCR_KERNEL_ADDR}" ] ; then
    sed -i "s/^\(setenv kernel_addr_r \).*/\1${BOOTSCR_KERNEL_ADDR}/" $BOOT_SCR_CMD
  fi

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

  if [ -n "${BOOTSCR_FDT_ADDR}" ] ; then
    printf "${BOOTCMD} \${kernel_addr_r} - \${fdt_addr_r}" >> $BOOT_SCR_CMD
  else
    printf "${BOOTCMD} \${kernel_addr_r} - \${fdt_addr}" >> $BOOT_SCR_CMD
  fi

  # Remove all leading blank lines
  sed -i "/./,\$!d" $BOOT_SCR_CMD

  # Generate U-Boot bootloader image
  # http://www.denx.de/wiki/view/DULG/UBootScripts
  # http://www.denx.de/wiki/view/DULG/UBootEnvVariables
  ${UBOOT_SOURCE_DIR}/tools/mkimage -A "${KERNEL_ARCH}" -O linux -T script -C none -a 0x00000000 -e 0x00000000 \
	-n "RPi${RPI_MODEL}" -d "${BOOT_SCR_CMD}" "${BOOT_DIR}/boot.scr"

  # The raspberry firmware blobs will boot u-boot
  sed -i "s/^\(kernel=\).*/\1${UBOOT_IMAGE}/" ${BOOT_DIR}/config.txt

  # The default bootEnv.txt
  printf "# user provided boot environment\nkernel_args=${KERNEL_BOOT_ARGS}\noverlay_prefix=${OVERLAY_PREFIX}\noverlays=\n" >> ${BOOTENV_FILE}

else
  # Native bootloader

  sed -i "s/^\(kernel=\).*/\1${KERNEL_IMAGE_TARGET}/"	${BOOT_DIR}/config.txt

fi

sed -i "s/^\(overlay_prefix=\).*/\1overlays\/${OVERLAY_PREFIX}-/" ${BOOT_DIR}/config.txt

sed -i "s/^\(device_tree=\).*/\1${DTB_FILE_NAME}/" ${BOOT_DIR}/config.txt

sed -i "s/^\(ramfsfile=\).*/\1initrd.img/" ${BOOT_DIR}/config.txt

if [ "${KERNEL_ARCH}" = arm64 ] ; then
  # See:
  # https://kernelnomicon.org/?p=682
  # https://www.raspberrypi.org/forums/viewtopic.php?f=72&t=137963
  printf "\n# run in 64bit mode\narm_control=0x200\narm_64bit=1\n" >> ${BOOT_DIR}/config.txt
fi

printf "\n# enable serial console\nenable_uart=1\nuart_2ndstage=1\n" >> ${BOOT_DIR}/config.txt
