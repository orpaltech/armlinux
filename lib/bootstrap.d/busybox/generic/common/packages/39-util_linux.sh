#
# Install linux utilities
#

UTIL_LINUX_REPO_URL="https://git.kernel.org/pub/scm/utils/util-linux/util-linux.git"
UTIL_LINUX_VERSION=2.40.4
UTIL_LINUX_BRANCH=master
UTIL_LINUX_TAG=
UTIL_LINUX_SRC_DIR=${EXTRADIR}/util-linux
UTIL_LINUX_BUILD_DIR=${UTIL_LINUX_SRC_DIR}/${BB_BUILD_OUT}
UTIL_LINUX_REBUILD=yes


SOURCE_NAME=$(basename ${BASH_SOURCE[0]})


#
# ############ helper functions ##############
#

util_linux_install()
{
    local PKG_NAME=${1:-"util-linux"}

    PKG_FORCE_CLEAN="${UTIL_LINUX_REBUILD}" \
	update_src_pkg "util-linux" \
                    $UTIL_LINUX_VERSION \
                    $UTIL_LINUX_SRC_DIR \
                    $UTIL_LINUX_REPO_URL \
                    $UTIL_LINUX_BRANCH \
                    $UTIL_LINUX_TAG

    if [ "${UTIL_LINUX_REBUILD}" = yes ] ; then
        rm -rf ${UTIL_LINUX_BUILD_DIR}
    fi

    cd ${UTIL_LINUX_SRC_DIR}/
    ./autogen.sh

    mkdir -p ${UTIL_LINUX_BUILD_DIR}
    cd ${UTIL_LINUX_BUILD_DIR}/


    echo "${SOURCE_NAME}: Configure ${PKG_NAME} ..."


    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    CFLAGS="-I${R}/usr/include" \
    LDFLAGS="-L${R}/usr/lib" \
    MAKEINFO=/bin/true \
        ../configure \
                --srcdir=${UTIL_LINUX_SRC_DIR} \
                --host=${BB_PLATFORM} \
                --prefix=/usr \
		--with-sysroot=${R} \
		--disable-widechar	--without-ncursesw \
		--disable-all-programs \
		--enable-fdisks	--enable-libfdisk	--enable-libuuid \
		--enable-lsblk	--enable-blkid		--enable-partx	--enable-libblkid \
		--enable-libmount	--enable-libsmartcols

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Make ${PKG_NAME} ..."

    chrt -i 0 make -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Install ${PKG_NAME} to ${R} ..."

    make  install DESTDIR="${R}"
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
}
