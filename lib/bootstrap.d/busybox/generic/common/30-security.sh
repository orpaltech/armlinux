#
# Setup users and security settings
#

SOURCE_NAME=$(basename ${BASH_SOURCE[0]})


#
# ############ helper functions ##############
#

set_user_passwd()
{
	local user_name=$1
	local password=$2

	echo "${SOURCE_NAME}: Set password for ${user_name} ..."

	cat << EOF > ${R}/tmp/set_passwd.sh
#!/bin/sh

(echo ${password}; echo ${password}) | passwd ${user_name}
EOF

	chmod +x ${R}/tmp/set_passwd.sh

	chroot_exec /tmp/set_passwd.sh

	rm -f ${R}/tmp/set_passwd.sh

	echo "${SOURCE_NAME}: Done."
}


#
# ############ install packages ##############
#

# Enable root login
if [ "${ENABLE_ROOT}" = yes ] ; then
    # set the root password
    set_user_passwd root ${PASSWORD}
fi


# Setup extra user
if [ "${ENABLE_USER}" = yes ] ; then
    chroot_exec adduser -g ${USER_NAME} -D -s /bin/sh	${USER_NAME}

    set_user_passwd ${USER_NAME} ${PASSWORD}

    if [ "${USER_ADMIN}" = yes ] ; then
	chroot_exec adduser ${USER_NAME} root
	chroot_exec adduser ${USER_NAME} adm
    fi

    if [ -n "${USER_GROUPS}" ] ; then
	make_array ${USER_GROUPS}
	for i in "${temp_array[@]}" ; do
	    chroot_exec adduser ${USER_NAME} $i
	done
    fi
fi

# Let's get rid on annoying log messages:
# lastlog_perform_login: Couldn't stat /var/log/lastlog: No such file or directory
# lastlog_openseek: /var/log/lastlog is not a file or directory!
chroot_exec touch /var/log/lastlog
chroot_exec chgrp utmp /var/log/lastlog
chroot_exec chmod 664 /var/log/lastlog
