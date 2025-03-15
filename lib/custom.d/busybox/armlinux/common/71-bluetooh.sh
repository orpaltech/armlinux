#
# Install Bluetooth user-space packages
#


ICAL_REPO_URL="https://github.com/libical/libical.git"
ICAL_BRANCH=master
ICAL_VERSION=3.0.19
ICAL_TAG="v${ICAL_VERSION}"
ICAL_SRC_DIR=${EXTRADIR}/libical
ICAL_BUILD_DIR=${ICAL_SRC_DIR}/${BB_BUILD_OUT}


BLUEZ_REPO_URL="https://github.com/bluez/bluez.git"
BLUEZ_BRANCH=master
BLUEZ_VERSION=5.79
BLUEZ_TAG="${BLUEZ_VERSION}"
BLUEZ_SRC_DIR=${EXTRADIR}/bluez
BLUEZ_BUILD_DIR=${BLUEZ_SRC_DIR}/${BB_BUILD_OUT}


LIBMD_REPO_URL="https://git.hadrons.org/cgit/libmd.git"
LIBMD_BRANCH=main
LIBMD_VERSION=1.1.0
LIBMD_TAG="${LIBMD_VERSION}"
LIBMD_SRC_DIR=${EXTRADIR}/libmd
LIBMD_BUILD_DIR=${LIBMD_SRC_DIR}/${BB_BUILD_OUT}


LIBBSD_REPO_URL="https://gitlab.freedesktop.org/libbsd/libbsd.git"
LIBBSD_BRANCH=main
LIBBSD_VERSION=0.12.2
LIBBSD_TAG="${LIBBSD_VERSION}"
LIBBSD_SRC_DIR=${EXTRADIR}/libbsd
LIBBSD_BUILD_DIR=${LIBBSD_SRC_DIR}/${BB_BUILD_OUT}

LIBSBC_REPO_URL="https://git.kernel.org/pub/scm/bluetooth/sbc.git"
LIBSBC_BRANCH=master
LIBSBC_VERSION=2.0
LIBSBC_TAG="${LIBSBC_VERSION}"
LIBSBC_SRC_DIR=${EXTRADIR}/libsbc
LIBSBC_BUILD_DIR=${LIBSBC_SRC_DIR}/${BB_BUILD_OUT}


BLUEZ_ALSA_REPO_URL="https://github.com/arkq/bluez-alsa.git"
BLUEZ_ALSA_BRANCH=master
BLUEZ_ALSA_VERSION=4.3.1
BLUEZ_ALSA_TAG="v${BLUEZ_ALSA_VERSION}"
BLUEZ_ALSA_SRC_DIR=${EXTRADIR}/bluez-alsa
BLUEZ_ALSA_BUILD_DIR=${BLUEZ_ALSA_SRC_DIR}/${BB_BUILD_OUT}

BLUEZ_ALSA_WITH_MP3=
BLUEZ_ALSA_WITH_AAC=
BLUEZ_ALSA_WITH_TOOLS=yes
BLUEZ_ALSA_WITH_USER=

SOURCE_NAME=$(basename ${BASH_SOURCE[0]})


#
# ############ helper functions ##############
#

libical_install()
{
    update_src_pkg "libical" \
                    $ICAL_VERSION \
                    $ICAL_SRC_DIR \
                    $ICAL_REPO_URL \
                    $ICAL_BRANCH \
                    $ICAL_TAG

    if [ "${BTH_FORCE_REBUILD}" = yes ] ; then
        rm -rf ${ICAL_BUILD_DIR}
    fi

    mkdir -p ${ICAL_BUILD_DIR}
    cd ${ICAL_BUILD_DIR}


    PKG_CONFIG=${BB_PKG_CONFIG} \
    cmake \
	-DCROSS_COMPILE=${BB_CROSS_COMPILE} \
	-DCROSS_SYSROOT=${R} \
	-DCMAKE_TOOLCHAIN_FILE=${LIBDIR}/cmake/generic.toolchain.cmake \
	-DICAL_BUILD_DOCS=OFF \
	-DENABLE_GTK_DOC=OFF \
	-DICAL_GLIB=OFF \
	-DLIBICAL_BUILD_TESTING=OFF -DLIBICAL_BUILD_EXAMPLES=OFF \
	-DCMAKE_INSTALL_PREFIX=/usr \
	../

    echo "${SOURCE_NAME}: Make libical ..."

    chrt -i 0 make -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Deploy libical to ${R} ..."

    make  install DESTDIR=${R}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."

}

