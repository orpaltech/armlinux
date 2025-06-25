#
# Setup FFTW library
#

FFTW_VERSION=3.3.10
FFTW_TAR_FILE="fftw-${FFTW_VERSION}.tar.gz"
FFTW_TAR_URL="https://fftw.org/${FFTW_TAR_FILE}"
FFTW_BASE_DIR=${EXTRADIR}/fftw
FFTW_SRC_DIR=${FFTW_BASE_DIR}/${FFTW_VERSION}
FFTW_BUILD_DIR=${FFTW_SRC_DIR}/${BB_BUILD_OUT}
FFTW_FORCE_UPDATE=no
FFTW_FORCE_REBUILD=yes


SOURCE_NAME=$(basename ${BASH_SOURCE[0]})


#
# ############ helper functions ##############
#

fftw3_install()
{
    mkdir -p ${FFTW_BASE_DIR}

    if [ ! -d ${FFTW_SRC_DIR} ] || [ "${FFTW_FORCE_UPDATE}" = yes ] ; then
	echo "${SOURCE_NAME}: Download fftw ..."

	rm -rf ${FFTW_SRC_DIR}
	mkdir -p ${FFTW_SRC_DIR}

	local tar_path="${FFTW_BASE_DIR}/${FFTW_TAR_FILE}"
	[ ! -f ${tar_path} ] && wget -O ${tar_path} ${FFTW_TAR_URL}
	tar -xvf ${tar_path} --strip-components=1 -C ${FFTW_SRC_DIR}
	rm -f ${tar_path}

	echo "Done."
    fi

    if [ "${FFTW_FORCE_REBUILD}" = yes ] ; then
        rm -rf ${FFTW_BUILD_DIR}
    fi

    cd ${FFTW_SRC_DIR}/

    touch ChangeLog
    rm -rf autom4te.cache
    autoreconf --verbose --install --symlink --force
    rm -f config.cache

    mkdir -p ${FFTW_BUILD_DIR}
    cd ${FFTW_BUILD_DIR}/

    echo "${SOURCE_NAME}: Configure fftw ..."

    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    MAKEINFO=/bin/true \
	../configure --host=${BB_PLATFORM} \
		--srcdir=${FFTW_SRC_DIR} \
		--prefix=/usr \
		--enable-shared --enable-threads --disable-fortran --disable-doc

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Make fftw ..."

    chrt -i 0 make -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Deploy fftw to ${R} ..."

    make  install DESTDIR=${R}
    [ $? -eq 0 ] || exit $?

    echo "${SOURCE_NAME}: Done."
}

#
# ############ install packages ##############
#

if [ "${ENABLE_FFTW}" = yes ] ; then

    fftw3_install
fi
