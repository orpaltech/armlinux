#
# Install Bluetooth user-space packages
#

BLUEZ_ALSA_REPO_URL="https://github.com/arkq/bluez-alsa.git"
BLUEZ_ALSA_BRANCH="master"
BLUEZ_ALSA_VER="4.3.1"
BLUEZ_ALSA_TAG="v${BLUEZ_ALSA_VER}"
BLUEZ_ALSA_SRC_DIR=${EXTRADIR}/bluez-alsa

BLUEZ_ALSA_WITH_USER=y
BLUEZ_ALSA_WITH_MP3=y
BLUEZ_ALSA_WITH_AAC=n
BLUEZ_ALSA_WITH_TOOLS=y
BLUEZ_ALSA_WITH_SYSTEMD=y


bluez_alsa_install()
{
	PKG_FORCE_CLEAN=${BTH_FORCE_REBUILD} \
	update_src_pkg	"Bluez-alsa" \
			$BLUEZ_ALSA_VER \
			$BLUEZ_ALSA_SRC_DIR \
			$BLUEZ_ALSA_REPO_URL \
			$BLUEZ_ALSA_BRANCH \
			$BLUEZ_ALSA_TAG

	echo "Configure Bluez-alsa..."

	cd ${BLUEZ_ALSA_SRC_DIR}/
	autoreconf --install --force

	rm -f ./${LINUX_PLATFORM}-pkg-config
	rm -f ./${LINUX_PLATFORM}-gcc

	cat <<-EOF > ./${LINUX_PLATFORM}-pkg-config
#!/bin/sh
SYSROOT=${SYSROOT_DIR}
export PKG_CONFIG_SYSROOT_DIR="\${SYSROOT}"
export PKG_CONFIG_LIBDIR="\${SYSROOT}/usr/lib/pkgconfig:\${SYSROOT}/usr/share/pkgconfig:\${SYSROOT}/usr/lib/${LINUX_PLATFORM}/pkgconfig"
export PKG_CONFIG_PATH="\${SYSROOT}/usr/lib/pkgconfig:\${SYSROOT}/usr/share/pkgconfig:\${SYSROOT}/usr/lib/${LINUX_PLATFORM}/pkgconfig"
exec /usr/bin/pkg-config "\$@"
EOF
	chmod +x ./${LINUX_PLATFORM}-pkg-config

	cat <<-EOF > ./${LINUX_PLATFORM}-gcc
#!/bin/sh
${DEV_GCC} "\${@}" --sysroot=${SYSROOT_DIR}
EOF
	chmod +x ./${LINUX_PLATFORM}-gcc


	PKG_CONFIG="$(pwd)/${LINUX_PLATFORM}-pkg-config" \
	CC="$(pwd)/${LINUX_PLATFORM}-gcc" NM=$DEV_NM STRIP=$DEV_STRIP RANLIB=$DEV_RANLIB OBJCOPY=$DEV_OBJCOPY OBJDUMP=$DEV_OBJDUMP AR=$DEV_AR \
	CFLAGS="-I${SYSROOT_DIR}/usr/include -I${SYSROOT_DIR}/usr/include/${LINUX_PLATFORM} -I${SYSROOT_DIR}/usr/lib/${LINUX_PLATFORM}/dbus-1.0/include -I${SYSROOT_DIR}/usr/lib/${LINUX_PLATFORM}/glib-2.0/include" \
		./configure --prefix=/usr --enable-shared \
			--host=${LINUX_PLATFORM} \
			--with-sysroot=${SYSROOT_DIR} \
			--enable-upower \
			--with-dbusconfdir="/usr/share/dbus-1/system.d" --with-alsaplugindir="/usr/lib/alsa-lib" --with-alsaconfdir="/usr/etc/alsa/conf.d" \
			"${BLUEZ_ALSA_EXTRA_PARAMS[@]}"

	[ $? -eq 0 ] || exit $?;
	echo "Done."

	echo "Build Bluez-alsa..."

	chrt -i 0 make -s -j${HOST_CPU_CORES}
	[ $? -eq 0 ] || exit $?;

	chown -R ${CURRENT_USER}:${CURRENT_USER} ${BLUEZ_ALSA_SRC_DIR}
	echo "Done."

	echo "Deploy Bluez-alsa..."

	make install DESTDIR=${R}
	make install DESTDIR=${SYSROOT_DIR}

	mkdir -p ${R}/usr/var/lib/bluealsa

# begin chroot section
	if [ "${BLUEZ_ALSA_WITH_USER}" = y ] ; then
		chroot_exec adduser --system --group --no-create-home bluealsa
		chroot_exec adduser bluealsa bluetooth

		chroot_exec adduser --system --group --no-create-home bluealsa_aplay
		chroot_exec adduser bluealsa_aplay audio

		chroot_exec chown bluealsa /usr/var/lib/bluealsa
		chroot_exec chmod 0700 /usr/var/lib/bluealsa
	fi

	chroot_exec systemctl --no-reload enable ${BLUEZ_ALSA_DAEMON}.service
# end chroot section

	echo "Done."
}

