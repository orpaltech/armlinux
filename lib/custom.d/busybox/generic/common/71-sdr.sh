#
# Install SDR-related user-space packages
#

RTLSDR_REPO_URL="https://gitea.osmocom.org/sdr/rtl-sdr.git"
RTLSDR_BRANCH=master
RTLSDR_VERSION=2.0.2
RTLSDR_TAG="v${RTLSDR_VERSION}"
RTLSDR_SRC_DIR=${EXTRADIR}/rtl-sdr
RTLSDR_BUILD_DIR=${RTLSDR_SRC_DIR}/${BB_BUILD_OUT}


SOURCE_NAME=$(basename ${BASH_SOURCE[0]})


#
# ############ helper functions ##############
#

rtl_sdr_install()
{
    update_src_pkg "rtl-sdr" \
                    $RTLSDR_VERSION \
                    $RTLSDR_SRC_DIR \
                    $RTLSDR_REPO_URL \
                    $RTLSDR_BRANCH \
                    $RTLSDR_TAG

    if [ "${SDR_FORCE_REBUILD}" = yes ] ; then
        rm -rf ${RTLSDR_BUILD_DIR}
    fi

    mkdir -p ${RTLSDR_BUILD_DIR}
    cd ${RTLSDR_BUILD_DIR}/


    PKG_CONFIG=${BB_PKG_CONFIG} \
    cmake \
	-DCROSS_COMPILE=${BB_CROSS_COMPILE} \
	-DCMAKE_TOOLCHAIN_FILE=${LIBDIR}/cmake/generic.toolchain.cmake \
	-DCMAKE_INSTALL_PREFIX=/usr \
	../

    echo "${SOURCE_NAME}: Make rtl-sdr ..."

    chrt -i 0 make -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Deploy rtl-sdr to ${R} ..."

    make  install DESTDIR=${R}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."

}


#
# ############ install packages ##############
#

if [ "${ENABLE_SDR}" = yes ] ; then
    echo -n -e "\n*** Build Settings ***\n"

    if [[ ${CLEAN} =~ (^|,)sdr(,|$) ]]; then
	SDR_FORCE_REBUILD=yes
    fi

    set -x
    SDR_FORCE_REBUILD=${SDR_FORCE_REBUILD:="no"}
    set +x

    PKG_FORCE_CLEAN=${SDR_FORCE_REBUILD}

    echo "${SOURCE_NAME}: Install SDR-related packages..."

    rtl_sdr_install

    echo "${SOURCE_NAME}: SDR packages installed."
    unset PKG_FORCE_CLEAN
fi
