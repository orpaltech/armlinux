#
# Setup Locales and keyboard settings
#

TZDB_VER=2025a
TZDB_TAR_FILE="tzdb-${TZDB_VER}.tar.lz"
TZDB_TAR_URL="https://data.iana.org/time-zones/releases/${TZDB_TAR_FILE}"
TZDB_BASE_DIR=${EXTRADIR}/tzdb
TZDB_SRC_DIR=${TZDB_BASE_DIR}/${TZDB_VER}
TZDB_SRC_HOST_DIR=${TZDB_BASE_DIR}/${TZDB_VER}-host
TZDB_FORCE_UPDATE=


SOURCE_NAME=$(basename ${BASH_SOURCE[0]})

#
# ############ helper functions ##############
#

tzdb_install()
{
    mkdir -p $TZDB_BASE_DIR

    if [ ! -d $TZDB_SRC_DIR ] || [ "${TZDB_FORCE_UPDATE}" = yes ] ; then
        echo "Download timezone db ..."

        rm -rf $TZDB_SRC_DIR	$TZDB_SRC_HOST_DIR
        mkdir -p $TZDB_SRC_DIR
	mkdir -p $TZDB_SRC_HOST_DIR

        local tar_path="${TZDB_BASE_DIR}/${TZDB_TAR_FILE}"
        [ ! -f ${tar_path} ] && wget -O ${tar_path} $TZDB_TAR_URL
        tar -xvf ${tar_path} --strip-components=1 -C $TZDB_SRC_DIR
	tar -xvf ${tar_path} --strip-components=1 -C $TZDB_SRC_HOST_DIR
        rm -f ${tar_path}

        echo "Done."
    fi

    cd ${TZDB_SRC_HOST_DIR}/

    echo "${SOURCE_NAME}: Deploy timezone db to ${R} ..."

    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
	make
    [ $? -eq 0 ] || exit $?;

    cd ${TZDB_SRC_DIR}/

    MAKEINFO=/bin/true \
	make DESTDIR="${TZDB_SRC_DIR}/dist" install
    [ $? -eq 0 ] || exit $?;


    cp --update=all -v ${TZDB_SRC_HOST_DIR}/*.a		${TZDB_SRC_DIR}/dist/usr/lib/
    cp --update=all -v ${TZDB_SRC_HOST_DIR}/zdump	${TZDB_SRC_DIR}/dist/usr/bin/
    cp --update=all -v ${TZDB_SRC_HOST_DIR}/zic		${TZDB_SRC_DIR}/dist/usr/sbin/



    rsync -avz ${TZDB_SRC_DIR}/dist/*	${R}/


    ln -sf ../usr/share/zoneinfo/Europe/Moscow	${ETC_DIR}/localtime


    echo "${SOURCE_NAME}: Done."

}

#
# ############ install packages ##############
#

tzdb_install
