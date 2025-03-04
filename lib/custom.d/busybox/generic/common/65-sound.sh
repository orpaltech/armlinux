#
# Install audio support packages
#


ALSALIB_REPO_URL="https://github.com/alsa-project/alsa-lib.git"
ALSALIB_VERSION=1.2.13
ALSALIB_BRANCH=master
ALSALIB_TAG="v${ALSALIB_VERSION}"
ALSALIB_SRC_DIR=${EXTRADIR}/alsa-lib
ALSALIB_BUILD_DIR=${ALSALIB_SRC_DIR}/${BB_BUILD_OUT}


ALSA_UTILS_REPO_URL="https://github.com/alsa-project/alsa-utils.git"
ALSA_UTILS_VERSION=1.2.13
ALSA_UTILS_BRANCH=master
ALSA_UTILS_TAG="v${ALSA_UTILS_VERSION}"
ALSA_UTILS_SRC_DIR=${EXTRADIR}/alsa-utils
ALSA_UTILS_BUILD_DIR=${ALSA_UTILS_SRC_DIR}/${BB_BUILD_OUT}


SNDFILE_REPO_URL="https://github.com/libsndfile/libsndfile.git"
SNDFILE_VERSION=1.2.2
SNDFILE_BRANCH=master
SNDFILE_TAG="${SNDFILE_VERSION}"
SNDFILE_SRC_DIR=${EXTRADIR}/libsndfile
SNDFILE_BUILD_DIR=${SNDFILE_SRC_DIR}/${BB_BUILD_OUT}



SOURCE_NAME=$(basename ${BASH_SOURCE[0]})


#
# ############ helper functions ##############
#

alsa_lib_install()
{
    update_src_pkg "alsa-lib" \
                    $ALSALIB_VERSION \
                    $ALSALIB_SRC_DIR \
                    $ALSALIB_REPO_URL \
                    $ALSALIB_BRANCH \
                    $ALSALIB_TAG

    if [ "${SND_FORCE_REBUILD}" = yes ] ; then
	rm -rf ${ALSALIB_BUILD_DIR}
    fi

    cd ${ALSALIB_SRC_DIR}/
    libtoolize --force --copy --automake
    aclocal
    autoheader
    automake --foreign --copy --add-missing
    autoconf

    mkdir -p ${ALSALIB_BUILD_DIR}
    cd ${ALSALIB_BUILD_DIR}/

    echo "${SOURCE_NAME}: Configure alsa-lib ..."


    CC=${BB_GCC} CXX=${BB_CXX} LD=${BB_LD} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    CC_FLAGS="-O2 -Wall -W -Wunused-const-variable=0 -pipe" \
    MAKEINFO=/bin/true \
	../configure \
		--host=${BB_PLATFORM} \
		--srcdir=${ALSALIB_SRC_DIR} \
		--prefix=/usr \
		--with-plugindir="/usr/lib/alsa-lib"

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Make alsa-lib ..."

    chrt -i 0 make -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Deploy alsa-lib to ${R} ..."

    make  install DESTDIR=${R}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
}


alsa_utils_install()
{
    update_src_pkg "alsa-utils" \
                    $ALSA_UTILS_VERSION \
                    $ALSA_UTILS_SRC_DIR \
                    $ALSA_UTILS_REPO_URL \
                    $ALSA_UTILS_BRANCH \
                    $ALSA_UTILS_TAG

    if [ "${SND_FORCE_REBUILD}" = yes ] ; then
        rm -rf ${ALSA_UTILS_BUILD_DIR}
    fi

    cd ${ALSA_UTILS_SRC_DIR}/
    autoreconf --install --force

    mkdir -p ${ALSA_UTILS_BUILD_DIR}
    cd ${ALSA_UTILS_BUILD_DIR}/

    echo "${SOURCE_NAME}: Configure alsa-utils ..."


    CFLAGS="-I${R}/usr/include"
    LDFLAGS="-L${R}/usr/lib"

    PKG_CONFIG=/bin/false \
    CC=${BB_GCC} CXX=${BB_CXX} LD=${BB_LD} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    CFLAGS="${CFLAGS} -O2 -Wall -W -Wunused-const-variable=0 -pipe" \
    LDFLAGS="${LDFLAGS}" \
    NCURSES_LIBS="-lncurses -ltinfo ${LDFLAGS}" NCURSES_CFLAGS="${CFLAGS} -D_DEFAULT_SOURCE -D_XOPEN_SOURCE=600" \
    MAKEINFO=/bin/true \
        ../configure \
                --host=${BB_PLATFORM} \
                --srcdir=${ALSA_UTILS_SRC_DIR} \
                --prefix=/usr \
		--with-sysroot=${R} \
		--disable-alsaloop  --disable-nhlt  --disable-xmlto --disable-rst2man


    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Make alsa-utils ..."

    chrt -i 0 make -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Deploy alsa-utils to ${R} ..."

    make  install DESTDIR=${R}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."

}


sndfile_install()
{
    update_src_pkg "libsndfile" \
                    $SNDFILE_VERSION \
                    $SNDFILE_SRC_DIR \
                    $SNDFILE_REPO_URL \
                    $SNDFILE_BRANCH \
                    $SNDFILE_TAG

    if [ "${SND_FORCE_REBUILD}" = yes ] ; then
        rm -rf ${SNDFILE_BUILD_DIR}
    fi

    cd ${SNDFILE_SRC_DIR}/
    autoreconf -vif

    mkdir -p ${SNDFILE_BUILD_DIR}
    cd ${SNDFILE_BUILD_DIR}/

    echo "${SOURCE_NAME}: Configure libsndfile ..."

    PKG_CONFIG=${BB_PKG_CONFIG} \
    CC=${BB_GCC} CXX=${BB_CXX} LD=${BB_LD} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    CFLAGS="-I${R}/usr/include" \
    LDFLAGS="-L${R}/usr/lib" \
    MAKEINFO=/bin/true \
	../configure \
                --host=${BB_PLATFORM} \
                --srcdir=${SNDFILE_SRC_DIR} \
                --prefix=/usr \
		--disable-full-suite  --enable-werror

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Make libsndfile ..."

    chrt -i 0 make -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Deploy libsndfile to ${R} ..."

    make  install DESTDIR=${R}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."

}


#
# ############ install packages ##############
#

if [ "${ENABLE_SOUND}" = yes ] ; then

    [[ ${CLEAN} =~ (^|,)sound(,|$) ]] && SND_FORCE_REBUILD=yes
    set -x
    SND_FORCE_REBUILD=${SND_FORCE_REBUILD:="no"}
    set +x

    PKG_FORCE_CLEAN=${SND_FORCE_REBUILD}

    echo "${SOURCE_NAME}: Install audio support packages..."

    alsa_lib_install

    alsa_utils_install

    sndfile_install

    echo "${SOURCE_NAME}: Audio support packages installed."

    unset PKG_FORCE_CLEAN
fi
