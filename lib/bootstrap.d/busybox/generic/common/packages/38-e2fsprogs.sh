#
# Install filesystem utilities
#

E2FSPROGS_REPO_URL="https://git.kernel.org/pub/scm/fs/ext2/e2fsprogs.git"
E2FSPROGS_VERSION=1.47.2
E2FSPROGS_BRANCH=master
E2FSPROGS_TAG="v${E2FSPROGS_VERSION}"
E2FSPROGS_SRC_DIR=${EXTRADIR}/e2fsprogs
E2FSPROGS_BUILD_DIR=${E2FSPROGS_SRC_DIR}/${BB_BUILD_OUT}
E2FSPROGS_REBUILD=yes


SOURCE_NAME=$(basename ${BASH_SOURCE[0]})


#
# ############ helper functions ##############
#

e2fsprogs_install()
{
    local PKG_NAME=${1:-"e2fsprogs"}

    PKG_FORCE_CLEAN="${E2FSPROGS_REBUILD}" \
	update_src_pkg "e2fsprogs" \
                    $E2FSPROGS_VERSION \
                    $E2FSPROGS_SRC_DIR \
                    $E2FSPROGS_REPO_URL \
                    $E2FSPROGS_BRANCH \
                    $E2FSPROGS_TAG

    if [ "${E2FSPROGS_REBUILD}" = yes ] ; then
        rm -rf ${E2FSPROGS_BUILD_DIR}
    fi

    mkdir -p ${E2FSPROGS_BUILD_DIR}
    cd ${E2FSPROGS_BUILD_DIR}/


    echo "${SOURCE_NAME}: Configure ${PKG_NAME} ..."

    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    CFLAGS="-I${R}/usr/include" \
    LDFLAGS="-L${R}/usr/lib" \
    MAKEINFO=/bin/true \
        ../configure \
                --srcdir=${E2FSPROGS_SRC_DIR} \
                --host=${BB_PLATFORM} \
                --prefix=/usr \
		--disable-fuse2fs  --disable-defrag  --disable-imager  --disable-debugfs --disable-nls --disable-uuidd

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Making ${PKG_NAME} ..."

    chrt -i 0 make -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Install ${PKG_NAME} to ${R} ..."

    make  install DESTDIR="${R}"
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."

}
