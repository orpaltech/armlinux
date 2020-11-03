#
# Build LIBDRM - userspace library for accessing the DRM
#

LIBDRM_VER="2.4.102"
LIBDRM_NAME="libdrm-${LIBDRM_VER}"
LIBDRM_TAR_FILE="${LIBDRM_NAME}.tar.xz"
LIBDRM_SRC_DIR=$EXTRADIR/$LIBDRM_NAME
LIBDRM_OUT_DIR=$LIBDRM_SRC_DIR/build/$LINUX_PLATFORM

LIBDRM_TAR_URL="https://dri.freedesktop.org/libdrm/${LIBDRM_TAR_FILE}"

echo -n -e "\n*** Build Settings ***\n"
set -x

LIBDRM_FORCE_UPDATE=${LIBDRM_FORCE_UPDATE:="no"}
LIBDRM_FORCE_REBUILD=${LIBDRM_FORCE_REBUILD:="yes"}

set +x

LIBDRM_CROSS_PKGCONFIG="${LIBDRM_OUT_DIR}/cross-pkg-config.sh"
LIBDRM_PREFIX=/usr

# ----------------------------------------------------------------------------

libdrm_update()
{
	if [ ! -d $LIBDRM_SRC_DIR ] || [ "${LIBDRM_FORCE_UPDATE}" = yes ] ; then
		echo "Download LIBDRM sources..."

		rm -rf $LIBDRM_SRC_DIR
		local TAR_PATH=$EXTRADIR/$LIBDRM_TAR_FILE
		[ ! -f $TAR_PATH ] && wget -O $TAR_PATH $LIBDRM_TAR_URL
		tar -xvf $TAR_PATH -C "${EXTRADIR}/"
		rm -f $TAR_PATH

		echo "Done."
	fi
}

libdrm_cross_init()
{
	cat <<-EOF > ${LIBDRM_CROSS_PKGCONFIG}
#!/bin/sh

SYSROOT=${SYSROOT_DIR}

export PKG_CONFIG_DIR=
export PKG_CONFIG_LIBDIR=\${SYSROOT}/usr/lib/${LINUX_PLATFORM}/pkgconfig:\${SYSROOT}/usr/lib/pkgconfig:\${SYSROOT}/usr/share/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=\${SYSROOT}

exec pkg-config "\$@"
EOF

        chmod +x ${LIBDRM_CROSS_PKGCONFIG}

        cat <<-EOF > ${LIBDRM_OUT_DIR}/${MESON_CROSSFILE}
[binaries]
c = '${DEV_GCC}'
cpp = '${DEV_CXX}'
ar = '${DEV_AR}'
ld = '${DEV_LD}'
nm = '${DEV_NM}'
strip = '${DEV_STRIP}'
pkgconfig = '${LIBDRM_CROSS_PKGCONFIG}'
exe_wrapper = 'QEMU_LD_PREFIX=${SYSROOT_DIR} ${QEMU_BINARY}'

[properties]
root = '${SYSROOT_DIR}'
sys_root = '${SYSROOT_DIR}'
c_args = [ '--sysroot=${SYSROOT_DIR}' ]
cpp_args = [ '--sysroot=${SYSROOT_DIR}' ]

[host_machine]
system = 'linux'
cpu_family = '${MESON_CPU_FAMILY}'
cpu = '${MESON_CPU}'
endian = 'little'
EOF
}

libdrm_make()
{
        mkdir -p $LIBDRM_OUT_DIR
        cd $LIBDRM_OUT_DIR

        if [ "${LIBDRM_FORCE_REBUILD}" = yes ] ; then
                echo "Forcing LIBDRM rebuild"
                rm -rf ./*
        fi

        mkdir -p ./dist
        rm -rf ./dist/*

	libdrm_cross_init

        echo "Configure LIBDRM..."

        ${MESON_DIR}/meson.py ${LIBDRM_SRC_DIR}/ --cross-file="${MESON_CROSSFILE}" \
                        --prefix="${LIBDRM_PREFIX}" \
                        --errorlogs \
                        --backend=ninja \
			-Dvc4=true \
			-Dcairo-tests=false \
			-Dinstall-test-programs=true

        echo "Making LIBDRM..."

        ninja -v

        DESTDIR="./dist" ninja install

        echo "Done."
}

libdrm_deploy()
{
	echo "Deploying LIBDRM..."

	rsync -az ${LIBDRM_OUT_DIR}/dist${LIBDRM_PREFIX}/	${SYSROOT_DIR}${LIBDRM_PREFIX}
	${LIBDIR}/make-relativelinks.sh $SYSROOT_DIR
	rsync -az ${LIBDRM_OUT_DIR}/dist${LIBDRM_PREFIX}/	${R}${LIBDRM_PREFIX}
	rsync -az ${LIBDRM_OUT_DIR}/dist${LIBDRM_PREFIX}/	${R}${LIBDRM_PREFIX}

#	rsync -az ${LIBDRM_OUT_DIR}/tests/modetest	${USR_DIR}/bin/

	echo "Done."
}

# ----------------------------------------------------------------------------

echo "Building LIBDRM..."

libdrm_update

libdrm_make

libdrm_deploy

echo "LIBDRM build finished."
