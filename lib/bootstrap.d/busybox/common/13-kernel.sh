#
# Setup Kernel (Main script)
#

SOURCE_NAME=$(basename ${BASH_SOURCE[0]})

#
# ############ helper functions ##############
#


#
# ############ configure kernel ##############
#

# create required directories
mkdir -p ${BOOT_DIR}
mkdir -p ${ETC_DIR}/modules-load.d


export ARCH="${KERNEL_ARCH}"
export CROSS_COMPILE="${KERNEL_CROSS_COMPILE}"

# Install kernel sources (optional)
if [ "${KERNEL_INSTALL_SOURCE}" = yes ] ; then
  KERNEL_DIR="${USR_DIR}/src/linux"
  mkdir -p ${KERNEL_DIR}
  rsync -a --exclude=".git" "${KERNEL_SOURCE_DIR}/" "${KERNEL_DIR}/"
else
  KERNEL_DIR=${KERNEL_SOURCE_DIR}
fi

# Install kernel modules
make -C "${KERNEL_DIR}" INSTALL_MOD_STRIP=1 INSTALL_MOD_PATH="${R}" modules_install

# TODO: Install kernel image ??


# Install kernel headers (optional)
if [ "${KERNEL_INSTALL_HEADERS}" = yes ] ; then
  make -C "${KERNEL_DIR}" INSTALL_HDR_PATH="${USR_DIR}" headers_install
fi

# Prepare boot (firmware) directory

# Copy kernel configuration file to the boot directory
install_readonly ${KERNEL_DIR}/.config	${R}/boot/config-${KERNEL_VERSION}
# Copy device tree binaries
install_readonly ${KERNEL_DIR}/arch/${KERNEL_ARCH}/boot/dts/${DTB_FILE}	${BOOT_DIR}/
# Setup initramfs file
#install_readonly "${R}/boot/initrd.img-${KERNEL_VERSION}" "${BOOT_DIR}/initrd.img"


# The default Linux kernel 'make' target generates an uncompressed 'Image' and a gzip-compresesd 'Image.gz'.
# If we use latter and wrap it into an uImage then u-boot can decompress gzip images.
# See https://www.kernel.org/doc/Documentation/arm64/booting.txt
# Since a "zImage" file is self-extracting (i.e. needs no external decompressors), the u-boot wrapper
# would indicate that this kernel is "uncompressed" even though it actually is.

if [ "${KERNEL_MKIMAGE_WRAP}" = yes ] ; then
  if [ "${KERNEL_MKIMAGE_COMPRESS}" = none ] ; then
    KERNEL_IMAGE_TARGET="linux.uImage"
  else
    KERNEL_IMAGE_TARGET="linux.zImage"
  fi
else
  KERNEL_IMAGE_TARGET="linuz.img"
fi


if [ "${BOOTLOADER}" = uboot ] && [ "${KERNEL_MKIMAGE_WRAP}" = yes ] ; then

  if [ "${KERNEL_MKIMAGE_LEGACY_FORMAT}" = yes ] ; then
    ${UBOOT_SOURCE_DIR}/tools/mkimage \
        -A ${KERNEL_ARCH} -O linux -T kernel -C ${KERNEL_MKIMAGE_COMPRESS} -a ${KERNEL_MKIMAGE_LOADADDR} -e ${KERNEL_MKIMAGE_LOADADDR} \
        -d ${KERNEL_DIR}/arch/${KERNEL_ARCH}/boot/${KERNEL_IMAGE_FILE}  ${BOOT_DIR}/${KERNEL_IMAGE_TARGET}
  else
    ${UBOOT_SOURCE_DIR}/tools/mkimage -f auto -b ${KERNEL_DIR}/arch/${KERNEL_ARCH}/boot/dts/${DTB_FILE} \
        -A ${KERNEL_ARCH} -O linux -T kernel -C ${KERNEL_MKIMAGE_COMPRESS} -a ${KERNEL_MKIMAGE_LOADADDR} -e ${KERNEL_MKIMAGE_LOADADDR} \
        -d ${KERNEL_DIR}/arch/${KERNEL_ARCH}/boot/${KERNEL_IMAGE_FILE}  ${BOOT_DIR}/${KERNEL_IMAGE_TARGET}
  fi
else
  install_readonly "${KERNEL_DIR}/arch/${KERNEL_ARCH}/boot/${KERNEL_IMAGE_FILE}" "${BOOT_DIR}/${KERNEL_IMAGE_TARGET}"
fi


if [ "${KERNEL_DIR}" != "${KERNEL_SOURCE_DIR}" ] ; then
  # Clean the kernel sources in the chroot
  make -C "${KERNEL_DIR}" mrproper
fi

# Setup kernel boot environment
CMDLINE="${CMDLINE} consoleblank=0 loglevel=8 earlyprintk rootfstype=ext4 rootwait panic=10"

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

#if [ "$DRM_USE_FIRMWARE_EDID" = yes ] ; then
#  KERNEL_BOOT_ARGS="drm_kms_helper.edid_firmware=${DRM_CONNECTOR}:${DRM_EDID_BINARY} video=${DRM_CONNECTOR}:${DRM_VIDEO_MODE} ${KERNEL_BOOT_ARGS}"
#fi

if [ ! -z "${DRM_DEBUG}" ] ; then
  KERNEL_BOOT_ARGS="drm.debug=${DRM_DEBUG} ${KERNEL_BOOT_ARGS}"
fi

if [ ! -z "${DMESG_BUF_LEN}" ] ; then
  KERNEL_BOOT_ARGS="log_buf_len=${DMESG_BUF_LEN} ${KERNEL_BOOT_ARGS}"
fi

if [ ! -z "${BOOT_PRINTK_DELAY+x}" ] ; then
    if [[ $BOOT_PRINTK_DELAY -gt 0 ]] ; then
	KERNEL_BOOT_ARGS="boot_delay=${BOOT_PRINTK_DELAY} ${KERNEL_BOOT_ARGS}"
    fi
fi


# Install sysctl configuration files
install_readonly ${FILES_DIR}/sysctl/81-vm.conf	${ETC_DIR}/sysctl.d/


if [ -n "${KERNEL_MODULES}" ] ; then
    make_array ${KERNEL_MODULES}
    for kmod in "${temp_array[@]}" ; do
	echo "${kmod}" > ${ETC_DIR}/modules-load.d/kmod_${kmod}.conf
    done
fi
