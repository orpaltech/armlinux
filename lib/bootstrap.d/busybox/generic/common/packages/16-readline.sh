READLINE_REPO_URL="https://git.savannah.gnu.org/git/readline.git"
READLINE_VERSION=8.2
READLINE_BRANCH=master
READLINE_TAG=
READLINE_SRC_DIR=${EXTRADIR}/readline
READLINE_BUILD_DIR=${READLINE_SRC_DIR}/${BB_BUILD_OUT}
READLINE_REBUILD=yes


readline_install()
{
    local PKG_NAME=${1:-"readline"}

    # build readline
    PKG_FORCE_CLEAN="${READLINE_REBUILD}" \
	update_src_pkg "${PKG_NAME}" \
                    $READLINE_VERSION \
                    $READLINE_SRC_DIR \
                    $READLINE_REPO_URL \
                    $READLINE_BRANCH \
                    $READLINE_TAG

    if [ "${READLINE_REBUILD}" = yes ] ; then
        rm -rf ${READLINE_BUILD_DIR}
    fi

    mkdir -p ${READLINE_BUILD_DIR}
    cd ${READLINE_BUILD_DIR}/

    echo "${SOURCE_NAME}: Configure ${PKG_NAME} ..."

    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    CFLAGS="-I${R}/usr/include" \
    LDFLAGS="-L${R}/usr/lib" \
    MAKEINFO=/bin/true \
        ../configure \
                --host=${BB_PLATFORM} \
                --srcdir=${READLINE_SRC_DIR} \
                --prefix=/usr \
		--enable-shared --disable-static \
                --with-shared-termcap-library \
                --disable-install-examples

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
