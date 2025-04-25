LIBXML2_REPO_URL="https://gitlab.gnome.org/GNOME/libxml2.git"
LIBXML2_VERSION=2.13.8
LIBXML2_BRANCH=master
LIBXML2_TAG=
#"v${LIBXML2_VERSION}"
LIBXML2_SRC_DIR=${EXTRADIR}/libxml2
LIBXML2_BUILD_DIR=${LIBXML2_SRC_DIR}/${BB_BUILD_OUT}
LIBXML2_REBUILD=yes
LIBXML2_LIBC=gnu


libxml2_install()
{
    local PKG_NAME=${1:-"libxml2"}

    # build libxml2
    local PKG_FORCE_CLEAN="${LIBXML2_REBUILD}"

    update_src_pkg "GNOME/${PKG_NAME}" \
                    $LIBXML2_VERSION \
                    $LIBXML2_SRC_DIR \
                    $LIBXML2_REPO_URL \
                    $LIBXML2_BRANCH \
                    $LIBXML2_TAG

    if [ "${LIBXML2_REBUILD}" = yes ] ; then
        rm -rf ${LIBXML2_BUILD_DIR}
    fi

    mkdir -p ${LIBXML2_BUILD_DIR}
    cd ${LIBXML2_SRC_DIR}/

    meson_cross_init "${LIBXML2_BUILD_DIR}/${MESON_CROSSFILE}"

    echo "${SOURCE_NAME}: Configure ${PKG_NAME} ..."

    ${MESON_PY} setup ${LIBXML2_BUILD_DIR}/ \
                --cross-file="${LIBXML2_BUILD_DIR}/${MESON_CROSSFILE}" \
                --prefix=/usr \
                --errorlogs \
                -Dminimum=false \
		-Dzlib=enabled \
		-Dpython=disabled

    [ $? -eq 0 ] || exit 1

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Making ${PKG_NAME} ..."

    ${MESON_PY} compile -C ${LIBXML2_BUILD_DIR}/
    [ $? -eq 0 ] || exit 1

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Install ${PKG_NAME} to ${R} ..."

    DESTDIR="${R}" \
        ${MESON_PY} install -C ${LIBXML2_BUILD_DIR}/
    [ $? -eq 0 ] || exit 1

    echo "${SOURCE_NAME}: Done."
}
