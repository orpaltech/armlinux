SYSKLOGD_REPO_URL="https://github.com/troglobit/sysklogd.git"
SYSKLOGD_VERSION=2.7.2
SYSKLOGD_BRANCH=master
SYSKLOGD_TAG="v${SYSKLOGD_VERSION}"
SYSKLOGD_SRC_DIR=${EXTRADIR}/sysklogd
SYSKLOGD_BUILD_DIR=${SYSKLOGD_SRC_DIR}/${BB_BUILD_OUT}
SYSKLOGD_REBUILD=yes


sysklogd_install()
{
    local PKG_NAME=${1:-"sysklogd"}

    # build sysklogd
    PKG_FORCE_CLEAN="${SYSKLOGD_REBUILD}" \
	update_src_pkg "${PKG_NAME}" \
                    $SYSKLOGD_VERSION \
                    $SYSKLOGD_SRC_DIR \
                    $SYSKLOGD_REPO_URL \
                    $SYSKLOGD_BRANCH \
                    $SYSKLOGD_TAG

    if [ "${SYSKLOGD_REBUILD}" = yes ] ; then
        rm -rf ${SYSKLOGD_BUILD_DIR}
    fi

    cd ${SYSKLOGD_SRC_DIR}/
    ./autogen.sh

    mkdir -p ${SYSKLOGD_BUILD_DIR}
    cd ${SYSKLOGD_BUILD_DIR}/


    echo "${SOURCE_NAME}: Configure ${PKG_NAME} ..."

    PKG_CONFIG=${BB_PKG_CONFIG} \
    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    MAKEINFO=/bin/true \
        ../configure \
                --srcdir=${SYSKLOG_SRC_DIR} \
                --host=${BB_PLATFORM} \
                --without-systemd \
                --prefix=/usr --sysconfdir=/etc --runstatedir=/run

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Making ${PKG_NAME} ..."

    chrt -i 0 make -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Install ${PKG_NAME} to ${R} ..."

    make  install DESTDIR=${R}
    [ $? -eq 0 ] || exit $?;


    install_readonly ${FILES_DIR}/etc/syslog.conf  ${ETC_DIR}/
    echo "${SOURCE_NAME}: Done."

}
