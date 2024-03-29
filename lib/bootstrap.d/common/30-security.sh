#
# Setup users and security settings
#

# Generate crypt(3) password string
# 500000 rounds for extra security. See https://michaelfranzl.com/2016/09/09/hashing-passwords-sha512-stronger-than-bcrypt-rounds/
ENCRYPTED_PASSWORD=`mkpasswd -m sha-512 -R 100000 "${PASSWORD}"`

# Setup default user
if [ "$ENABLE_USER" = yes ] ; then
  chroot_exec adduser --gecos $USER_NAME --add_extra_groups \
	--disabled-password $USER_NAME
  chroot_exec usermod -p "${ENCRYPTED_PASSWORD}" $USER_NAME
  chroot_exec usermod -aG sudo $USER_NAME
fi

# Setup root password
if [ "$ENABLE_ROOT" = yes ] ; then
  chroot_exec usermod -p "${ENCRYPTED_PASSWORD}" root

  if [ "$ENABLE_ROOT_SSH" = yes ] ; then
    sed -i "s|[#]*PermitRootLogin.*|PermitRootLogin yes|g" "${ETC_DIR}/ssh/sshd_config"
  fi
else
  # Set no root password to disable root login
  chroot_exec usermod -p \'!\' root
fi

if [ "$ENABLE_SSHD" = yes ] ; then
  LOCAL_SSH_DIR=/home/${CURRENT_USER}/.ssh
  mkdir -p ${LOCAL_SSH_DIR}

  # Enable password-less login
  if [ ! -f "${LOCAL_SSH_DIR}/id_rsa" ] ; then
    ssh-keygen -f "${LOCAL_SSH_DIR}/id_rsa" -t rsa -N '' &> /dev/null
  fi
  chown ${CURRENT_USER}:${CURRENT_USER} ${LOCAL_SSH_DIR}/id_rsa

  mkdir -p ${R}/root/.ssh
  cat ${LOCAL_SSH_DIR}/id_rsa.pub >> ${R}/root/.ssh/authorized_keys

  if [ "$ENABLE_USER" = yes ] ; then
    mkdir -p ${R}/home/${USER_NAME}/.ssh
    cat ${LOCAL_SSH_DIR}/id_rsa.pub >> ${R}/home/${USER_NAME}/.ssh/authorized_keys
  fi
fi
