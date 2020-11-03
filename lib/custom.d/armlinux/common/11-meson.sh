#
# Install Meson - open source build system
#

MESON_RELEASE="0.55.3"
MESON_BASE_DIR=$EXTRADIR/meson
MESON_DIR=${MESON_BASE_DIR}/meson-${MESON_RELEASE}
MESON_TAR_FILE="meson-${MESON_RELEASE}.tar.gz"
MESON_TAR_URL="https://github.com/mesonbuild/meson/releases/download/${MESON_RELEASE}/${MESON_TAR_FILE}"
MESON_CROSSFILE="meson-cross-file.ini"
MESON_FORCE_UPDATE="no"


meson_update()
{
        mkdir -p ${MESON_BASE_DIR}

        if [ ! -d $MESON_DIR ] || [ "${MESON_FORCE_UPDATE}" = yes ] ; then
                echo "Download Meson build tool..."

                rm -rf $MESON_DIR
                local TAR_PATH="${MESON_BASE_DIR}/${MESON_TAR_FILE}"
                [ ! -f ${TAR_PATH} ] && wget -O ${TAR_PATH} ${MESON_TAR_URL}
                tar -xvf ${TAR_PATH} -C ${MESON_BASE_DIR}/
                rm -f ${TAR_PATH}

                echo "Done."
        fi
}

# -----------------------------------------------------------------------------

meson_update