if [ "${ENABLE_BTH}" = yes ] ; then
	echo -n -e "\n*** Build Settings ***\n"

	[[ ${CLEAN} =~ (^|,)bluetooth(,|$) ]] && BTH_FORCE_REBUILD=yes
	set -x
	BTH_FORCE_REBUILD=${BTH_FORCE_REBUILD:="no"}
	set +x


	# For more details
	# https://github.com/arkq/bluez-alsa/wiki/Migrating-from-release-4.3.1-or-earlier
	ver_compare "${BLUEZ_ALSA_VER}" "4.3.1"
	[[ $? -eq 1 ]] && BLUEZ_ALSA_NEW_VER=y


	BLUEZ_ALSA_EXTRA_PARAMS=()
	if [ "${BLUEZ_ALSA_WITH_AAC}" = y ] ; then
		BLUEZ_ALSA_EXTRA_PARAMS+=( --enable-aac )
	fi
	if [ "${BLUEZ_ALSA_WITH_MP3}" = y ] ; then
		BLUEZ_ALSA_EXTRA_PARAMS+=( --enable-mp3lame )
	fi
	if [ "${BLUEZ_ALSA_WITH_USER}" = y ] ; then
		BLUEZ_ALSA_EXTRA_PARAMS+=( --with-bluealsauser=bluealsa )
		BLUEZ_ALSA_EXTRA_PARAMS+=( --with-bluealsaaplayuser=bluealsa_aplay )
	fi
	if [ "${BLUEZ_ALSA_WITH_TOOLS}" = y ] ; then
		BLUEZ_ALSA_EXTRA_PARAMS+=( --enable-rfcomm )
		BLUEZ_ALSA_EXTRA_PARAMS+=( --enable-hcitop )
		BLUEZ_ALSA_EXTRA_PARAMS+=( --enable-a2dpconf )
		if [ "${BLUEZ_ALSA_NEW_VER}" != y ] ; then
			BLUEZ_ALSA_EXTRA_PARAMS+=( --enable-cli )
		fi
	else
		if [ "${BLUEZ_ALSA_NEW_VER}" = y ] ; then
			BLUEZ_ALSA_EXTRA_PARAMS+=( --disable-ctl )
		fi
        fi
	if [ "${BLUEZ_ALSA_WITH_SYSTEMD}" = y ] ; then
		BLUEZ_ALSA_EXTRA_PARAMS+=( --enable-systemd )
		BLUEZ_ALSA_EXTRA_PARAMS+=( --with-systemdsystemunitdir="/lib/systemd/system" )
		BLUEZ_ALSA_EXTRA_PARAMS+=( --with-systemdbluealsaargs="-S -p a2dp-source -p hsp-ag --initial-volume=50" )
	fi


	if [ "${BLUEZ_ALSA_NEW_VER}" = y ] ; then
		BLUEZ_ALSA_DAEMON=bluealsad
	else
		BLUEZ_ALSA_DAEMON=bluealsa
	fi

	echo "Installing Bluetooth packages..."

	bluez_alsa_install

	echo "Bluetooth packages installed."
fi
