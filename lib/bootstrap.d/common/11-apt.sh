#
# Setup APT repositories
#

# Install and setup APT proxy configuration
if [ -z "${APT_PROXY}" ] ; then
  install_readonly "${FILES_DIR}/apt/10proxy" "${ETC_DIR}/apt/apt.conf.d/10proxy"
  sed -i "s/\"\"/\"${APT_PROXY}\"/" "${ETC_DIR}/apt/apt.conf.d/10proxy"
fi

install_readonly "${FILES_DIR}/apt/sources.list" "${ETC_DIR}/apt/sources.list"

# Use specified APT server and release
sed -i "s/\/deb.debian.org\//\/${APT_SERVER}\//" "${ETC_DIR}/apt/sources.list"
sed -i "s/ stretch/ ${DEBIAN_RELEASE}/" "${ETC_DIR}/apt/sources.list"


# Allow the installation of non-free Debian packages
if [ "${ENABLE_NONFREE}" = yes ] ; then
  sed -i "s/ contrib/ contrib non-free/" "${ETC_DIR}/apt/sources.list"
fi

# Upgrade package index and update all installed packages and changed dependencies
chroot_exec apt-get -qq -y update
chroot_exec apt-get -qq -y -u dist-upgrade

local PKG_COUNT=$(count_files "${BOOTSTRAP_D}/${CONFIG}/packages/*.deb")
if [ $PKG_COUNT -gt 0 ] ; then
  for package in ${BOOTSTRAP_D}/${CONFIG}/packages/*.deb ; do
    cp $package ${R}/tmp
    chroot_exec dpkg --unpack /tmp/$(basename $package)
  done
fi

chroot_exec apt-get -qq -y -f install $(echo "${APT_INCLUDES}" | sed -e 's/,/ /g')

chroot_exec apt-get -qq -y check
