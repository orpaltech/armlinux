#
# Build and Setup Kernel (RPi 2/3 script)
#

# Fail early: Is firmware ready?
if [ ! -d "$FIRMWARE_DIR" ] ; then
  echo "error: firmware directory not specified or not found!"
  exit 1
fi

# Copy firmware binaries
cp ${FIRMWARE_DIR}/boot/bootcode.bin ${BOOT_DIR}/bootcode.bin
cp ${FIRMWARE_DIR}/boot/fixup_cd.dat ${BOOT_DIR}/fixup_cd.dat
cp ${FIRMWARE_DIR}/boot/fixup.dat ${BOOT_DIR}/fixup.dat
cp ${FIRMWARE_DIR}/boot/fixup_x.dat ${BOOT_DIR}/fixup_x.dat
cp ${FIRMWARE_DIR}/boot/start_cd.elf ${BOOT_DIR}/start_cd.elf
cp ${FIRMWARE_DIR}/boot/start.elf ${BOOT_DIR}/start.elf
cp ${FIRMWARE_DIR}/boot/start_x.elf ${BOOT_DIR}/start_x.elf


# Add serial console support
if [ "$ENABLE_CONSOLE" = yes ] ; then
  CMDLINE="console=ttyAMA0,115200 kgdboc=ttyAMA0,115200 ${CMDLINE}"
fi

# Setup firmware boot cmdline
CMDLINE="dwc_otg.lpm_enable=0 root=/dev/mmcblk0p2 rootfstype=ext4 rootflags=commit=100,data=writeback elevator=deadline cma=256M@512M ${CMDLINE}"

# Install firmware boot cmdline
echo "${CMDLINE}" > "${BOOT_DIR}/cmdline.txt"

# Install firmware config file
install_readonly "${FILES_DIR}/boot/config.txt" "${BOOT_DIR}/config.txt"
