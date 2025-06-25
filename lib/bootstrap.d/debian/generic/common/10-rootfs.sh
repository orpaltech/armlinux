#
# Prepare root file system
#

[ "${DEBIAN_MINBASE}" = yes ] && MINBASE_="minbase_"
ROOTFS_PKG="rootfs-${DEBIAN_RELEASE}-${DPKG_ARCH}_${MINBASE_}${PRODUCT_FULL_VER}-${SOC_FAMILY}-${CONFIG}"

mkdir -p ${BASEDIR}/debs

if [[ ${CLEAN} =~ (^|,)rootfs(,|$) ]] ; then
  rm -f ${BASEDIR}/debs/${ROOTFS_PKG}.txt
fi

DEBIAN_VARIANT=
COMPONENTS="main,contrib"

# Use non-free Debian packages if needed
if [ "${DEBIAN_NONFREE}" = yes ] ; then
  COMPONENTS="${COMPONENTS},non-free"
fi

# Use minbase bootstrap variant which only includes essential packages
if [ "${DEBIAN_MINBASE}" = yes ] ; then
  DEBIAN_VARIANT="--variant=minbase"
fi

cat <<-EOF > ${BASEDIR}/debs/${ROOTFS_PKG}.txt~
DEBIAN_VARIANT=${DEBIAN_VARIANT}
COMPONENTS=${COMPONENTS}
APT_INCLUDES=${APT_INCLUDES}
APT_EXCLUDES=${APT_EXCLUDES}
EOF

if [ ! -f ${BASEDIR}/debs/${ROOTFS_PKG}.txt ] ; then
  rm -f ${BASEDIR}/debs/${ROOTFS_PKG}.tar.gz
else
  hash=$(/usr/bin/md5sum ${BASEDIR}/debs/${ROOTFS_PKG}.txt | /bin/cut -f1 -d" ")
  hash2=$(/usr/bin/md5sum ${BASEDIR}/debs/${ROOTFS_PKG}.txt~ | /bin/cut -f1 -d" ")
  if [ "${hash}" != "${hash2}" ] ; then
    rm -f ${BASEDIR}/debs/${ROOTFS_PKG}.tar.gz
    rm -f ${BASEDIR}/debs/${ROOTFS_PKG}.txt
  fi
fi

if [ ! -f ${BASEDIR}/debs/${ROOTFS_PKG}.tar.gz ] ; then
  echo "Rootfs '${ROOTFS_PKG}' was not found, debootstrap"

  # Base debootstrap (unpack only)
  http_proxy=${APT_PROXY} \
    debootstrap --arch="${DPKG_ARCH}" \
		--foreign \
		${DEBIAN_VARIANT} \
		--components="${COMPONENTS}" \
		--include="${APT_INCLUDES}" \
		--exclude="${APT_EXCLUDES}" \
		"${DEBIAN_RELEASE}" "${R}" "http://${APT_SERVER}/debian"
  [ $? -eq 0 ] || exit $?;

  # Copy qemu emulator binary to chroot
  install -m 755 -o root -g root "${QEMU_BINARY}" "${R}${QEMU_BINARY}"

  # Complete the bootstrapping process
  echo "Run debootstrap second-stage..."
  chroot_exec /debootstrap/debootstrap --second-stage
  [ $? -eq 0 ] || exit $?;

  echo "Compressing rootfs '${ROOTFS_PKG}' to speed-up next build..."
  tar -czf "${BASEDIR}/debs/${ROOTFS_PKG}.tar.gz" -C "${BUILDDIR}/" "chroot"

  mv ${BASEDIR}/debs/${ROOTFS_PKG}.txt~ ${BASEDIR}/debs/${ROOTFS_PKG}.txt

else

  echo "Rootfs '${ROOTFS_PKG}' already exists, extract it"

  rm -rf ${R}/*
  tar -C "${R}/" --strip-components=1 -xzf "${BASEDIR}/debs/${ROOTFS_PKG}.tar.gz"

  rm -f ${BASEDIR}/debs/${ROOTFS_PKG}.txt~
fi

echo "Done."

# Mount required directories
mount -t proc none "${R}/proc"
mount -t sysfs none "${R}/sys"

# Mount pseudo terminal slave if supported by Debian release
if [ -d "${R}/dev/pts" ] ; then
  mount --bind /dev/pts "${R}/dev/pts"
fi

# Temporarily use static resolv.conf file
chroot_exec mv /etc/resolv.conf /etc/resolv.conf.orig
chroot_exec ln -s /usr/lib/systemd/resolv.conf /etc/resolv.conf
