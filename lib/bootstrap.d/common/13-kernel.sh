#
# Build and Setup Kernel (Main script)
#

export ARCH="${KERNEL_ARCH}"
export CROSS_COMPILE="${CROSS_COMPILE}"

# Install kernel sources (optional)
if [ "${KERNEL_INSTALL_SOURCE}" = yes ] ; then
  KERNEL_DIR="${R}/usr/src/linux"
  mkdir -p $KERNEL_DIR
  rsync -a --exclude=".git" "${KERNEL_SOURCE_DIR}/" "${KERNEL_DIR}/"
else
  KERNEL_DIR=$KERNEL_SOURCE_DIR
fi

# Install kernel modules
make -C "${KERNEL_DIR}" INSTALL_MOD_STRIP=1 INSTALL_MOD_PATH="${R}" modules_install

# Preserve headers from being updated by kernel
if [ -f $USR_DIR/include/linux/i2c-dev.h.kernel ] ; then
  mv $USR_DIR/include/linux/i2c-dev.h	$USR_DIR/include/linux/i2c-dev.h.temp
fi

# Install kernel headers
if [ "${KERNEL_INSTALL_HEADERS}" = yes ] ; then
  make -C "${KERNEL_DIR}" INSTALL_HDR_PATH="${USR_DIR}" headers_install
fi

# Restore headers
if [ -f $USR_DIR/include/linux/i2c-dev.h.temp ] ; then
  mv $USR_DIR/include/linux/i2c-dev.h		$USR_DIR/include/linux/i2c-dev.h.kernel
  mv $USR_DIR/include/linux/i2c-dev.h.temp	$USR_DIR/include/linux/i2c-dev.h
fi

# Prepare boot (firmware) directory
mkdir -p $BOOT_DIR

# Copy kernel configuration file to the boot directory
install_readonly "${KERNEL_DIR}/.config" "${R}/boot/config-${KERNEL_VERSION}"


# Copy device tree binaries
install_readonly "${KERNEL_DIR}/arch/${KERNEL_ARCH}/boot/dts/${DTB_FILE}" "${BOOT_DIR}/"


if [ "${KERNEL_ARCH}" = arm64 ] && [ "${KERNEL_MKIMAGE_WRAP}" = yes ] ; then
  # The default Linux kernel 'make' target generates an uncompressed 'Image' and a gzip-compresesd 'Image.gz'.
  # If we use latter and wrap it into an uImage then u-boot can decompress gzip images.
  # See https://www.kernel.org/doc/Documentation/arm64/booting.txt
  ${UBOOT_SOURCE_DIR}/tools/mkimage -A $KERNEL_ARCH -O linux -T kernel \
	-C $KERNEL_MKIMAGE_COMPRESS \
	-a $KERNEL_MKIMAGE_LOADADDR -e $KERNEL_MKIMAGE_LOADADDR \
	-d "${KERNEL_DIR}/arch/${KERNEL_ARCH}/boot/${KERNEL_IMAGE_SOURCE}" "${BOOT_DIR}/${KERNEL_IMAGE_TARGET}"
else
  # The default Linux kernel 'make' target generates a self-extracting 'zImage'.
  # Since a zImage file is self-extracting (i.e. needs no external decompressors), the u-boot wrapper
  # would indicate that this kernel is "uncompressed" even though it actually is.
  install_readonly "${KERNEL_DIR}/arch/${KERNEL_ARCH}/boot/${KERNEL_IMAGE_SOURCE}" "${BOOT_DIR}/${KERNEL_IMAGE_TARGET}"
fi

if [ "${KERNEL_DIR}" != "${KERNEL_SOURCE_DIR}" ] ; then
  # Clean the kernel sources in the chroot
  make -C "${KERNEL_DIR}" mrproper
fi

# Setup kernel boot environment
CMDLINE="consoleblank=0 loglevel=7 rootfstype=ext4 rootwait panic=10 rootflags=commit=60,data=writeback elevator=deadline init=/bin/systemd"

# Remove IPv6 networking support
if [ "${ENABLE_IPV6}" != yes ] ; then
  CMDLINE="ipv6.disable=1 ${CMDLINE}"
fi

# Automatically assign predictable network interface names
if [ "${ENABLE_IFNAMES}" = yes ] ; then
  CMDLINE="net.ifnames=1 ${CMDLINE}"
else
  CMDLINE="net.ifnames=0 ${CMDLINE}"
fi

# Install and setup fstab
install_readonly "${FILES_DIR}/mount/fstab" "${ETC_DIR}/fstab"

# Install sysctl.d configuration files
install_readonly "${FILES_DIR}/sysctl.d/81-vm.conf" "${ETC_DIR}/sysctl.d/81-vm.conf"

if [ ! -z "${KERNEL_MODULES}" ] ; then
  tr ' ' '\n' <<< "${KERNEL_MODULES}" > "${ETC_DIR}/modules"
fi
