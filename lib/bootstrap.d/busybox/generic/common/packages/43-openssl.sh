OPENSSL_REPO_URL="https://github.com/openssl/openssl.git"
OPENSSL_VERSION=3.6.0
OPENSSL_BRANCH=master
OPENSSL_TAG="openssl-${OPENSSL_VERSION}"
OPENSSL_SRC_DIR=${EXTRADIR}/openssl
OPENSSL_BUILD_DIR=${OPENSSL_SRC_DIR}/${BB_BUILD_OUT}
OPENSSL_REBUILD=yes


openssl_install()
{
    local PKG_NAME=${1:-"openssl"}

    # build openssl
    PKG_FORCE_CLEAN="${OPENSSL_REBUILD}" \
        update_src_pkg "openssl" \
                    $OPENSSL_VERSION \
                    $OPENSSL_SRC_DIR \
                    $OPENSSL_REPO_URL \
                    $OPENSSL_BRANCH \
                    $OPENSSL_TAG

    if [ "${OPENSSL_REBUILD}" = yes ] ; then
        rm -rf ${OPENSSL_BUILD_DIR}
    fi

    mkdir -p ${OPENSSL_BUILD_DIR}
    cd ${OPENSSL_BUILD_DIR}/

    echo "${SOURCE_NAME}: Configure ${PKG_NAME} ..."

    PKG_CONFIG=${BB_PKG_CONFIG} \
        ../Configure ${OPENSSL_PLATFORM} \
                --release \
                --cross-compile-prefix=${BB_CROSS_COMPILE} \
                --prefix=/usr \
                --with-zlib-include=${R}/usr/include \
                --with-zlib-lib=${R}/usr/lib \
                shared zlib-dynamic no-tests no-docs no-engine no-ssl-trace no-legacy \
                '-Wl,--enable-new-dtags,-rpath,$(LIBRPATH)'

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Make ${PKG_NAME} ..."

    chrt -i 0 make -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Install ${PKG_NAME} to ${R} ..."

    make  install DESTDIR=${R}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    unset PKG_FORCE_CLEAN
}
