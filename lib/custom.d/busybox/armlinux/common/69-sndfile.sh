#
# Install audio support packages
#


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

sndfile_install()
{
    PKG_FORCE_CLEAN=${SND_FORCE_REBUILD} \
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
		--enable-shared --disable-static \
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

if is_true "${ENABLE_SOUND}"; then

    [[ ${CLEAN} =~ (^|,)sound(,|$) ]] && SND_FORCE_REBUILD=yes
    set -x
    SND_FORCE_REBUILD=${SND_FORCE_REBUILD:="no"}
    set +x

    sndfile_install
fi
