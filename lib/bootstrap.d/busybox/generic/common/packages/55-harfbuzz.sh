HARFBUZZ_REPO_URL="https://github.com/harfbuzz/harfbuzz.git"
HARFBUZZ_VERSION=11.2.1
HARFBUZZ_BRANCH=main
HARFBUZZ_TAG="${HARFBUZZ_VERSION}"
HARFBUZZ_SRC_DIR=${EXTRADIR}/harfbuzz
HARFBUZZ_BUILD_DIR=${HARFBUZZ_SRC_DIR}/${BB_BUILD_OUT}
HARFBUZZ_REBUILD=yes


harfbuzz_install()
{
    local PKG_NAME=${1:-"harfbuzz"}

    # build harfbuzz
    PKG_FORCE_CLEAN="${HARFBUZZ_REBUILD}" \
        update_src_pkg "${PKG_NAME}" \
                    $HARFBUZZ_VERSION \
                    $HARFBUZZ_SRC_DIR \
                    $HARFBUZZ_REPO_URL \
                    $HARFBUZZ_BRANCH \
                    $HARFBUZZ_TAG

    if [ "${HARFBUZZ_REBUILD}" = yes ] ; then
        rm -rf ${HARFBUZZ_BUILD_DIR}
    fi

    mkdir -p ${HARFBUZZ_BUILD_DIR}
    cd ${HARFBUZZ_SRC_DIR}/

    meson_cross_init "${HARFBUZZ_BUILD_DIR}/${MESON_CROSSFILE}"

    echo "${SOURCE_NAME}: Configure ${PKG_NAME} ..."

    ${MESON_PY} setup ${HARFBUZZ_BUILD_DIR}/ \
                --cross-file="${HARFBUZZ_BUILD_DIR}/${MESON_CROSSFILE}" \
                --prefix=/usr \
                --errorlogs \
                -Dtests=disabled \
		-Ddocs=disabled -Ddoc_tests=false
    [ $? -eq 0 ] || exit $?

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Making ${PKG_NAME} ..."

    ${MESON_PY} compile -C ${HARFBUZZ_BUILD_DIR}/
    [ $? -eq 0 ] || exit $?

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Install ${PKG_NAME} to ${R} ..."

    DESTDIR="${R}" \
        ${MESON_PY} install -C ${HARFBUZZ_BUILD_DIR}/
    [ $? -eq 0 ] || exit $?

    echo "${SOURCE_NAME}: Done."
}
