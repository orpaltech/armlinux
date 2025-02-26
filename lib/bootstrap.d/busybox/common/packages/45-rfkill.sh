RFKILL_VERSION=1.0
RFKILL_TAR_FILE=rfkill-${RFKILL_VERSION}.tar.gz
RFKILL_TAR_URL="https://www.kernel.org/pub/software/network/rfkill/${RFKILL_TAR_FILE}"
RFKILL_BASE_DIR=${EXTRADIR}/rfkill
RFKILL_SRC_DIR=${RFKILL_BASE_DIR}/${RFKILL_VERSION}
RFKILL_FORCE_UPDATE=


rfkill_install()
{
    local PKG_NAME=${1:-"rfkill"}

    mkdir -p ${RFKILL_BASE_DIR}

    if [ ! -d ${RFKILL_SRC_DIR} ] || [ "${RFKILL_FORCE_UPDATE}" = yes ] ; then
	echo "${SOURCE_NAME}: Download ${PKG_NAME} ..."

	rm -rf ${RFKILL_SRC_DIR}
	mkdir -p ${RFKILL_SRC_DIR}

	local tar_path="${RFKILL_BASE_DIR}/${RFKILL_TAR_FILE}"
	[ ! -f ${tar_path} ] && wget -O ${tar_path} ${RFKILL_TAR_URL}
	tar -xvf ${tar_path} --strip-components=1 -C ${RFKILL_SRC_DIR}
	rm -f ${tar_path}

	echo "${SOURCE_NAME}: Done."
    fi

    cd ${RFKILL_SRC_DIR}/

    echo "${SOURCE_NAME}: Make ${PKG_NAME} ..."

    CC=${BB_GCC} \
	make -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Deploy ${PKG_NAME} to ${R} ..."

    DESTDIR=${R} \
	make  install
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."

}