bluez_install()
{
    update_src_pkg "bluez" \
                    $BLUEZ_VERSION \
                    $BLUEZ_SRC_DIR \
                    $BLUEZ_REPO_URL \
                    $BLUEZ_BRANCH \
                    $BLUEZ_TAG

    if [ "${BTH_FORCE_REBUILD}" = yes ] ; then
	rm -rf ${BLUEZ_BUILD_DIR}
    fi

    cd ${BLUEZ_SRC_DIR}/
    ./bootstrap

    mkdir -p ${BLUEZ_BUILD_DIR}
    cd ${BLUEZ_BUILD_DIR}/

    echo "${SOURCE_NAME}: Configure Bluez ..."

    #
    # IMPORTANT: delete R-prefix as 'configure' won't do it correctly
    #
    local dbus_conf_dir=$($BB_PKG_CONFIG --variable=datadir dbus-1 | grep -oP "^${R}\K.*")
    local dbus_sessionbus_dir=$($BB_PKG_CONFIG --variable=session_bus_services_dir dbus-1 | grep -oP "^${R}\K.*")
    local dbus_systembus_dir=$($BB_PKG_CONFIG --variable=system_bus_services_dir dbus-1 | grep -oP "^${R}\K.*")

    PKG_CONFIG=${BB_PKG_CONFIG} \
    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    CFLAGS="-I${R}/usr/include" \
    LDFLAGS="-L${R}/usr/lib" LIBS="-ltinfo" \
    MAKEINFO=/bin/true \
	../configure \
		--host=${BB_PLATFORM} \
		--srcdir=${BLUEZ_SRC_DIR} \
		--disable-udev --disable-cups --disable-systemd --disable-manpages --enable-deprecated --enable-library \
		--enable-shared --disable-static \
		--prefix=/usr \
		--with-sysroot=${R} \
		--with-dbusconfdir="${dbus_conf_dir}" --with-dbussystembusdir="${dbus_systembus_dir}" --with-dbussessionbusdir="${dbus_sessionbus_dir}"

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Make Bluez ..."

    chrt -i 0 make -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Deploy Bluez to ${R} ..."

    make  install DESTDIR=${R}
    [ $? -eq 0 ] || exit $?;

    install_exec ${FILES_DIR}/init/optional/S71bluetooth  ${ETC_DIR}/init.d/

    echo "${SOURCE_NAME}: Done."
}

libmd_install()
{
    update_src_pkg "libmd" \
                    $LIBMD_VERSION \
                    $LIBMD_SRC_DIR \
                    $LIBMD_REPO_URL \
                    $LIBMD_BRANCH \
                    $LIBMD_TAG

    if [ "${BTH_FORCE_REBUILD}" = yes ] ; then
        rm -rf ${LIBMD_BUILD_DIR}
    fi

    cd ${LIBMD_SRC_DIR}/
    ./autogen

    mkdir -p ${LIBMD_BUILD_DIR}
    cd ${LIBMD_BUILD_DIR}/

    echo "${SOURCE_NAME}: Configure libmd ..."

    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    MAKEINFO=/bin/true \
	../configure --prefix=/usr \
		--srcdir=${LIBMD_SRC_DIR} \
                --host=${BB_PLATFORM} \
		--enable-shared --disable-static

# fix issue with missing helper.c
    cp ../src/helper.c ./src/

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Make libmd ..."

    chrt -i 0 make -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Deploy libmd to ${R} ..."

    make  install DESTDIR=${R}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."

}


