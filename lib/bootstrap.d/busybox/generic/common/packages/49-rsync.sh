RSYNC_REPO_URL="https://github.com/RsyncProject/rsync.git"
RSYNC_VERSION=3.4.1
RSYNC_BRANCH=master
RSYNC_TAG="v${RSYNC_VERSION}"
RSYNC_SRC_DIR=${EXTRADIR}/rsync
RSYNC_BUILD_DIR=${RSYNC_SRC_DIR}/${BB_BUILD_OUT}
RSYNC_FORCE_REBUILD=yes

rsync_install()
{
    local PKG_NAME=${1:-"rsync"}

    # build rsync
    PKG_FORCE_CLEAN="${RSYNC_FORCE_REBUILD}"
	update_src_pkg "${PKG_NAME}" \
                    $RSYNC_VERSION \
                    $RSYNC_SRC_DIR \
                    $RSYNC_REPO_URL \
                    $RSYNC_BRANCH \
                    $RSYNC_TAG

    if [ "${RSYNC_FORCE_REBUILD}" = yes ] ; then
        rm -rf ${RSYNC_BUILD_DIR}
    fi

    mkdir -p ${RSYNC_BUILD_DIR}
    cd ${RSYNC_BUILD_DIR}/

    echo "${SOURCE_NAME}: Configure ${PKG_NAME} ..."

    CFLAGS="-I${R}/usr/include" \
    LDFLAGS="-L${R}/usr/lib" \
    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    MAKEINFO=/bin/true \
        ../configure \
		--srcdir=${RSYNC_SRC_DIR} \
		--host=${BB_PLATFORM} \
		--prefix=/usr \
		--disable-md2man --disable-xxhash


    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Making ${PKG_NAME} ..."

    chrt -i 0 make -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Install ${PKG_NAME} to ${R} ..."

    make  install DESTDIR=${R}
    [ $? -eq 0 ] || exit $?

    echo "${SOURCE_NAME}: Done."
}
