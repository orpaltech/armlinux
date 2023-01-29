#
# Build and deploy MESA 3D library (lima backend)
#

MESA_REPO_URL="https://gitlab.freedesktop.org/mesa/mesa.git"
MESA_BRANCH="main"
MESA_TAG="mesa-22.3.4"
MESA_SRC_DIR=${EXTRADIR}/mesa
MESA_OUT_DIR=${MESA_SRC_DIR}/build/${LINUX_PLATFORM}-lima
MESA_PREFIX=/usr
MESA_FORCE_UPDATE=${MESA_FORCE_UPDATE:="yes"}
MESA_FORCE_REBUILD=${MESA_FORCE_REBUILD:="yes"}

MESA_CROSS_PKGCONFIG="${MESA_OUT_DIR}/cross-pkg-config.sh"

MESA_GCC="${MESA_CROSS_COMPILE}gcc"
MESA_CXX="${MESA_CROSS_COMPILE}g++"
MESA_AR="${MESA_CROSS_COMPILE}ar"
MESA_STRIP="${MESA_CROSS_COMPILE}strip"
MESA_NM="${MESA_CROSS_COMPILE}nm"

# -----------------------------------------------------------------------------

mesa_cross_init()
{
	cat <<-EOF > ${MESA_CROSS_PKGCONFIG}
#!/bin/sh

SYSROOT=${SYSROOT_DIR}

export PKG_CONFIG_DIR=
export PKG_CONFIG_SYSROOT_DIR=\${SYSROOT}
export PKG_CONFIG_LIBDIR=\${SYSROOT}/usr/lib/${LINUX_PLATFORM}/pkgconfig:\${SYSROOT}/usr/lib/pkgconfig:\${SYSROOT}/usr/share/pkgconfig

exec pkg-config "\$@"
EOF
	chmod +x ${MESA_CROSS_PKGCONFIG}

	cat <<-EOF > ${MESA_OUT_DIR}/${MESON_CROSSFILE}
# Meson cross-file for Mesa 3D Graphics Library, ver ${MESA_DEB_VER}
[constants]
compile_flags = []
c_flags = [ '-I${SYSROOT_DIR}/usr/include', '-I${SYSROOT_DIR}/usr/include/${LINUX_PLATFORM}' ]
cpp_flags = []

[binaries]
c = '${MESA_GCC}'
cpp = '${MESA_CXX}'
ar = '${MESA_AR}'
strip = '${MESA_STRIP}'
nm = '${MESA_NM}'
pkgconfig = '${MESA_CROSS_PKGCONFIG}'
#exe_wrapper = 'QEMU_LD_PREFIX=${SYSROOT_DIR} ${QEMU_BINARY}'

[built-in options]
c_args = compile_flags + c_flags
cpp_args = compile_flags + cpp_flags

[host_machine]
system = 'linux'
cpu_family = '${MESON_CPU_FAMILY}'
cpu = '${MESON_CPU}'
endian = 'little'
EOF
}

mesa_prepare()
{
	echo "Prepare MESA sources..."

	if [ "${MESA_FORCE_UPDATE}" = yes ] ; then
		echo "Force MESA source update"
		rm -rf $MESA_SRC_DIR
	fi

	if [ -d $MESA_SRC_DIR ] && [ -d ${MESA_SRC_DIR}/.git ] ; then
		local old_url=$(git -C $MESA_SRC_DIR config --get remote.origin.url)
		if [ "${old_url}" != "${MESA_REPO_URL}" ] ; then
			rm -rf $MESA_SRC_DIR
		fi
	fi
	if [ -d $MESA_SRC_DIR ] && [ -d ${MESA_SRC_DIR}/.git ] ; then
		# update sources
		git -C $MESA_SRC_DIR fetch origin --tags

		git -C $MESA_SRC_DIR reset --hard
		git -C $MESA_SRC_DIR clean -fdx

		echo "Checking out branch: ${MESA_BRANCH}"
		git -C $MESA_SRC_DIR checkout -B $MESA_BRANCH origin/${MESA_BRANCH}
		git -C $MESA_SRC_DIR pull
	else
		[[ -d $MESA_SRC_DIR ]] && rm -rf $MESA_SRC_DIR

		# clone sources
		git clone $MESA_REPO_URL -b $MESA_BRANCH $MESA_SRC_DIR
	fi

	if [ -n "${MESA_TAG}" ] ; then
		echo "Checking out tag: tags/${MESA_TAG}"
		git -C $MESA_SRC_DIR checkout tags/${MESA_TAG}

		MESA_RELEASE=$(head -n 1 ${MESA_SRC_DIR}/VERSION)
		MESA_DEB_VER="${MESA_RELEASE}-tag"
	else
		MESA_RELEASE=$(head -n 1 ${MESA_SRC_DIR}/VERSION)
		LAST_COMMIT_ID=$(git -C $MESA_SRC_DIR log --format="%h" -n 1)
		MESA_DEB_VER="${MESA_RELEASE}-${LAST_COMMIT_ID}"
	fi

	MESA_GCC_VER=$(${MESA_GCC} -dumpversion)
	MESA_DEB_PKG_VER="${MESA_DEB_VER}-${DEBIAN_RELEASE}-${DEBIAN_RELEASE_ARCH}-${SOC_FAMILY}-${MESA_TOOLCHAIN}${MESA_GCC_VER}"
	MESA_DEB_PKG="mesa-${MESA_DEB_PKG_VER}"
	MESA_DEB_DIR="${DEBS_DIR}/${MESA_DEB_PKG}-deb"

	display_alert "Sources ready" "release ${MESA_RELEASE}" "info"
}

