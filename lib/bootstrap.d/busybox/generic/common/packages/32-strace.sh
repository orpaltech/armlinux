STRACE_REPO_URL="https://github.com/strace/strace.git"
STRACE_VERSION=6.17
STRACE_BRANCH=master
STRACE_TAG="v${STRACE_VERSION}"
STRACE_SRC_DIR=${EXTRADIR}/strace
STRACE_BUILD_DIR=${STRACE_SRC_DIR}/${BB_BUILD_OUT}
STRACE_REBUILD=yes

strace_install()
{
    local PKG_NAME=${1:-"strace"}

    # build strace
    local PKG_FORCE_CLEAN="${STRACE_REBUILD}"

    update_src_pkg "${PKG_NAME}" \
                    $STRACE_VERSION \
                    $STRACE_SRC_DIR \
                    $STRACE_REPO_URL \
                    $STRACE_BRANCH \
                    $STRACE_TAG

    if [ "${STRACE_REBUILD}" = yes ] ; then
        rm -rf ${STRACE_BUILD_DIR}
    fi

    cd ${STRACE_SRC_DIR}/
    ./bootstrap

    mkdir -p ${STRACE_BUILD_DIR}
    cd ${STRACE_BUILD_DIR}/

    echo "${SOURCE_NAME}: Configure ${PKG_NAME} ..."

    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    MAKEINFO=/bin/true \
        ../configure --host=${BB_PLATFORM} \
		--srcdir=${STRACE_SRC_DIR} \
		--prefix=/usr

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
