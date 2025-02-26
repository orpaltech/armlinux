HOSTAP_REPO_URL="https://w1.fi/hostap.git"
HOSTAP_VERSION=2_11
HOSTAP_BRANCH=main
HOSTAP_TAG="hostap_${HOSTAP_VERSION}"
HOSTAP_SRC_DIR=${EXTRADIR}/hostap
HOSTAP_BUILD_DIR=${HOSTAP_SRC_DIR}/${BB_BUILD_OUT}
HOSTAP_CONDITION="ENABLE_WLAN"
HOSTAP_REBUILD=yes


hostap_install()
{
    local PKG_NAME=${1:-"hostap"}

    # build wpa_supplicant
    PKG_FORCE_CLEAN="${HOSTAP_REBUILD}" \
	update_src_pkg "hostap" \
                    $HOSTAP_VERSION \
                    $HOSTAP_SRC_DIR \
                    $HOSTAP_REPO_URL \
                    $HOSTAP_BRANCH \
                    $HOSTAP_TAG

    cd ${HOSTAP_SRC_DIR}/wpa_supplicant/

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
