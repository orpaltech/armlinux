#
# Build and deploy MESA 3D library (lima backend)
#

MESA_REPO_URL="https://gitlab.freedesktop.org/mesa/mesa.git"
MESA_BRANCH="main"
MESA_TAG="mesa-24.1.1"
MESA_SRC_DIR=${EXTRADIR}/mesa
MESA_OUT_DIR=${MESA_SRC_DIR}/build/${LINUX_PLATFORM}-lima
MESA_PREFIX=/usr
MESA_FORCE_UPDATE=${MESA_FORCE_UPDATE:="no"}
MESA_FORCE_REBUILD=${MESA_FORCE_REBUILD:="yes"}

# -----------------------------------------------------------------------------

mesa_cross_init()
{
	cat <<-EOF > ${MESA_OUT_DIR}/${MESON_CROSSFILE}
# Meson cross-file for Mesa 3D Graphics Library, ver ${MESA_DEB_VER}
[constants]
common_flags = [ '--sysroot=${SYSROOT_DIR}', '-I${SYSROOT_DIR}/usr/include', '-I${SYSROOT_DIR}/usr/include/${LINUX_PLATFORM}' ]
c_flags = []
cpp_flags = []

[binaries]
c = '${MESA_GCC}'
cpp = '${MESA_CXX}'
ar = '${MESA_AR}'
strip = '${MESA_STRIP}'
nm = '${MESA_NM}'
pkg-config = '/usr/bin/pkg-config'
# exe_wrapper = 'QEMU_LD_PREFIX=${SYSROOT_DIR} ${QEMU_BINARY}'

[properties]
sys_root = '${SYSROOT_DIR}'
pkg_config_libdir = [ '${SYSROOT_DIR}/usr/lib/${LINUX_PLATFORM}/pkgconfig', '${SYSROOT_DIR}/usr/lib/pkgconfig', '${SYSROOT_DIR}/usr/share/pkgconfig' ]

[built-in options]
c_args = common_flags + c_flags
cpp_args = common_flags + cpp_flags

[host_machine]
system = 'linux'
kernel = 'linux'
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
		rm -rf ${MESA_SRC_DIR}
	fi

	if [ -d ${MESA_SRC_DIR} ] && [ -d ${MESA_SRC_DIR}/.git ] ; then
		local old_url=$(git -C ${MESA_SRC_DIR} config --get remote.origin.url)
		if [ "${old_url}" != "${MESA_REPO_URL}" ] ; then
			rm -rf ${MESA_SRC_DIR}
		fi
	fi
	if [ -d ${MESA_SRC_DIR} ] && [ -d ${MESA_SRC_DIR}/.git ] ; then
		# update sources
		git -C ${MESA_SRC_DIR} fetch origin --tags

		git -C ${MESA_SRC_DIR} reset --hard
		git -C ${MESA_SRC_DIR} clean -fdx

		echo "Checking out branch: ${MESA_BRANCH}"
		git -C ${MESA_SRC_DIR} checkout -B ${MESA_BRANCH} origin/${MESA_BRANCH}
		git -C ${MESA_SRC_DIR} pull
	else
		[[ -d ${MESA_SRC_DIR} ]] && rm -rf ${MESA_SRC_DIR}

		# clone sources
		git clone ${MESA_REPO_URL} -b ${MESA_BRANCH} --tags  ${MESA_SRC_DIR}
	fi

	if [ -n "${MESA_TAG}" ] ; then
		echo "Checking out tag: tags/${MESA_TAG}"
		git -C ${MESA_SRC_DIR} checkout tags/${MESA_TAG}

		MESA_RELEASE=$(head -n 1 ${MESA_SRC_DIR}/VERSION)
		MESA_DEB_VER="${MESA_RELEASE}-tag"
	else
		MESA_RELEASE=$(head -n 1 ${MESA_SRC_DIR}/VERSION)
		LAST_COMMIT_ID=$(git -C ${MESA_SRC_DIR} log --format="%h" -n 1)
		MESA_DEB_VER="${MESA_RELEASE}-${LAST_COMMIT_ID}"
	fi

	MESA_DEB_PKG_VER="${MESA_DEB_VER}-${DEBIAN_RELEASE}-${DEBIAN_RELEASE_ARCH}-${SOC_FAMILY}"
	MESA_DEB_PKG="mesa-${MESA_DEB_PKG_VER}"
	MESA_DEB_DIR="${DEBS_DIR}/${MESA_DEB_PKG}-deb"

	display_alert "Sources ready" "release ${MESA_RELEASE}" "info"
}

mesa_make()
{
	mkdir -p ${MESA_OUT_DIR}

	if [ "${MESA_FORCE_REBUILD}" = yes ] ; then
		echo "Force rebuild"
		rm -rf ${MESA_OUT_DIR}/*
	fi

	mesa_cross_init

	cd ${MESA_SRC_DIR}

	echo "Configure MESA..."

	PKG_CONFIG_PATH= \
		${MESON_DIR}/meson.py setup ${MESA_OUT_DIR}/ \
			--cross-file="${MESA_OUT_DIR}/${MESON_CROSSFILE}" \
			--prefix="${MESA_PREFIX}" \
			--errorlogs \
			--backend=ninja \
			-Dplatforms= \
			-Dgallium-drivers=lima,kmsro \
			-Degl-native-platform=drm \
			-Dvulkan-drivers= \
			-Dgles2=enabled \
			-Degl=enabled \
			-Dgbm=enabled \
			-Dglx=disabled \
			-Dllvm=disabled \
			-Dlibunwind=disabled \
			-Dgallium-vdpau=disabled

	[ $? -eq 0 ] || exit 1

	echo "Making Mesa..."

	${MESON_DIR}/meson.py compile -C ${MESA_OUT_DIR}/

	[ $? -eq 0 ] || exit 1

	DESTDIR="${MESA_OUT_DIR}/dist" \
		${MESON_DIR}/meson.py install -C ${MESA_OUT_DIR}/

	[ $? -eq 0 ] || exit 1

	cd ${MESA_OUT_DIR}

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

	cat <<-EOF > ${MESA_DEB_DIR}/DEBIAN/rules
#!/usr/bin/make -f

%:
	dh $@

override_dh_builddeb:
	dh_builddeb -- -Zxz
EOF

	cat <<-EOF > ${MESA_DEB_DIR}/DEBIAN/control
Package: ${MESA_DEB_PKG}
Version: ${MESA_DEB_PKG_VER}
Maintainer: ${MAINTAINER_NAME} <${MAINTAINER_EMAIL}>
Architecture: all
Priority: optional
Depends: libexpat1 (>= 2.2.0), zlib1g (>= 1.2.0)
Build-Depends: libexpat1-dev, zlib1g-dev
Description: This package provides Mesa 3D libraries for Allwinner SoCs
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

	dpkg-deb -Zxz -z0 -b ${MESA_DEB_DIR}  ${BASEDIR}/debs/${MESA_DEB_PKG}.deb
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

if [ "${ENABLE_MESA}" = yes ] ; then

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
	echo "Skip building MESA (lima backend) library."
fi
