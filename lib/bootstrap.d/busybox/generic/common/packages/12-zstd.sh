ZSTD_REPO_URL="https://github.com/facebook/zstd.git"
ZSTD_VERSION=1.5.7
ZSTD_BRANCH=dev
ZSTD_TAG="v${ZSTD_VERSION}"
ZSTD_SRC_DIR=${EXTRADIR}/zstd
ZSTD_BUILD_DIR=${ZSTD_SRC_DIR}/${BB_BUILD_OUT}
ZSTD_FORCE_REBUILD=yes

zstd_install()
{
    local PKG_NAME=${1:-"zstd"}

    # build zstd
    PKG_FORCE_CLEAN="${ZSTD_FORCE_REBUILD}"
	update_src_pkg "${PKG_NAME}" \
                    $ZSTD_VERSION \
                    $ZSTD_SRC_DIR \
                    $ZSTD_REPO_URL \
                    $ZSTD_BRANCH \
                    $ZSTD_TAG

    if [ "${ZSTD_FORCE_REBUILD}" = yes ] ; then
        rm -rf ${ZSTD_BUILD_DIR}
    fi

    mkdir -p ${ZSTD_BUILD_DIR}
    cd ${ZSTD_SRC_DIR}/build/meson

    meson_cross_init "${ZSTD_BUILD_DIR}/${MESON_CROSSFILE}"

    echo "${SOURCE_NAME}: Configure ${PKG_NAME} ..."

    ${MESON_PY} setup ${ZSTD_BUILD_DIR}/ \
                --cross-file="${ZSTD_BUILD_DIR}/${MESON_CROSSFILE}" \
                --prefix=/usr \
                --errorlogs

    [ $? -eq 0 ] || exit 1

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Making ${PKG_NAME} ..."

    ${MESON_PY} compile -C ${ZSTD_BUILD_DIR}/
    [ $? -eq 0 ] || exit 1

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Install ${PKG_NAME} to ${R} ..."

    DESTDIR="${R}" \
        ${MESON_PY} install -C ${ZSTD_BUILD_DIR}/
    [ $? -eq 0 ] || exit 1

    echo "${SOURCE_NAME}: Done."
}
