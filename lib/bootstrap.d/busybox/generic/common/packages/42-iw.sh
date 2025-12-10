IW_REPO_URL="https://kernel.googlesource.com/pub/scm/linux/kernel/git/jberg/iw"
#https://git.kernel.org/pub/scm/linux/kernel/git/jberg/iw.git"
IW_VERSION=6.9
IW_BRANCH=master
IW_TAG=v${IW_VERSION}
IW_SRC_DIR=${EXTRADIR}/jberg_iw
IW_BUILD_DIR=${IW_SRC_DIR}/${BB_BUILD_OUT}
IW_CONDITION="ENABLE_WLAN"
IW_REBUILD=yes


iw_install()
{
    local PKG_NAME=${1:-"iw"}

    # build iw
    PKG_FORCE_CLEAN="${IW_REBUILD}" \
	update_src_pkg "jberg-iw" \
                    $IW_VERSION \
                    $IW_SRC_DIR \
                    $IW_REPO_URL \
                    $IW_BRANCH \
                    $IW_TAG

    cd ${IW_SRC_DIR}/

    export PKG_CONFIG=${BB_PKG_CONFIG}
    export CC=${BB_GCC}
    export CFLAGS="-I${R}/usr/include/libnl3"
    export LDFLAGS="-L${R}/usr/lib"

    echo "${SOURCE_NAME}: Making ${PKG_NAME} ..."

    chrt -i 0 make  -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Install ${PKG_NAME} to ${R} ..."

    make  install DESTDIR=${R}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    unset PKG_CONFIG CC CFLAGS LDFLAGS
}
