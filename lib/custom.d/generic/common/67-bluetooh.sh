#
# Install Bluetooth user-space packages
#

BLUEZ_ALSA_REPO_URL="https://github.com/arkq/bluez-alsa.git"
BLUEZ_ALSA_BRANCH="master"
BLUEZ_ALSA_VER="4.2.0"
BLUEZ_ALSA_TAG="v${BLUEZ_ALSA_VER}"
BLUEZ_ALSA_SRC_DIR=${EXTRADIR}/bluez-alsa
BLUEZ_ALSA_WITH_USER=no
BLUEZ_ALSA_WITH_MP3=yes
BLUEZ_ALSA_WITH_AAC=yes


update_pkg_src()
{
	pkg_name=$1
	pkg_ver=$2
	pkg_src_dir=$3
	pkg_repo_url=$4
	pkg_branch=$5
	pkg_tag=$6

	echo "Prepare ${pkg_name} sources..."BLUEZ_ALSA_WITH_AAC

	if [ "${BLUETOOTH_FORCE_REBUILD}" = yes ] ; then
		echo "Force ${pkg_name} source update"
		rm -rf ${pkg_src_dir}
	fi

	if [ -d ${pkg_src_dir} ] && [ -d ${pkg_src_dir}/.git ] ; then
                local old_url=$(git -C ${pkg_src_dir} config --get remote.origin.url)
                if [ "${old_url}" != "${pkg_repo_url}" ] ; then
                        rm -rf ${pkg_src_dir}
                fi
        fi

	if [ -d ${pkg_src_dir} ] && [ -d ${pkg_src_dir}/.git ] ; then
                # update sources
                git -C ${pkg_src_dir} fetch origin --tags

                git -C ${pkg_src_dir} reset --hard
                git -C ${pkg_src_dir} clean -fdx

                echo "Checking out branch: ${pkg_branch}"
                git -C ${pkg_src_dir} checkout -B ${pkg_branch} origin/${pkg_branch}
                git -C ${pkg_src_dir} pull
        else
		[ -d ${pkg_src_dir} ] && rm -rf ${pkg_src_dir}

		# clone sources
		git clone ${pkg_repo_url} -b ${pkg_branch} --tags ${pkg_src_dir}
        fi

	if [ ! -z "${pkg_tag}" ] ; then
		echo "Checking out tag: tags/${pkg_tag}"
		git -C ${pkg_src_dir} checkout tags/${pkg_tag}
	fi

	display_alert "Sources ready" "release ${pkg_ver}" "info"
}

bluez_alsa_update()
{
	update_pkg_src "Bluez-alsa" \
			$BLUEZ_ALSA_VER \
			$BLUEZ_ALSA_SRC_DIR \
			$BLUEZ_ALSA_REPO_URL \
			$BLUEZ_ALSA_BRANCH \
			$BLUEZ_ALSA_TAG
}

bluez_alsa_make()
{
	echo "Configure Bluez-alsa..."

#	export CFLAGS="-I${SYSROOT_DIR}/usr/include -I${SYSROOT_DIR}/usr/include/${LINUX_PLATFORM} -I${SYSROOT_DIR}/usr/lib/${LINUX_PLATFORM}/dbus-1.0/include -I${SYSROOT_DIR}/usr/lib/${LINUX_PLATFORM}/glib-2.0/include"
#	export LDFLAGS="-L${TOOLCHAIN_LIBDIR} -L${SYSROOT_DIR}/usr/lib -Wl,-rpath-link,${SYSROOT_DIR}/usr/lib/${LINUX_PLATFORM}"
#	export LDFLAGS="-L${SYSROOT_DIR}/usr/lib -L${SYSROOT_DIR}/lib/${LINUX_PLATFORM} -Wl,-rpath -Wl,${SYSROOT_DIR}/usr/lib/${LINUX_PLATFORM}"

	cd ${BLUEZ_ALSA_SRC_DIR}
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

	if [ ${BLUEZ_ALSA_WITH_AAC} = yes ] ; then
		BLUEZ_ALSA_EXTRA_PARAMS="--enable-aac"
	fi
	if [ ${BLUEZ_ALSA_WITH_MP3} = yes ] ; then
		BLUEZ_ALSA_EXTRA_PARAMS="--enable-mp3lame ${BLUEZ_ALSA_EXTRA_PARAMS}"
	fi
	if [ ${BLUEZ_ALSA_WITH_USER} = yes ] ; then
		BLUEZ_ALSA_EXTRA_PARAMS="--with-bluealsauser=bluealsa --with-bluealsaaplayuser=bluealsa_aplay ${BLUEZ_ALSA_EXTRA_PARAMS}"
	fi

	PKG_CONFIG="$(pwd)/${LINUX_PLATFORM}-pkg-config" \
	CC="$(pwd)/${LINUX_PLATFORM}-gcc" NM=$DEV_NM STRIP=$DEV_STRIP RANLIB=$DEV_RANLIB OBJCOPY=$DEV_OBJCOPY OBJDUMP=$DEV_OBJDUMP AR=$DEV_AR \
	CFLAGS="-I${SYSROOT_DIR}/usr/include -I${SYSROOT_DIR}/usr/include/${LINUX_PLATFORM} -I${SYSROOT_DIR}/usr/lib/${LINUX_PLATFORM}/dbus-1.0/include -I${SYSROOT_DIR}/usr/lib/${LINUX_PLATFORM}/glib-2.0/include" \
		./configure --prefix=/usr --enable-shared \
			--host=${LINUX_PLATFORM} \
			--with-sysroot=${SYSROOT_DIR} \
			--enable-systemd --enable-cli --enable-a2dpconf --enable-upower \
			${BLUEZ_ALSA_EXTRA_PARAMS}

	[ $? -eq 0 ] || exit $?;
	echo "Done."

	echo "Build Bluez-alsa..."

	make
	[ $? -eq 0 ] || exit $?;

	chown -R ${CURRENT_USER}:${CURRENT_USER} ${BLUEZ_ALSA_SRC_DIR}
	echo "Done."
}

bluez_alsa_deploy()
{
	echo "Deploy Bluez-alsa..."

	DESTDIR=${SYSROOT_DIR} make install
	DESTDIR=${R} make install

	mkdir -p ${R}/usr/var/lib/bluealsa

# begin chroot section
	if [ ${BLUEZ_ALSA_WITH_USER} = yes ] ; then
		chroot_exec adduser --system --group --no-create-home bluealsa
		chroot_exec adduser bluealsa bluetooth

		chroot_exec adduser --system --group --no-create-home bluealsa_aplay
		chroot_exec adduser bluealsa_aplay audio

		chroot_exec chown bluealsa /usr/var/lib/bluealsa
		chroot_exec chmod 0700 /usr/var/lib/bluealsa
	fi

	chroot_exec systemctl --no-reload enable bluealsa.service
# end chroot section

	echo "Done."
}

if [ "${ENABLE_BLUETOOTH}" = yes ] ; then
	echo -n -e "\n*** Build Settings ***\n"

	if [[ ${CLEAN} =~ (^|,)bluetooth(,|$) ]] ; then
		BLUETOOTH_FORCE_REBUILD=yes
	fi

	set -x

	BLUETOOTH_FORCE_REBUILD=${BLUETOOTH_FORCE_REBUILD:="no"}

	set +x

	echo "Installing Bluetooth packages..."

	bluez_alsa_update
	bluez_alsa_make
	bluez_alsa_deploy

	echo "Bluetooth packages installed."
fi
