LIBEXPAT_REPO_URL="https://github.com/libexpat/libexpat.git"
LIBEXPAT_VERSION=2_7_3
LIBEXPAT_BRANCH=master
LIBEXPAT_TAG="R_${LIBEXPAT_VERSION}"
LIBEXPAT_SRC_DIR=${EXTRADIR}/libexpat
LIBEXPAT_BUILD_DIR=${LIBEXPAT_SRC_DIR}/expat/${BB_BUILD_OUT}
LIBEXPAT_REBUILD=yes


libexpat_install()
{
    local PKG_NAME=${1:-"libexpat"}

    # build EXPAT library
    PKG_FORCE_CLEAN="${LIBEXPAT_REBUILD}" \
	update_src_pkg "${PKG_NAME}" \
                    $LIBEXPAT_VERSION \
                    $LIBEXPAT_SRC_DIR \
                    $LIBEXPAT_REPO_URL \
                    $LIBEXPAT_BRANCH \
                    $LIBEXPAT_TAG

    if [ "${LIBEXPAT_REBUILD}" = yes ] ; then
        rm -rf ${LIBEXPAT_BUILD_DIR}
    fi

    cd ${LIBEXPAT_SRC_DIR}/expat
    ./buildconf.sh

    mkdir -p ${LIBEXPAT_BUILD_DIR}
    cd ${LIBEXPAT_BUILD_DIR}/


    echo "${SOURCE_NAME}: Configure ${PKG_NAME} ..."

    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
        ../configure \
                --srcdir=${LIBEXPAT_SRC_DIR}/expat \
                --host=${BB_PLATFORM} \
                --prefix=/usr \
		--enable-shared --disable-static \
                --without-tests --without-docbook

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
