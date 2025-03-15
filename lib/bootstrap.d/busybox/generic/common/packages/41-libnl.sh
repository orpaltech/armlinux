LIBNL_REPO_URL="https://github.com/thom311/libnl.git"
LIBNL_VERSION=3_11_0
LIBNL_BRANCH=main
LIBNL_TAG="libnl${LIBNL_VERSION}"
LIBNL_SRC_DIR=${EXTRADIR}/libnl
LIBNL_BUILD_DIR=${LIBNL_SRC_DIR}/${BB_BUILD_OUT}
LIBNL_REBUILD=yes


libnl_install()
{
    local PKG_NAME=${1:-"libnl"}

    # build libnl
    PKG_FORCE_CLEAN="${LIBNL_REBUILD}" \
	update_src_pkg "libnl" \
                    $LIBNL_VERSION \
                    $LIBNL_SRC_DIR \
                    $LIBNL_REPO_URL \
                    $LIBNL_BRANCH \
                    $LIBNL_TAG

    if [ "${LIBNL_REBUILD}" = yes ] ; then
        rm -rf ${LIBNL_BUILD_DIR}
    fi

    cd ${LIBNL_SRC_DIR}/
    ./autogen.sh

    mkdir -p ${LIBNL_BUILD_DIR}
    cd ${LIBNL_BUILD_DIR}/

    echo "${SOURCE_NAME}: Configure ${PKG_NAME} ..."

    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    MAKEINFO=/bin/true \
        ../configure --host=${BB_PLATFORM} \
                --srcdir=${LIBNL_SRC_DIR} \
                --prefix=/usr \
		--enable-shared --disable-static

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