libbsd_install()
{
    update_src_pkg "libbsd" \
                    $LIBBSD_VERSION \
                    $LIBBSD_SRC_DIR \
                    $LIBBSD_REPO_URL \
                    $LIBBSD_BRANCH \
                    $LIBBSD_TAG


    cd ${LIBBSD_SRC_DIR}/
    ./autogen


    echo "${SOURCE_NAME}: Configure libbsd ..."

    CC=${BB_GCC} LD=${BB_LD} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    CFLAGS="-I${R}/usr/include" \
    LDFLAGS="-lmd -L${R}/usr/lib" \
    MAKEINFO=/bin/true \
        ./configure	--host=${BB_PLATFORM} \
			--prefix=/usr \
		--enable-shared --disable-static

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Make libbsd ..."

    chrt -i 0 make -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Deploy libbsd to ${R} ..."

# IMPORTANT: installer is broken - it produces GNU ld script instead of a symbolic link
    make  install DESTDIR=${R}
    [ $? -eq 0 ] || exit $?;
# .. so must reinstall *.so-file manually
    cp -P ./src/.libs/libbsd.so	${R}/usr/lib/

    echo "${SOURCE_NAME}: Done."

}


libsbc_install()
{
    update_src_pkg "libsbc" \
                    $LIBSBC_VERSION \
                    $LIBSBC_SRC_DIR \
                    $LIBSBC_REPO_URL \
                    $LIBSBC_BRANCH \
                    $LIBSBC_TAG

    if [ "${BTH_FORCE_REBUILD}" = yes ] ; then
        rm -rf ${LIBSBC_BUILD_DIR}
    fi

    echo "${SOURCE_NAME}: Configure libsbc ..."

    cd ${LIBSBC_SRC_DIR}/
    ./bootstrap

    mkdir -p ${LIBSBC_BUILD_DIR}
    cd ${LIBSBC_BUILD_DIR}/

    PKG_CONFIG=${BB_PKG_CONFIG} \
    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    CFLAGS="-I${R}/usr/include" \
    LDFLAGS="-L${R}/usr/lib" \
    MAKEINFO=/bin/true \
        ../configure --prefix=/usr \
                --host=${BB_PLATFORM} \
                --srcdir=${LIBSBC_SRC_DIR} \
		--enable-shared --disable-static \
		--disable-tools	--with-sysroot=${R}

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Make libsbc ..."

    chrt -i 0 make -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Deploy libsbc to ${R} ..."

    make  install DESTDIR=${R}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."

}


