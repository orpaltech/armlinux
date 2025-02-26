#
# Install some of major linux utilities
#

LINUXUTIL_REPO_URL="https://git.kernel.org/pub/scm/utils/util-linux/util-linux.git"
LINUXUTIL_VERSION=2.40.4
LINUXUTIL_BRANCH=master
LINUXUTIL_TAG=
LINUXUTIL_SRC_DIR=${EXTRADIR}/util-linux
LINUXUTIL_BUILD_DIR=${LINUXUTIL_SRC_DIR}/${BB_BUILD_OUT}
LINUXUTIL_REBUILD=yes


FSPROGS_REPO_URL="https://git.kernel.org/pub/scm/fs/ext2/e2fsprogs.git"
FSPROGS_VERSION=1.47.2
FSPROGS_BRANCH=master
FSPROGS_TAG="v${FSPROGS_VERSION}"
FSPROGS_SRC_DIR=${EXTRADIR}/e2fsprogs
FSPROGS_BUILD_DIR=${FSPROGS_SRC_DIR}/${BB_BUILD_OUT}
FSPROGS_REBUILD=yes

SOURCE_NAME=$(basename ${BASH_SOURCE[0]})


#
# ############ helper functions ##############
#

e2fsprogs_install()
{
    update_src_pkg "e2fsprogs" \
                    $FSPROGS_VERSION \
                    $FSPROGS_SRC_DIR \
                    $FSPROGS_REPO_URL \
                    $FSPROGS_BRANCH \
                    $FSPROGS_TAG

    if [ "${FSPROGS_REBUILD}" = yes ] ; then
        rm -rf ${FSPROGS_BUILD_DIR}
    fi

    mkdir -p ${FSPROGS_BUILD_DIR}
    cd ${FSPROGS_BUILD_DIR}/


    echo "${SOURCE_NAME}: Configure e2fsprogs ..."

    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    CFLAGS="-I${R}/usr/include" \
    LDFLAGS="-L${R}/usr/lib" \
    MAKEINFO=/bin/true \
        ../configure \
                --srcdir=${FSPROGS_SRC_DIR} \
                --host=${BB_PLATFORM} \
                --prefix=/usr \
		--disable-fuse2fs  --disable-defrag  --disable-imager  --disable-debugfs --disable-nls --disable-uuidd

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Making e2fsprogs ..."

    chrt -i 0 make -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Install e2fsprogs to ${R} ..."

    make  install DESTDIR="${R}"
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."

}

util_linux_install()
{
    update_src_pkg "util-linux" \
                    $LINUXUTIL_VERSION \
                    $LINUXUTIL_SRC_DIR \
                    $LINUXUTIL_REPO_URL \
                    $LINUXUTIL_BRANCH \
                    $LINUXUTIL_TAG

    if [ "${LINUXUTIL_REBUILD}" = yes ] ; then
        rm -rf ${LINUXUTIL_BUILD_DIR}
    fi

    cd ${LINUXUTIL_SRC_DIR}/
    ./autogen.sh

    mkdir -p ${LINUXUTIL_BUILD_DIR}
    cd ${LINUXUTIL_BUILD_DIR}/


    echo "${SOURCE_NAME}: Configure util-linux ..."


    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    CFLAGS="-I${R}/usr/include" \
    LDFLAGS="-L${R}/usr/lib" \
    MAKEINFO=/bin/true \
        ../configure \
                --srcdir=${LINUXUTIL_SRC_DIR} \
                --host=${BB_PLATFORM} \
                --prefix=/usr \
		--with-sysroot=${R} \
		--disable-widechar	--without-ncursesw \
		--disable-all-programs \
		--enable-fdisks	--enable-libfdisk	--enable-libuuid \
		--enable-lsblk	--enable-blkid		--enable-partx	--enable-libblkid \
		--enable-libmount	--enable-libsmartcols

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Making util-linux ..."

    chrt -i 0 make -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Install util-linux to ${R} ..."

    make  install DESTDIR="${R}"
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
}


#
# ############ install packages ##############
#

util_linux_install

e2fsprogs_install
