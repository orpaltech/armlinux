WPA_SUPP_VERSION=2.11
WPA_SUPP_TAR_FILE="wpa_supplicant-${WPA_SUPP_VERSION}.tar.gz"
WPA_SUPP_TAR_URL="https://w1.fi/releases/${WPA_SUPP_TAR_FILE}"
WPA_SUPP_BASE_DIR=${EXTRADIR}/wpa_supplicant
WPA_SUPP_SRC_DIR=${WPA_SUPP_BASE_DIR}/${WPA_SUPP_VERSION}
WPA_SUPP_BUILD_DIR=${WPA_SUPP_SRC_DIR}/${BB_BUILD_OUT}
WPA_SUPP_CONDITION="ENABLE_WLAN"
WPA_SUPP_REBUILD=yes


wpa_supp_install()
{
    local PKG_NAME=${1:-"wpa_supplicant"}

    # build wpa_supplicant

    if [ ! -d ${WPA_SUPP_SRC_DIR} ] || [ "${WPA_SUPP_FORCE_UPDATE}" = yes ] ; then
	echo "Download ${PKG_NAME} ..."

	rm -rf ${WPA_SUPP_SRC_DIR}
	mkdir -p ${WPA_SUPP_SRC_DIR}

	local tar_path="${WPA_SUPP_BASE_DIR}/${WPA_SUPP_TAR_FILE}"
	[ ! -f ${tar_path} ] && wget -O ${tar_path} ${WPA_SUPP_TAR_URL}
	tar -xvf ${tar_path} --strip-components=1 -C ${WPA_SUPP_SRC_DIR}
	rm -f ${tar_path}

        echo "Done."
    fi

    cd ${WPA_SUPP_SRC_DIR}/wpa_supplicant/

    cp defconfig .config

    local make_cmd=$(cat <<EOF
export PKG_CONFIG=${BB_PKG_CONFIG}
export CFLAGS="-I${R}/usr/include -I${R}/usr/include/libnl3 -I${R}/usr/lib/dbus-1.0/include"
export LDFLAGS="-L${R}/usr/lib"
export CC=${BB_GCC}
export INCDIR=/usr/include
export LIBDIR=/usr/lib
export BINDIR=/usr/sbin

echo "${SOURCE_NAME}: Making ${PKG_NAME} ..."

chrt -i 0  make -j${HOST_CPU_CORES}
[ $? -eq 0 ] || exit $?;

echo "${SOURCE_NAME}: Done."
echo "${SOURCE_NAME}: Install ${PKG_NAME} to ${R} ..."

make  install DESTDIR=${R}
[ $? -eq 0 ] || exit $?;

echo "${SOURCE_NAME}: Done."
EOF
)

    bash -c "$make_cmd"
    wait
}
