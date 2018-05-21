#
# Bootloader configuration
#

BOOT_SCR_CMD="${BOOT_DIR}/uboot.mkimage"
BOOTENV_FILE="${BOOT_DIR}/bootEnv.txt"

# This is optional
install_readonly "${UBOOT_SOURCE_DIR}/u-boot-sunxi-with-spl.bin" "${BOOT_DIR}/u-boot-sunxi-with-spl.bin"

# Install and setup U-Boot command file
install_readonly "${FILES_DIR}/boot/uboot.mkimage" $BOOT_SCR_CMD

if [ "${KERNEL_ARCH}" = arm64 ] ; then
  [[ "${KERNEL_USE_MKIMAGE}" = yes ]] && BOOTCMD="bootm" || BOOTCMD="booti"
else
  BOOTCMD="bootz"
fi
printf "${BOOTCMD} \${kernel_addr_r} - \${fdt_addr}" >> $BOOT_SCR_CMD

BOOTARGS_ENV="setenv bootargs \"${CMDLINE} hdmi.audio=EDID:0 disp.screen0_output_mode=\${video_mode} \${extraargs}\""
sed -i "/setenv bootargs .*/c ${BOOTARGS_ENV}" $BOOT_SCR_CMD


DTB_FILE_BASENAME=$(basename $DTB_FILE)
sed -i "s/^\(setenv dtb_file \).*/\1${DTB_FILE_BASENAME}/" $BOOT_SCR_CMD

sed -i "s/^\(setenv kernel_file \).*/\1${KERNEL_IMAGE_TARGET}/" $BOOT_SCR_CMD

# Remove all leading blank lines
sed -i "/./,\$!d" $BOOT_SCR_CMD

# Generate U-Boot bootloader image
# http://www.denx.de/wiki/view/DULG/UBootScripts
# http://www.denx.de/wiki/view/DULG/UBootEnvVariables
${UBOOT_SOURCE_DIR}/tools/mkimage -A "${KERNEL_ARCH}" -O linux -T script -C none -a 0x00000000 -e 0x00000000 \
	-d "${BOOT_SCR_CMD}" "${BOOT_DIR}/boot.scr"

# The default bootEnv.txt
printf "# user provided boot enviroment \nextraargs=${EXTRAARGS}\noverlay_prefix=${OVERLAY_PREFIX}\noverlays=${DEFAULT_OVERLAYS}\n" >> ${BOOTENV_FILE}
