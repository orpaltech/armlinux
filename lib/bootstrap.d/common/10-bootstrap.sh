#
# Debootstrap basic system
#

ROOTFS_PKG="rootfs-${DEBIAN_RELEASE}-${DEBIAN_RELEASE_ARCH}-${SOC_FAMILY}-${CONFIG}-${VERSION}"

mkdir -p ${BASEDIR}/debs

if [[ $CLEAN =~ (^|,)"rootfs"(,|$) ]] ; then
  rm -f "${BASEDIR}/debs/${ROOTFS_PKG}.tar.gz"
fi

if [ ! -f "${BASEDIR}/debs/${ROOTFS_PKG}.tar.gz" ] ; then

  VARIANT=""
  COMPONENTS="main,contrib"

  # Use non-free Debian packages if needed
  if [ "${DEBIAN_NONFREE}" = yes ] ; then
    COMPONENTS="${COMPONENTS},non-free"
  fi

  # Use minbase bootstrap variant which only includes essential packages
  if [ "${DEBIAN_MINBASE}" = yes ] ; then
    VARIANT="--variant=minbase"
  fi

  # Base debootstrap (unpack only)
  http_proxy=${APT_PROXY} \
    debootstrap --arch="${DEBIAN_RELEASE_ARCH}" \
		--foreign ${VARIANT} \
		--components="${COMPONENTS}" \
		--include="${APT_INCLUDES}" \
                "${DEBIAN_RELEASE}" "${R}" "http://${APT_SERVER}/debian"
    [ $? -eq 0 ] || exit $?;

  # Copy qemu emulator binary to chroot
  install -m 755 -o root -g root "${QEMU_BINARY}" "${R}${QEMU_BINARY}"

  # Copy debian-archive-keyring.pgp
  mkdir -p "${R}/usr/share/keyrings"
  install_readonly "/usr/share/keyrings/debian-archive-keyring.gpg" "${R}/usr/share/keyrings/debian-archive-keyring.gpg"

  # Complete the bootstrapping process
  chroot_exec /debootstrap/debootstrap --second-stage
  [ $? -eq 0 ] || exit $?;

  echo "Compressing rootfs '${ROOTFS_PKG}' to speed-up next build..."
  tar -czf "${BASEDIR}/debs/${ROOTFS_PKG}.tar.gz" -C "${BUILDDIR}/" "chroot"

else

  echo "Rootfs '${ROOTFS_PKG}' already exists, extract it"
  tar -C "${R}/" --strip-components=1 -xzf "${BASEDIR}/debs/${ROOTFS_PKG}.tar.gz"
fi
echo "Done."

# Mount required filesystems
mount -t proc none "${R}/proc"
mount -t sysfs none "${R}/sys"

# Mount pseudo terminal slave if supported by Debian release
if [ -d "${R}/dev/pts" ] ; then
  mount --bind /dev/pts "${R}/dev/pts"
fi
