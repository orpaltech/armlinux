LIBUSB_REPO_URL="https://github.com/libusb/libusb.git"
LIBUSB_VERSION=1.0.28
LIBUSB_BRANCH=master
LIBUSB_TAG="v${LIBUSB_VERSION}"
LIBUSB_SRC_DIR=${EXTRADIR}/libusb
LIBUSB_BUILD_DIR=${LIBUSB_SRC_DIR}/${BB_BUILD_OUT}
LIBUSB_REBUILD=yes


libusb_install()
{
    local PKG_NAME=${1:-"libusb"}

    # build libusb library
    local PKG_FORCE_CLEAN="${LIBUSB_REBUILD}"

    update_src_pkg "${PKG_NAME}" \
                    $LIBUSB_VERSION \
                    $LIBUSB_SRC_DIR \
                    $LIBUSB_REPO_URL \
                    $LIBUSB_BRANCH \
                    $LIBUSB_TAG

    if [ "${LIBUSB_REBUILD}" = yes ] ; then
        rm -rf ${LIBUSB_BUILD_DIR}
    fi

    cd ${LIBUSB_SRC_DIR}/
    ./bootstrap.sh

    mkdir -p ${LIBUSB_BUILD_DIR}
    cd ${LIBUSB_BUILD_DIR}/


    echo "${SOURCE_NAME}: Configure ${PKG_NAME} ..."

    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
        ../configure \
                --srcdir=${LIBUSB_SRC_DIR} \
                --host=${BB_PLATFORM} \
                --prefix=/usr \
		--enable-shared --disable-static \
		--disable-udev

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Make ${PKG_NAME} ..."

    chrt -i 0 make -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Deploy ${PKG_NAME} to ${R} ..."

    make  install DESTDIR=${R}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
}
