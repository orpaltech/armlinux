GLIB_REPO_URL="https://gitlab.gnome.org/GNOME/glib.git"
GLIB_VERSION=2.83.3
GLIB_BRANCH=main
GLIB_TAG=${GLIB_VERSION}
GLIB_SRC_DIR=${EXTRADIR}/glib
GLIB_BUILD_DIR=${GLIB_SRC_DIR}/${BB_BUILD_OUT}
GLIB_REBUILD=yes
GLIB_LIBC=gnu


glib_install()
{
    local PKG_NAME=${1:-"glib"}

    # build GLib
    local PKG_FORCE_CLEAN="${GLIB_REBUILD}"

    update_src_pkg "GNOME/${PKG_NAME}" \
                    $GLIB_VERSION \
                    $GLIB_SRC_DIR \
                    $GLIB_REPO_URL \
                    $GLIB_BRANCH \
                    $GLIB_TAG

    if [ "${GLIB_REBUILD}" = yes ] ; then
        rm -rf ${GLIB_BUILD_DIR}
    fi

    mkdir -p ${GLIB_BUILD_DIR}
    cd ${GLIB_SRC_DIR}/

    meson_cross_init "${GLIB_BUILD_DIR}/${MESON_CROSSFILE}"

    echo "${SOURCE_NAME}: Configure ${PKG_NAME} ..."

    ${MESON_PY} setup ${GLIB_BUILD_DIR}/ \
                --cross-file="${GLIB_BUILD_DIR}/${MESON_CROSSFILE}" \
                --prefix=/usr \
                --errorlogs \
                -Dnls=disabled \
                -Dmultiarch=true \
                -Dman-pages=disabled \
                -Dinstalled_tests=false -Dtests=false -Ddocumentation=false

    [ $? -eq 0 ] || exit 1

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Making ${PKG_NAME} ..."

    ${MESON_PY} compile -C ${GLIB_BUILD_DIR}/
    [ $? -eq 0 ] || exit 1

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Install ${PKG_NAME} to ${R} ..."

    DESTDIR="${R}" \
        ${MESON_PY} install -C ${GLIB_BUILD_DIR}/
    [ $? -eq 0 ] || exit 1

    echo "${SOURCE_NAME}: Done."
}
