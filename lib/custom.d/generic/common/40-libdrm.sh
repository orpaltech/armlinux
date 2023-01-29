#
# Build LIBDRM - userspace library for accessing the DRM
#
LIBDRM_REPO_URL="https://gitlab.freedesktop.org/mesa/drm.git"
LIBDRM_BRANCH="master"
LIBDRM_VER="2.4.110"
LIBDRM_TAG="libdrm-${LIBDRM_VER}"
LIBDRM_SRC_DIR=$EXTRADIR/libdrm
LIBDRM_OUT_DIR=${LIBDRM_SRC_DIR}/build/${LINUX_PLATFORM}

LIBDRM_CROSS_PKGCONFIG="${LIBDRM_OUT_DIR}/cross-pkg-config.sh"
LIBDRM_PREFIX="/usr"

MESA_GCC="${MESA_CROSS_COMPILE}gcc"
MESA_CXX="${MESA_CROSS_COMPILE}g++"
MESA_AR="${MESA_CROSS_COMPILE}ar"
MESA_NM="${MESA_CROSS_COMPILE}nm"
MESA_STRIP="${MESA_CROSS_COMPILE}strip"

# ----------------------------------------------------------------------------

libdrm_cross_init()
{
	cat <<-EOF > ${LIBDRM_CROSS_PKGCONFIG}
#!/bin/sh

SYSROOT=${SYSROOT_DIR}

export PKG_CONFIG_DIR=
export PKG_CONFIG_SYSROOT_DIR=\${SYSROOT}
export PKG_CONFIG_LIBDIR=\${SYSROOT}/usr/lib/${LINUX_PLATFORM}/pkgconfig:\${SYSROOT}/usr/lib/pkgconfig:\${SYSROOT}/usr/share/pkgconfig

exec pkg-config "\$@"
EOF

        chmod +x ${LIBDRM_CROSS_PKGCONFIG}

        cat <<-EOF > ${LIBDRM_OUT_DIR}/${MESON_CROSSFILE}
[constants]
compile_flags = []

[binaries]
c = '${MESA_GCC}'
cpp = '${MESA_CXX}'
ar = '${MESA_AR}'
nm = '${MESA_NM}'
strip = '${MESA_STRIP}'
pkgconfig = '${LIBDRM_CROSS_PKGCONFIG}'
exe_wrapper = 'QEMU_LD_PREFIX=${SYSROOT_DIR} ${QEMU_BINARY}'

[properties]
root = '${SYSROOT_DIR}'
sys_root = '${SYSROOT_DIR}'

[built-in options]
c_args = compile_flags
cpp_args = compile_flags

[host_machine]
system = 'linux'
cpu_family = '${MESON_CPU_FAMILY}'
cpu = '${MESON_CPU}'
endian = 'little'
EOF
}

libdrm_update()
{
	echo "Prepare LIBDRM sources..."

	if [ "${LIBDRM_FORCE_UPDATE}" = yes ] ; then
		echo "Force LIBDRM source update"
		rm -rf $LIBDRM_SRC_DIR
	fi

	if [ -d $LIBDRM_SRC_DIR ] && [ -d ${LIBDRM_SRC_DIR}/.git ] ; then
		local old_url=$(git -C $LIBDRM_SRC_DIR config --get remote.origin.url)
		if [ "${old_url}" != "${LIBDRM_REPO_URL}" ] ; then
			rm -rf $LIBDRM_SRC_DIR
		fi
	fi
	if [ -d $LIBDRM_SRC_DIR ] && [ -d ${LIBDRM_SRC_DIR}/.git ] ; then
		# update sources
		git -C $LIBDRM_SRC_DIR fetch origin --tags

		git -C $LIBDRM_SRC_DIR reset --hard
		git -C $LIBDRM_SRC_DIR clean -fdx

		echo "Checking out branch: ${LIBDRM_BRANCH}"
		git -C $LIBDRM_SRC_DIR checkout -B $LIBDRM_BRANCH origin/${LIBDRM_BRANCH}
		git -C $LIBDRM_SRC_DIR pull
	else
		[[ -d $LIBDRM_SRC_DIR ]] && rm -rf $LIBDRM_SRC_DIR

		# clone sources
		git clone $LIBDRM_REPO_URL -b $LIBDRM_BRANCH $LIBDRM_SRC_DIR
	fi

	if [ ! -z "${LIBDRM_TAG}" ] ; then
		echo "Checking out tag: tags/${LIBDRM_TAG}"
		git -C $LIBDRM_SRC_DIR checkout tags/${LIBDRM_TAG}

		LIBDRM_RELEASE=$LIBDRM_VER
		LIBDRM_DEB_VER="${LIBDRM_RELEASE}-tag"
	else
		LIBDRM_RELEASE=$LIBDRM_VER
		LAST_COMMIT_ID=$(git -C $LIBDRM_SRC_DIR log --format="%h" -n 1)
		LIBDRM_DEB_VER="${LIBDRM_RELEASE}-${LAST_COMMIT_ID}"
	fi

	LIBDRM_DEB_PKG_VER="${LIBDRM_DEB_VER}-${DEBIAN_RELEASE_ARCH}-${SOC_FAMILY}-${CONFIG}-${VERSION}"
	LIBDRM_DEB_PKG="libdrm-${LIBDRM_DEB_PKG_VER}"
	LIBDRM_DEB_DIR="${DEBS_DIR}/${LIBDRM_DEB_PKG}-deb"

	display_alert "Sources ready" "release ${LIBDRM_RELEASE}" "info"
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

        ${MESON_DIR}/meson.py "${LIBDRM_SRC_DIR}/" \
			--cross-file="${MESON_CROSSFILE}" \
                        --prefix="${LIBDRM_PREFIX}" \
                        --errorlogs \
                        --backend=ninja \
			-Dlibkms=true \
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

	chroot_exec /usr/sbin/ldconfig -X

	echo "Done."
}

# ----------------------------------------------------------------------------

if [[ ${CLEAN} =~ (^|,)(mesa|mesa-vc4|mesa-lima)(,|$) ]] ; then
	LIBDRM_FORCE_UPDATE="yes"
	LIBDRM_FORCE_REBUILD="yes"
fi

echo -n -e "\n*** Build Settings ***\n"
set -x

LIBDRM_FORCE_UPDATE=${LIBDRM_FORCE_UPDATE:="no"}
LIBDRM_FORCE_REBUILD=${LIBDRM_FORCE_REBUILD:="yes"}

set +x

echo "Building LIBDRM..."

libdrm_update

libdrm_make

libdrm_deploy

echo "LIBDRM build finished."
