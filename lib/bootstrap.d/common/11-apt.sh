#
# Setup APT repositories
#

# Install and setup APT proxy configuration
if [ -z "${APT_PROXY}" ] ; then
  install_readonly "${FILES_DIR}/apt/10proxy" "${ETC_DIR}/apt/apt.conf.d/10proxy"
  sed -i "s/\"\"/\"${APT_PROXY}\"/" "${ETC_DIR}/apt/apt.conf.d/10proxy"
fi

install_readonly "${FILES_DIR}/apt/${DEBIAN_RELEASE}/sources.list" "${ETC_DIR}/apt/sources.list"

# Use specified debian APT server and debian release
sed -i "s/\/deb.debian.org\//\/${APT_SERVER}\//" "${ETC_DIR}/apt/sources.list"


# Allow the installation of non-free Debian packages
if [ "${DEBIAN_NONFREE}" = yes ] ; then
  sed -i "s/ main/ main contrib non-free/" "${ETC_DIR}/apt/sources.list"
fi

# Upgrade package index and update all installed packages and changed dependencies
chroot_exec apt-get -qq -y update
chroot_exec apt-get -qq -y -u dist-upgrade

PKG_COUNT=$(count_files "${BOOTSTRAP_D}/${CONFIG}/packages/*.deb")
if [ $PKG_COUNT -gt 0 ] ; then
  for package in ${BOOTSTRAP_D}/${CONFIG}/packages/*.deb ; do
    cp $package ${R}/tmp
    chroot_exec dpkg --unpack /tmp/$(basename $package)
  done
fi

chroot_exec apt-get -qq -y -f install $(echo "${APT_INCLUDES}" | sed -e 's/,/ /g')

if [ "${ENABLE_X11}" = yes ] ; then
  chroot_exec apt-get -qq -y -f install "libxcb-*-dev"
fi

# See if our configuration requires any packages
if [ ! -z "${APT_CONFIG_PACKAGES}" ] ; then
  chroot_exec apt-get -qq -y install $(echo "${APT_CONFIG_PACKAGES}" | sed -e 's/,/ /g')
fi

# See if our board requires any packages
if [ ! -z "${APT_BOARD_PACKAGES}" ] ; then
  chroot_exec apt-get -qq -y install $(echo "${APT_BOARD_PACKAGES}" | sed -e 's/,/ /g')
fi

if [ "${ENABLE_X11}" = yes ] ; then
  chroot_exec apt-get -qq -y -f install "libxcb-*-dev"
fi

if [ ! -z "${APT_REMOVE_PACKAGES}" ] ; then
  chroot_exec apt-get -qq -y remove $(echo "${APT_REMOVE_PACKAGES}" | sed -e 's/,/ /g')
fi

chroot_exec apt-get -qq -y check
