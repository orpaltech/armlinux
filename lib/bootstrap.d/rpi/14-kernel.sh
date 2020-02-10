#
# Build and Setup Kernel (RPi 2/3 script)
#

# Fail early: Is firmware ready?
if [ ! -d "$FIRMWARE_DIR" ] ; then
  echo "error: firmware directory not specified or not found!"
  exit 1
fi

# Copy firmware binaries
cp ${FIRMWARE_DIR}/boot/bootcode.bin	${BOOT_DIR}/
cp ${FIRMWARE_DIR}/boot/fixup*.dat	${BOOT_DIR}/
cp ${FIRMWARE_DIR}/boot/start*.elf	${BOOT_DIR}/


# Setup firmware boot cmdline
CMDLINE="root=/dev/mmcblk0p2 console=tty1 cma=128M@256M ${CMDLINE}"

# Add serial console support
if [ "$ENABLE_CONSOLE" = yes ] ; then
  CMDLINE="console=ttyS0,115200 ${CMDLINE}"
fi

# Install firmware boot cmdline
echo "${CMDLINE}" > "${BOOT_DIR}/cmdline.txt"

# Install firmware config file
install_readonly "${FILES_DIR}/boot/config.txt" "${BOOT_DIR}/config.txt"
