DBUS_REPO_URL="https://gitlab.freedesktop.org/dbus/dbus.git"
DBUS_VERSION=1.16.2
DBUS_BRANCH=main
DBUS_TAG="dbus-${DBUS_VERSION}"
DBUS_SRC_DIR=${EXTRADIR}/dbus
DBUS_BUILD_DIR=${DBUS_SRC_DIR}/${BB_BUILD_OUT}
DBUS_REBUILD=yes
DBUS_LIBC=gnu


dbus_install()
{
    local PKG_NAME=${1:-"dbus"}

    # build D-BUS library
    update_src_pkg "${PKG_NAME}" \
                    $DBUS_VERSION \
                    $DBUS_SRC_DIR \
                    $DBUS_REPO_URL \
                    $DBUS_BRANCH \
                    $DBUS_TAG


    if [ "${DBUS_REBUILD}" = yes ] ; then
        rm -rf ${DBUS_BUILD_DIR}
    fi

    mkdir -p ${DBUS_BUILD_DIR}
    cd ${DBUS_SRC_DIR}/

    meson_cross_init "${DBUS_BUILD_DIR}/${MESON_CROSSFILE}"

    echo "${SOURCE_NAME}: Configure ${PKG_NAME} ..."

    ${MESON_PY} setup ${DBUS_BUILD_DIR}/ \
                --cross-file="${DBUS_BUILD_DIR}/${MESON_CROSSFILE}" \
                --prefix=/usr \
                --errorlogs \
                -Dsystemd=disabled \
                -Dsession_socket_dir=/tmp \
                -Ddbus_user=dbus \
                -Dsystem_pid_file=/var/run/dbus/pid \
                -Dmodular_tests=disabled \
                -Dxml_docs=disabled \
                -Ddoxygen_docs=disabled \
                -Dducktype_docs=disabled \
                -Dqt_help=disabled

    [ $? -eq 0 ] || exit 1

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Making ${PKG_NAME} ..."

    ${MESON_PY} compile -C ${DBUS_BUILD_DIR}/
    [ $? -eq 0 ] || exit 1

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Install ${PKG_NAME} to ${R} ..."

    DESTDIR="${R}" \
        ${MESON_PY} install -C ${DBUS_BUILD_DIR}/
    [ $? -eq 0 ] || exit 1

    echo "${SOURCE_NAME}: Done."
}
