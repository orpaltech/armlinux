FREETYPE_REPO_URL="https://gitlab.freedesktop.org/freetype/freetype.git"
FREETYPE_VERSION=2-13-3
FREETYPE_BRANCH=master
FREETYPE_TAG="VER-${FREETYPE_VERSION}"
FREETYPE_SRC_DIR=${EXTRADIR}/freetype
FREETYPE_BUILD_DIR=${FREETYPE_SRC_DIR}/${BB_BUILD_OUT}
FREETYPE_REBUILD=yes


freetype_install()
{
    local PKG_NAME=${1:-"freetype"}

    # build freetype
    PKG_FORCE_CLEAN="${FREETYPE_REBUILD}" \
	update_src_pkg "${PKG_NAME}" \
                    $FREETYPE_VERSION \
                    $FREETYPE_SRC_DIR \
                    $FREETYPE_REPO_URL \
                    $FREETYPE_BRANCH \
                    $FREETYPE_TAG

    if [ "${FREETYPE_REBUILD}" = yes ] ; then
        rm -rf ${FREETYPE_BUILD_DIR}
    fi

    mkdir -p ${FREETYPE_BUILD_DIR}
    cd ${FREETYPE_SRC_DIR}/

    meson_cross_init "${FREETYPE_BUILD_DIR}/${MESON_CROSSFILE}"

    echo "${SOURCE_NAME}: Configure ${PKG_NAME} ..."

    ${MESON_PY} setup ${FREETYPE_BUILD_DIR}/ \
		--cross-file="${FREETYPE_BUILD_DIR}/${MESON_CROSSFILE}" \
		--prefix=/usr \
		--errorlogs \
		-Dzlib=system
    [ $? -eq 0 ] || exit $?

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Making ${PKG_NAME} ..."

    ${MESON_PY} compile -C ${FREETYPE_BUILD_DIR}/
    [ $? -eq 0 ] || exit $?

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Install ${PKG_NAME} to ${R} ..."

    DESTDIR="${R}" \
        ${MESON_PY} install -C ${FREETYPE_BUILD_DIR}/
    [ $? -eq 0 ] || exit $?

    echo "${SOURCE_NAME}: Done."
}
