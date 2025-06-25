LZ4_REPO_URL="https://github.com/lz4/lz4.git"
LZ4_VERSION=1.10.0
LZ4_BRANCH=dev
LZ4_TAG="v${LZ4_VERSION}"
LZ4_SRC_DIR=${EXTRADIR}/lz4
LZ4_BUILD_DIR=${LZ4_SRC_DIR}/${BB_BUILD_OUT}
LZ4_FORCE_REBUILD=yes

lz4_install()
{
    local PKG_NAME=${1:-"lz4"}

    # build lz4
    PKG_FORCE_CLEAN="${LZ4_FORCE_REBUILD}"
	update_src_pkg "${PKG_NAME}" \
                    $LZ4_VERSION \
                    $LZ4_SRC_DIR \
                    $LZ4_REPO_URL \
                    $LZ4_BRANCH \
                    $LZ4_TAG

    if [ "${LZ4_FORCE_REBUILD}" = yes ] ; then
        rm -rf ${LZ4_BUILD_DIR}
    fi

    mkdir -p ${LZ4_BUILD_DIR}
    cd ${LZ4_SRC_DIR}/build/meson

    meson_cross_init "${LZ4_BUILD_DIR}/${MESON_CROSSFILE}"

    echo "${SOURCE_NAME}: Configure ${PKG_NAME} ..."

    ${MESON_PY} setup ${LZ4_BUILD_DIR}/ \
                --cross-file="${LZ4_BUILD_DIR}/${MESON_CROSSFILE}" \
                --prefix=/usr \
                --errorlogs

    [ $? -eq 0 ] || exit 1

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Making ${PKG_NAME} ..."

    ${MESON_PY} compile -C ${LZ4_BUILD_DIR}/
    [ $? -eq 0 ] || exit 1

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Install ${PKG_NAME} to ${R} ..."

    DESTDIR="${R}" \
        ${MESON_PY} install -C ${LZ4_BUILD_DIR}/
    [ $? -eq 0 ] || exit 1

    echo "${SOURCE_NAME}: Done."
}
