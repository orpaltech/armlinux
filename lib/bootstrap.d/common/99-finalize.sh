#
# Reduce system disk usage
#

# Reduce the image size by various operations
if [ "${ENABLE_REDUCE}" = yes ] ; then
  if [ "$REDUCE_APT" = yes ] ; then
    # Install dpkg configuration file
    if [ "$REDUCE_DOC" = yes ] || [ "$REDUCE_MAN" = yes ] ; then
      install_readonly "${FILES_DIR}/dpkg/01nodoc" "${ETC_DIR}/dpkg/dpkg.cfg.d/01nodoc"
    fi

    # Install APT configuration files
    install_readonly "${FILES_DIR}/apt/02nocache" "${ETC_DIR}/apt/apt.conf.d/02nocache"
    install_readonly "${FILES_DIR}/apt/03compress" "${ETC_DIR}/apt/apt.conf.d/03compress"
    install_readonly "${FILES_DIR}/apt/04norecommends" "${ETC_DIR}/apt/apt.conf.d/04norecommends"

    # Remove APT cache files
    rm -fr "${R}/var/cache/apt/pkgcache.bin"
    rm -fr "${R}/var/cache/apt/srcpkgcache.bin"
  fi

  # Remove all doc files
  if [ "$REDUCE_DOC" = yes ] ; then
    find "${R}/usr/share/doc" -depth -type f ! -name copyright | xargs rm || true
    find "${R}/usr/share/doc" -empty | xargs rmdir || true
  fi

  # Remove all man pages and info files
  if [ "$REDUCE_MAN" = yes ] ; then
    rm -rf "${R}/usr/share/man" "${R}/usr/share/groff" "${R}/usr/share/info" "${R}/usr/share/lintian" "${R}/usr/share/linda" "${R}/var/cache/man"
  fi

  # Remove all locale translation files
  if [ "$REDUCE_LOCALE" = yes ] ; then
    find "${R}/usr/share/locale" -mindepth 1 -maxdepth 1 ! -name 'en' | xargs rm -r
  fi

  # Remove hwdb PCI device classes (experimental)
  if [ "$REDUCE_HWDB" = yes ] ; then
    rm -fr "/lib/udev/hwdb.d/20-pci-*"
  fi

  # Replace bash shell by dash shell (experimental)
  if [ "$REDUCE_BASH" = yes ] ; then
    echo "Yes, do as I say!" | chroot_exec apt-get purge -qq -y ${APT_FORCE_YES} bash
    chroot_exec update-alternatives --install /bin/bash bash /bin/dash 100
  fi

  # Clean APT list of repositories
  rm -fr "${R}/var/lib/apt/lists/*"
  chroot_exec apt-get -qq -y update
fi

# Restore original resolv.conf file
chroot_exec rm -f /etc/resolv.conf
chroot_exec mv /etc/resolv.conf.orig /etc/resolv.conf

echo "Done."
