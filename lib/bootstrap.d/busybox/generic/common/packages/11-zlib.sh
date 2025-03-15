ZLIB_REPO_URL="https://github.com/madler/zlib.git"
ZLIB_VERSION=1.3.1
ZLIB_BRANCH=develop
ZLIB_TAG="v${ZLIB_VERSION}"
ZLIB_SRC_DIR=${EXTRADIR}/zlib
ZLIB_BUILD_DIR=${ZLIB_SRC_DIR}/${BB_BUILD_OUT}
ZLIB_REBUILD=yes

zlib_install()
{
    local PKG_NAME=${1:-"zlib"}

    # build zlib
    local PKG_FORCE_CLEAN="${ZLIB_REBUILD}"

    update_src_pkg "${PKG_NAME}" \
                    $ZLIB_VERSION \
                    $ZLIB_SRC_DIR \
                    $ZLIB_REPO_URL \
                    $ZLIB_BRANCH \
                    $ZLIB_TAG

    if [ "${ZLIB_REBUILD}" = yes ] ; then
        rm -rf ${ZLIB_BUILD_DIR}
    fi

    mkdir -p ${ZLIB_BUILD_DIR}
    cd ${ZLIB_BUILD_DIR}/

    echo "${SOURCE_NAME}: Configure ${PKG_NAME} ..."

    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    MAKEINFO=/bin/true \
        ../configure --prefix=/usr

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Making ${PKG_NAME} ..."

    chrt -i 0 make -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Install ${PKG_NAME} to ${R} ..."

    make  install DESTDIR=${R}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
}
