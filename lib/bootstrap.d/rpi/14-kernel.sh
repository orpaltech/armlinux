#
# Build and Setup Kernel (RPi 2/3/4 script)
#

# Fail early: Is firmware ready?
if [ ! -d "$FIRMWARE_DIR" ] ; then
  echo "error: firmware directory not specified or not found!"
  exit 1
fi

# Copy firmware binaries
cp ${FIRMWARE_DIR}/${FIRMWARE_NAME}/boot/bootcode.bin	${BOOT_DIR}/
cp ${FIRMWARE_DIR}/${FIRMWARE_NAME}/boot/fixup*.dat	${BOOT_DIR}/
cp ${FIRMWARE_DIR}/${FIRMWARE_NAME}/boot/start*.elf	${BOOT_DIR}/


# Setup firmware boot cmdline
CMDLINE="console=tty1 cma=256M@256M dwc_otg.lpm_enable=0 elevator=deadline root=ROOTPARTUUID ${CMDLINE}"
KERNEL_BOOT_ARGS="root=ROOTPARTUUID ${KERNEL_BOOT_ARGS}"

# Add serial console support
if [ "$ENABLE_CONSOLE" = yes ] ; then
  CMDLINE="console=ttyS0,115200 ${CMDLINE}"
fi

# Install firmware boot cmdline
echo "${CMDLINE}" > "${BOOT_DIR}/cmdline.txt"

# Install firmware config file
install_readonly "${FILES_DIR}/boot/config.txt" "${BOOT_DIR}/config.txt"
