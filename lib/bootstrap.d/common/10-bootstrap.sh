#
# Debootstrap basic system
#

ROOTFS_PKG="rootfs-${DEBIAN_RELEASE}-${DEBIAN_RELEASE_ARCH}-${VERSION}"

if [[ $CLEAN_OPTIONS =~ (^|,)"rootfs"(,|$) ]] ; then
  rm -f "${BASEDIR}/debs/${ROOTFS_PKG}.tar.gz"
fi

if [ ! -f "${BASEDIR}/debs/${ROOTFS_PKG}.tar.gz" ] ; then

  VARIANT=""
  COMPONENTS="main"

  # Use non-free Debian packages if needed
  if [ "${ENABLE_NONFREE}" = yes ] ; then
    COMPONENTS="main,non-free"
  fi

  # Use minbase bootstrap variant which only includes essential packages
  if [ "$ENABLE_MINBASE" = true ] ; then
    VARIANT="--variant=minbase"
  fi

  # Base debootstrap (unpack only)
  http_proxy=${APT_PROXY} debootstrap --arch="${DEBIAN_RELEASE_ARCH}" --foreign ${VARIANT} --components="${COMPONENTS}" --include="${APT_INCLUDES}" "${DEBIAN_RELEASE}" "${R}" "http://${APT_SERVER}/debian"

  # Copy qemu emulator binary to chroot
  install -m 755 -o root -g root "${QEMU_BINARY}" "${R}${QEMU_BINARY}"

  # Copy debian-archive-keyring.pgp
  mkdir -p "${R}/usr/share/keyrings"
  install_readonly /usr/share/keyrings/debian-archive-keyring.gpg "${R}/usr/share/keyrings/debian-archive-keyring.gpg"

  # Complete the bootstrapping process
  chroot_exec /debootstrap/debootstrap --second-stage

  echo "Compress rootfs to speed up subsequent builds"
  tar -czf "${BASEDIR}/debs/${ROOTFS_PKG}.tar.gz" -C "${BUILDDIR}/" "chroot"

else
  echo "Rootfs already exists, extract it"
  tar -C "${R}/" --strip-components=1 -xzf "${BASEDIR}/debs/${ROOTFS_PKG}.tar.gz"
fi

# Mount required filesystems
mount -t proc none "${R}/proc"
mount -t sysfs none "${R}/sys"

# Mount pseudo terminal slave if supported by Debian release
if [ -d "${R}/dev/pts" ] ; then
  mount --bind /dev/pts "${R}/dev/pts"
fi
