#
# Install ntp package
#

NTP_REPO_URL="https://github.com/ntp-project/ntp.git"
NTP_VERSION=4_2_8P18
NTP_BRANCH=stable
NTP_TAG="NTP_${NTP_VERSION}"
NTP_SRC_DIR=${EXTRADIR}/ntp
NTP_BUILD_DIR=${NTP_SRC_DIR}/${BB_BUILD_OUT}
NTP_REBUILD=yes

SOURCE_NAME=$(basename ${BASH_SOURCE[0]})

#
# ############ helper functions ##############
#

ntp_install()
{
    PKG_FORCE_CLEAN=${NTP_REBUILD} \
	update_src_pkg "ntp" \
                    $NTP_VERSION \
                    $NTP_SRC_DIR \
                    $NTP_REPO_URL \
                    $NTP_BRANCH \
                    $NTP_TAG

    if [ "${NTP_REBUILD}" = yes ] ; then
        rm -rf ${NTP_BUILD_DIR}
    fi

    cd ${NTP_SRC_DIR}/
    ./bootstrap

    mkdir -p ${NTP_BUILD_DIR}
    cd ${NTP_BUILD_DIR}/

    echo "${SOURCE_NAME}: Configure ntp ..."

    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    CFLAGS="-I${R}/usr/include" \
    LDFLAGS="-L${R}/usr/lib" \
    MAKEINFO=/bin/true \
        ../configure \
                --srcdir=${NTP_SRC_DIR} \
                --host=${BB_PLATFORM} \
		--with-sysroot=${TOOLCHAIN_SYSROOT} \
                --prefix=/usr \
		--with-shared \
		--program-transform-name=s,,, \
		--disable-tickadj \
		--disable-debugging \
		--with-yielding-select=yes \
		--disable-local-libevent

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Making ntp ..."

    chrt -i 0 make -s  -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Install ntp to ${R} ..."

    make  install DESTDIR="${NTP_BUILD_DIR}/dist"
    [ $? -eq 0 ] || exit $?;

    install_exec ${NTP_BUILD_DIR}/dist/usr/bin/sntp	${USR_DIR}/bin/
    install_exec ${NTP_BUILD_DIR}/dist/usr/bin/ntpd	${USR_DIR}/bin/
    install_readonly ${FILES_DIR}/etc/ntp.conf	${ETC_DIR}/

    install_exec ${FILES_DIR}/init/optional/S48sntp	${ETC_DIR}/init.d/
    install_exec ${FILES_DIR}/init/optional/S49ntp	${ETC_DIR}/init.d/

    echo "${SOURCE_NAME}: Done."
}


#
# ############ install packages ##############
#

if [ "${ENABLE_NTP}" = yes  ] ; then

    ntp_install
fi
