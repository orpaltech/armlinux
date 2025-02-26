NCURSES_VERSION=6.5
NCURSES_TAR_FILE="ncurses-6.5.tar.gz"
NCURSES_TAR_URL="https://ftp.gnu.org/gnu/ncurses/${NCURSES_TAR_FILE}"
NCURSES_BASE_DIR=${EXTRADIR}/libncurses
NCURSES_SRC_DIR=${NCURSES_BASE_DIR}/${NCURSES_VERSION}
NCURSES_BUILD_DIR=${NCURSES_SRC_DIR}/${BB_BUILD_OUT}
NCURSES_FORCE_REBUILD=yes


ncurses_install()
{
    local PKG_NAME=${1:-"ncurses"}

    mkdir -p ${NCURSES_BASE_DIR}

    if [ ! -d ${NCURSES_SRC_DIR} ] || [ "${NCURSES_FORCE_UPDATE}" = yes ] ; then
        echo "Download ${PKG_NAME} ..."

        rm -rf ${NCURSES_SRC_DIR}
        mkdir -p ${NCURSES_SRC_DIR}

        local tar_path="${NCURSES_BASE_DIR}/${NCURSES_TAR_FILE}"
        [ ! -f ${tar_path} ] && wget -O ${tar_path} ${NCURSES_TAR_URL}
        tar -xvf ${tar_path} --strip-components=1 -C ${NCURSES_SRC_DIR}
        rm -f ${tar_path}

        echo "Done."
    fi

    if [ "${NCURSES_FORCE_REBUILD}" = yes ] ; then
        rm -rf ${NCURSES_BUILD_DIR}
    fi

    mkdir -p ${NCURSES_BUILD_DIR}
    cd ${NCURSES_BUILD_DIR}/

    echo "${SOURCE_NAME}: Configure ${PKG_NAME} ..."

    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
        ../configure --host=${BB_PLATFORM} \
                --srcdir=${NCURSES_SRC_DIR} \
                --prefix=/usr \
		--with-install-prefix=${R} \
		--with-pkg-config=${BB_PKG_CONFIG} --with-pkg-config-libdir=/usr/lib/pkgconfig --enable-pc-files \
		--disable-widec		--disable-big-core \
		--enable-termcap	--enable-getcap \
		--with-shared		--with-termlib \
		--without-manpages	--without-tests		--without-progs

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Make ${PKG_NAME} ..."

    chrt -i 0 make -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Deploy ${PKG_NAME} to ${R} ..."

    make  install
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."

}
