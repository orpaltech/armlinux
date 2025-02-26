PKGCONFIG_REPO_URL="https://gitlab.freedesktop.org/pkg-config/pkg-config.git"
PKGCONFIG_VERSION=0.29.2
PKGCONFIG_BRANCH=master
PKGCONFIG_TAG="pkg-config-${PKGCONFIG_VERSION}"
PKGCONFIG_SRC_DIR=${EXTRADIR}/pkg-config
PKGCONFIG_BUILD_DIR=${PKGCONFIG_SRC_DIR}/${BB_BUILD_OUT}
PKGCONFIG_REBUILD=yes
PKGCONFIG_LIBC=gnu


pkgconfig_install()
{
    local PKG_NAME=${1:-"pkgconfig"}

    # build pkg-config
    local PKG_FORCE_CLEAN="${PKGCONFIG_REBUILD}"

    update_src_pkg "${PKG_NAME}" \
                $PKGCONFIG_VERSION \
                $PKGCONFIG_SRC_DIR \
                $PKGCONFIG_REPO_URL \
                $PKGCONFIG_BRANCH \
                $PKGCONFIG_TAG

    cd ${PKGCONFIG_SRC_DIR}/
    # Remove internal glib, otherwise autogen.sh will fail
    rm -rf ./glib/*
    autoreconf --install


    echo "${SOURCE_NAME}: Configure ${PKG_NAME} ..."

    PKG_CONFIG=${BB_PKG_CONFIG} \
    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    MAKEINFO=/bin/true \
        ./configure --host=${BB_PLATFORM} --prefix=/usr

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Making ${PKG_NAME} ..."

    chrt -i 0 make  -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Install ${PKG_NAME} to ${R} ..."

    make  install DESTDIR=${R}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."

}
