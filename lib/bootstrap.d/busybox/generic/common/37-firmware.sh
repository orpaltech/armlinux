#
# Install firmware files
#

WREGDB_VERSION=2025.07.10
WREGDB_TAR_FILE="wireless-regdb-${WREGDB_VERSION}.tar.xz"
WREGDB_TAR_URL="https://mirrors.edge.kernel.org/pub/software/network/wireless-regdb/${WREGDB_TAR_FILE}"
WREGDB_BASE_DIR=${EXTRADIR}/wireless-regdb
WREGDB_SRC_DIR=${WREGDB_BASE_DIR}/${WREGDB_VERSION}
WREGDB_FORCE_UPDATE=

SOURCE_NAME=$(basename ${BASH_SOURCE[0]})


#
# ############ helper functions ##############
#

wregdb_install()
{
    mkdir -p ${WREGDB_BASE_DIR}

    if [ ! -d ${WREGDB_SRC_DIR} ] || [ "${WREGDB_FORCE_UPDATE}" = yes ] ; then
        echo "${SOURCE_NAME}: Download wireless-regdb ..."

        rm -rf ${WREGDB_SRC_DIR}
        mkdir -p ${WREGDB_SRC_DIR}

        local tar_path="${WREGDB_BASE_DIR}/${WREGDB_TAR_FILE}"
        [ ! -f ${tar_path} ] && wget -O ${tar_path} ${WREGDB_TAR_URL}
        tar -xvf ${tar_path} --strip-components=1 -C ${WREGDB_SRC_DIR}
        rm -f ${tar_path}

        echo "${SOURCE_NAME}: Done."
    fi

    cd ${WREGDB_SRC_DIR}

    echo "${SOURCE_NAME}: Deploy wireless-regdb to ${R} ..."

    make  install LSB_ID=busybox DESTDIR=${R}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."

}

#
# ############ install packages ##############
#

wregdb_install


rsync -avz ${LIBDIR}/files/firmware/common/		${R}/lib/firmware
rsync -avz ${LIBDIR}/files/firmware/${SOC_FAMILY}/	${R}/lib/firmware


chown -R root:root ${R}/lib/firmware
find ${R}/lib/firmware -type d -exec chmod 755 {} \;
find ${R}/lib/firmware -type f -exec chmod 644 {} \;
