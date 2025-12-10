FONTCONFIG_REPO_URL="https://gitlab.freedesktop.org/fontconfig/fontconfig.git"
FONTCONFIG_VERSION=2.17.1
FONTCONFIG_BRANCH=main
FONTCONFIG_TAG="${FONTCONFIG_VERSION}"
FONTCONFIG_SRC_DIR=${EXTRADIR}/fontconfig
FONTCONFIG_BUILD_DIR=${FONTCONFIG_SRC_DIR}/${BB_BUILD_OUT}
FONTCONFIG_REBUILD=yes


fontconfig_install()
{
    local PKG_NAME=${1:-"fontconfig"}

    # build fontconfig
    PKG_FORCE_CLEAN="${FONTCONFIG_REBUILD}" \
	update_src_pkg "${PKG_NAME}" \
                    $FONTCONFIG_VERSION \
                    $FONTCONFIG_SRC_DIR \
                    $FONTCONFIG_REPO_URL \
                    $FONTCONFIG_BRANCH \
                    $FONTCONFIG_TAG

    if [ "${FONTCONFIG_REBUILD}" = yes ] ; then
        rm -rf ${FONTCONFIG_BUILD_DIR}
    fi

    mkdir -p ${FONTCONFIG_BUILD_DIR}
    cd ${FONTCONFIG_SRC_DIR}/

    meson_cross_init "${FONTCONFIG_BUILD_DIR}/${MESON_CROSSFILE}"

    echo "${SOURCE_NAME}: Configure ${PKG_NAME} ..."

    ${MESON_PY} setup ${FONTCONFIG_BUILD_DIR}/ \
		--cross-file="${FONTCONFIG_BUILD_DIR}/${MESON_CROSSFILE}" \
		--prefix=/usr \
		--errorlogs
    [ $? -eq 0 ] || exit $?

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Making ${PKG_NAME} ..."

    ${MESON_PY} compile -C ${FONTCONFIG_BUILD_DIR}/
    [ $? -eq 0 ] || exit $?

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Install ${PKG_NAME} to ${R} ..."

    DESTDIR="${R}" \
        ${MESON_PY} install -C ${FONTCONFIG_BUILD_DIR}/
    [ $? -eq 0 ] || exit $?

    echo "${SOURCE_NAME}: Done."
}
