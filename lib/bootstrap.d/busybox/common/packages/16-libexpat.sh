EXPAT_REPO_URL="https://github.com/libexpat/libexpat.git"
EXPAT_VERSION=2_6_4
EXPAT_BRANCH=master
EXPAT_TAG="R_${EXPAT_VERSION}"
EXPAT_SRC_DIR=${EXTRADIR}/libexpat
EXPAT_BUILD_DIR=${EXPAT_SRC_DIR}/expat/${BB_BUILD_OUT}
EXPAT_REBUILD=yes


libexpat_install()
{
    local PKG_NAME=${1:-"libexpat"}

    # build EXPAT library
    local PKG_FORCE_CLEAN="${EXPAT_REBUILD}"

    update_src_pkg "${PKG_NAME}" \
                    $EXPAT_VERSION \
                    $EXPAT_SRC_DIR \
                    $EXPAT_REPO_URL \
                    $EXPAT_BRANCH \
                    $EXPAT_TAG

    if [ "${EXPAT_REBUILD}" = yes ] ; then
        rm -rf ${EXPAT_BUILD_DIR}
    fi

    cd ${EXPAT_SRC_DIR}/expat
    ./buildconf.sh

    mkdir -p ${EXPAT_BUILD_DIR}
    cd ${EXPAT_BUILD_DIR}/


    echo "${SOURCE_NAME}: Configure ${PKG_NAME} ..."

    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
        ../configure \
                --srcdir=${EXPAT_SRC_DIR}/expat \
                --host=${BB_PLATFORM} \
                --prefix=/usr \
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
