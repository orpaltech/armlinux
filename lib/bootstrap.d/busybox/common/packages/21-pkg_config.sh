PKG_CONFIG_REPO_URL="https://gitlab.freedesktop.org/pkg-config/pkg-config.git"
PKG_CONFIG_VERSION=0.29.2
PKG_CONFIG_BRANCH=master
PKG_CONFIG_TAG="pkg-config-${PKG_CONFIG_VERSION}"
PKG_CONFIG_SRC_DIR=${EXTRADIR}/pkg-config
PKG_CONFIG_BUILD_DIR=${PKG_CONFIG_SRC_DIR}/${BB_BUILD_OUT}
PKG_CONFIG_REBUILD=yes
PKG_CONFIG_LIBC=gnu


pkg_config_install()
{
    local PKG_NAME=${1:-"pkg-config"}

    # build pkg-config
    PKG_FORCE_CLEAN="${PKG_CONFIG_REBUILD}" \
	update_src_pkg "pkg-config" \
                $PKG_CONFIG_VERSION \
                $PKG_CONFIG_SRC_DIR \
                $PKG_CONFIG_REPO_URL \
                $PKG_CONFIG_BRANCH \
                $PKG_CONFIG_TAG

    cd ${PKG_CONFIG_SRC_DIR}/
    # Remove internal glib, otherwise autogen.sh will fail
    rm -rf ./glib/*
    autoreconf --install


    echo "${SOURCE_NAME}: Configure ${PKG_NAME} ..."

    PKG_CONFIG=${BB_PKG_CONFIG} \
    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    MAKEINFO=/bin/true \
        ./configure --host=${BB_PLATFORM} \
		--prefix=/usr

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Making ${PKG_NAME} ..."

    chrt -i 0 make  -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Install ${PKG_NAME} to ${R} ..."

    make  install DESTDIR=${R}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."

}
