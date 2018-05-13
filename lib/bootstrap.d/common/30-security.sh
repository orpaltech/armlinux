#
# Setup users and security settings
#

# Generate crypt(3) password string
# 500000 rounds for extra security. See https://michaelfranzl.com/2016/09/09/hashing-passwords-sha512-stronger-than-bcrypt-rounds/
ENCRYPTED_PASSWORD=`mkpasswd -m sha-512 -R 100000 "${PASSWORD}"`

# Setup default user
if [ "$ENABLE_USER" = true ] ; then
  chroot_exec adduser --gecos $USER_NAME --add_extra_groups \
	--disabled-password $USER_NAME
  chroot_exec usermod -p "${ENCRYPTED_PASSWORD}" $USER_NAME
fi

# Setup root password or not
if [ "$ENABLE_ROOT" = true ] ; then
  chroot_exec usermod -p "${ENCRYPTED_PASSWORD}" root

  if [ "$ENABLE_ROOT_SSH" = true ] ; then
    sed -i "s|[#]*PermitRootLogin.*|PermitRootLogin yes|g" "${ETC_DIR}/ssh/sshd_config"
  fi
else
  # Set no root password to disable root login
  chroot_exec usermod -p \'!\' root
fi