mesa_make()
{
	if [ "${MESA_FORCE_REBUILD}" = yes ] ; then
		echo "Force rebuild"
		rm -rf ${MESA_OUT_DIR}
	fi
	mkdir -p ${MESA_OUT_DIR}

	mesa_cross_init

	echo "Configure MESA..."

	cd ${MESA_OUT_DIR}

	${MESON_DIR}/meson.py ${MESA_SRC_DIR}/ --cross-file="${MESON_CROSSFILE}" \
			--prefix="${MESA_PREFIX}" \
			--errorlogs \
			--backend=ninja \
			-Dplatforms= \
			-Dgallium-drivers=lima,kmsro \
			-Ddri-drivers= \
			-Dvulkan-drivers= \
			-Dgles2=enabled \
			-Degl=enabled \
			-Dgbm=enabled \
			-Dglx=disabled \
			-Dllvm=disabled \
			-Dlibunwind=disabled \
			-Dgallium-vdpau=disabled

	echo "Making Mesa..."

	ninja -v

	DESTDIR="./dist" ninja install

	# NOTE: only need sun4i-drm, so remove other libraries
	mv ./dist/usr/lib/dri/sun4i-drm_dri.so ./dist/usr/lib/dri/sun4i-drm_dri.so.tmp
	rm -f ./dist/usr/lib/dri/*_dri.so
	mv ./dist/usr/lib/dri/sun4i-drm_dri.so.tmp ./dist/usr/lib/dri/sun4i-drm_dri.so

	echo "Done."
}

mesa_deb_pkg()
{
	echo "Create MESA deb package..."

	mkdir -p ${MESA_DEB_DIR}
	rm -rf ${MESA_DEB_DIR}/*

	mkdir ${MESA_DEB_DIR}/DEBIAN

	cat <<-EOF > ${MESA_DEB_DIR}/DEBIAN/control
Package: $MESA_DEB_PKG
Version: $MESA_DEB_PKG_VER
Maintainer: $MAINTAINER_NAME <$MAINTAINER_EMAIL>
Architecture: all
Priority: optional
Description: This package provides Mesa 3D libraries for sunXi platforms
EOF

	cat <<-EOF > ${MESA_DEB_DIR}/DEBIAN/postinst
#!/bin/sh

set -e

case "\$1" in
  configure)
    echo "${MESA_PREFIX}/lib" > /etc/ld.so.conf.d/mesa.conf
    ldconfig -X
    ;;
esac

exit 0
EOF

	chmod +x ${MESA_DEB_DIR}/DEBIAN/postinst

	mkdir -p ${MESA_DEB_DIR}${MESA_PREFIX}
	rsync -az ${MESA_OUT_DIR}/dist${MESA_PREFIX}/  ${MESA_DEB_DIR}${MESA_PREFIX}

	dpkg-deb -z0 -b $MESA_DEB_DIR  ${BASEDIR}/debs/${MESA_DEB_PKG}.deb
	[ $? -eq 0 ] || exit $?;

	rm -rf ${MESA_DEB_DIR}

	echo "Done."
}

mesa_deploy()
{
	echo "Deploying MESA libs/headers..."

	mkdir -p ${MESA_DEB_DIR}
	dpkg -x ${BASEDIR}/debs/${MESA_DEB_PKG}.deb  ${MESA_DEB_DIR}  2> /dev/null

	mkdir -p ${SYSROOT_DIR}${MESA_PREFIX}
	rsync -az ${MESA_DEB_DIR}${MESA_PREFIX}/  ${SYSROOT_DIR}${MESA_PREFIX}
	${LIBDIR}/make-relativelinks.sh  ${SYSROOT_DIR}
	rm -rf ${MESA_DEB_DIR}

	cp ${BASEDIR}/debs/${MESA_DEB_PKG}.deb  ${R}/tmp/
	chroot_exec dpkg -i  /tmp/${MESA_DEB_PKG}.deb
	rm -f ${R}/tmp/${MESA_DEB_PKG}.deb

        echo "Done."
}

# -----------------------------------------------------------------------------

if [ "${MALI_BLOB_TYPE}" = "lima" ] ; then

	echo "Building MESA library..."

	mesa_prepare

	if [[ ${CLEAN} =~ (^|,)(mesa|mesa-lima)(,|$) ]] ; then
		rm -f ${BASEDIR}/debs/${MESA_DEB_PKG}.deb
	fi

	if [ ! -f ${BASEDIR}/debs/${MESA_DEB_PKG}.deb ] ; then
		mesa_make
		mesa_deb_pkg
	fi

	mesa_deploy

	echo "MESA build complete."
else
	echo "Skip building MESA library."
fi
