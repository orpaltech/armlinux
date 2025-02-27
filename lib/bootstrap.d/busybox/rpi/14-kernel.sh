#
# Setup Kernel (raspberrypi)
#

# Fail early: Is firmware ready?
if [ ! -d "${FIRMWARE_DIR}" ] ; then
  echo "error: firmware directory was not specified or not found!"
  exit 1
fi

echo "Copy firmware binaries"
cp ${FIRMWARE_DIR}/${FIRMWARE_NAME}/boot/bootcode.bin	${BOOT_DIR}/
cp ${FIRMWARE_DIR}/${FIRMWARE_NAME}/boot/fixup*.dat	${BOOT_DIR}/
cp ${FIRMWARE_DIR}/${FIRMWARE_NAME}/boot/start*.elf	${BOOT_DIR}/


echo "Prepare cmdline.txt & config.txt"
# Setup firmware boot cmdline
CMDLINE="console=tty1 8250.nr_uarts=1 cma=256M dwc_otg.lpm_enable=0 ${CMDLINE}"

if [ "${BOOTLOADER}" = uboot ] ; then
  KERNEL_BOOT_ARGS="root=ROOTPART ${KERNEL_BOOT_ARGS}"
else
  CMDLINE="root=ROOTPART ${CMDLINE}"
fi

# Add serial console support
if [ "${ENABLE_CONSOLE}" = yes ] ; then
  CMDLINE="console=ttyS0,115200 ${CMDLINE}"
fi

# Install firmware boot cmdline
echo "${CMDLINE}" > ${BOOT_DIR}/cmdline.txt

# Install firmware config file
install_readonly "${FILES_DIR}/boot/config.txt"	${BOOT_DIR}/