bluez_alsa_install()
{
    update_src_pkg "bluez-alsa" \
		$BLUEZ_ALSA_VERSION \
		$BLUEZ_ALSA_SRC_DIR \
		$BLUEZ_ALSA_REPO_URL \
		$BLUEZ_ALSA_BRANCH \
		$BLUEZ_ALSA_TAG

    cd ${BLUEZ_ALSA_SRC_DIR}/
    autoreconf --install --force


    if [ "${BLUEZ_ALSA_WITH_AAC}" = yes ] ; then
	BLUEZ_ALSA_EXTRA_PARAMS="--enable-aac"
    fi
    if [ "${BLUEZ_ALSA_WITH_MP3}" = yes ] ; then
	BLUEZ_ALSA_EXTRA_PARAMS="--enable-mp3lame ${BLUEZ_ALSA_EXTRA_PARAMS}"
    fi
    if [ "${BLUEZ_ALSA_WITH_USER}" = yes ] ; then
	BLUEZ_ALSA_EXTRA_PARAMS="--with-bluealsauser=bluealsa --with-bluealsaaplayuser=bluealsa_aplay ${BLUEZ_ALSA_EXTRA_PARAMS}"
    fi
    if [ "${BLUEZ_ALSA_WITH_TOOLS}" = yes ] ; then
	BLUEZ_ALSA_EXTRA_PARAMS="--enable-cli --enable-rfcomm --enable-hcitop --enable-a2dpconf ${BLUEZ_ALSA_EXTRA_PARAMS}"
    fi


    echo "${SOURCE_NAME}: Configure Bluez-alsa..."

    CFLAGS="-I${R}/usr/include"
    LDFLAGS="-L${R}/usr/lib"


    PKG_CONFIG=${BB_PKG_CONFIG} \
    CC=${BB_GCC} \
    NM=${BB_NM} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} OBJCOPY=${BB_OBJCOPY} OBJDUMP=${BB_OBJDUMP} AR=${BB_AR} \
    CFLAGS="${CFLAGS}" \
    LDFLAGS="${LDFLAGS}" LIBS="-ltinfo -lmd" \
    GIO2_LIBS="-lgio-2.0 -lgobject-2.0 -lgmodule-2.0 -lffi -lz  ${LDFLAGS}" \
    MAKEINFO=/bin/true \
	./configure --prefix=/usr \
		--enable-shared \
		--host=${BB_PLATFORM} \
		--with-sysroot=${R} \
		--with-dbusconfdir="/usr/share/dbus-1/system.d" \
		--with-alsaplugindir="/usr/lib/alsa-lib" \
		--with-alsaconfdir="/usr/etc/alsa/conf.d" \
		--enable-upower \
		${BLUEZ_ALSA_EXTRA_PARAMS}


    [ $? -eq 0 ] || exit $?;
    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Make Bluez-alsa..."

    chrt -i 0 make  -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Deploy Bluez-alsa..."

    make install DESTDIR=${R}
    [ $? -eq 0 ] || exit $?;

    mkdir -p ${R}/usr/var/lib/bluealsa

# begin chroot section
    if [ "${BLUEZ_ALSA_WITH_USER}" = yes ] ; then
	chroot_exec addgroup -S bluealsa
	chroot_exec adduser -S -G bluealsa -H bluealsa
	chroot_exec adduser bluealsa bluetooth

	chroot_exec addgroup -S bluealsa_aplay
	chroot_exec adduser -S -G bluealsa_aplay -H bluealsa_aplay
	chroot_exec adduser bluealsa_aplay audio

	chroot_exec chown bluealsa /usr/var/lib/bluealsa
	chroot_exec chmod 0700 /usr/var/lib/bluealsa
    fi
# end chroot section

    install_exec ${FILES_DIR}/init/optional/S72bluealsa  ${ETC_DIR}/init.d/

    cat << EOF > ${ETC_DIR}/default/bluealsa
BLUEALSA_ARGS="-S -p a2dp-source -p hsp-ag -p hfp-ag --initial-volume=50"
EOF
    chmod 644 ${ETC_DIR}/default/bluealsa

    echo "${SOURCE_NAME}: Done."
}


#
# ############ install packages ##############
#

if [ "${ENABLE_BTH}" = yes ] ; then
    echo -n -e "\n*** Build Settings ***\n"

    [[ ${CLEAN} =~ (^|,)bluetooth(,|$) ]] && BTH_FORCE_REBUILD=yes
    set -x
    BTH_FORCE_REBUILD=${BTH_FORCE_REBUILD:="no"}
    set +x

    PKG_FORCE_CLEAN=${BTH_FORCE_REBUILD}

    echo "${SOURCE_NAME}: Install Bluetooth packages..."

    libical_install

    libsbc_install

    bluez_install

    if [ "${ENABLE_SOUND}" = yes ] ; then
	libmd_install
	libbsd_install

	bluez_alsa_install
    fi

    echo "${SOURCE_NAME}: Bluetooth packages installed."
    unset PKG_FORCE_CLEAN
fi
