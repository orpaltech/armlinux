#
# Build Qt5 framework
#
QT_GIT_ROOT="https://code.qt.io/qt"
QT_RELEASE="5.15"
QT_BRANCH="${QT_RELEASE}.2"
QT_TAG=
QT_MODULES=("qtxmlpatterns" "qtimageformats" "qtgraphicaleffects" "qtsvg" "qtscript" "qtdeclarative" "qtquickcontrols" "qtquickcontrols2" "qtcharts" "qtvirtualkeyboard")
QT_ROOT_DIR=${EXTRADIR}/qt-build/qt5
QT_BUILD_DIR=${QT_ROOT_DIR}/build/${QT_DEVICE_CONFIG}
QTBASE_URL=${QT_GIT_ROOT}/qtbase.git
QTBASE_SRC_DIR=${QT_ROOT_DIR}/qtbase
QTBASE_OUT_DIR=${QT_BUILD_DIR}/qtbase

# version directory is named after the branch
QT_CUSTOM_VER="${QT_RELEASE}"
# here we keep resources needed for QT5 customization
QT_PATCH_BASE_DIR=${PATCHDIR}/qt/qt5/${QT_CUSTOM_VER}

QT_TARGET_LOCATION="/usr/local"
QT_TARGET_PREFIX=${QT_TARGET_LOCATION}/qt5pi
QT_HOST_PREFIX=${QT_BUILD_DIR}/qt5host
echo -n -e "\n*** Build Settings ***\n"
set -x

# force update sources
QT_UPDATE_SOURCES=${QT_UPDATE_SOURCES:="no"}

# go for a full rebuild
QT_FORCE_REBUILD=${QT_FORCE_REBUILD:="yes"}

set +x
QT_EXT_PREFIX=${QT_BUILD_DIR}/qt5pi
QT_QMAKE=${QT_HOST_PREFIX}/bin/qmake

[[ -z "${QT_TAG}" ]] && QT5_DEB_VER="${QT_BRANCH}" || QT5_DEB_VER="${QT_RELEASE}-tag-${QT_TAG}"
QT5_DEB_PKG_VER="${QT5_DEB_VER}-${QT_DEVICE_CONFIG}-${FULL_VERSION}-${CONFIG}"
QT5_DEB_PKG="qt-${QT5_DEB_PKG_VER}"
QT5_DEB_DIR=${DEBS_DIR}/${QT5_DEB_PKG}-deb
QT5_DEB_PKG_FILE=${BASEDIR}/debs/${QT5_DEB_PKG}.deb

QT_CROSS_COMPILE=${QT_CROSS_COMPILE:="$CROSS_COMPILE"}

[[ "${ENABLE_X11}" = "yes" ]] && QT_XCB_OPTION="-system-xcb" || QT_XCB_OPTION="-no-xcb"


# ----------------------------------------------------------------------------

qt_update()
{
        display_alert "Prepare Qt sources..." "${QT_GIT_ROOT}" "info"

	# make sure qt5 root directory exists
	mkdir -p ${QT_ROOT_DIR}

	if [ "${QT_UPDATE_SOURCES}" = yes ] ; then
		echo "Forcing full source update qtbase"
		rm -rf ${QTBASE_SRC_DIR}
	fi

	if [ -d ${QTBASE_SRC_DIR} ] && [ -d ${QTBASE_SRC_DIR}/.git ] ; then
		local old_url=$(git -C ${QTBASE_SRC_DIR} config --get remote.origin.url)
		if [ "${old_url}" != "${QTBASE_URL}" ] ; then
			rm -rf ${QTBASE_SRC_DIR}
		fi
	fi
	if [ -d ${QTBASE_SRC_DIR} ] && [ -d ${QTBASE_SRC_DIR}/.git ] ; then
		# update sources
		git -C ${QTBASE_SRC_DIR} fetch origin --tags
		[ $? -eq 0 ] || exit $?;

		git -C ${QTBASE_SRC_DIR} reset --hard
		git -C ${QTBASE_SRC_DIR} clean -fdx

		echo "Checking out branch: ${QT_BRANCH}"
		git -C ${QTBASE_SRC_DIR} checkout -B ${QT_BRANCH} origin/${QT_BRANCH}
		[ $? -eq 0 ] || exit $?;

		git -C ${QTBASE_SRC_DIR} pull
		[ $? -eq 0 ] || exit $?;
	else
		[[ -d ${QTBASE_SRC_DIR} ]] && rm -rf ${QTBASE_SRC_DIR}

		# clone sources
		git clone ${QTBASE_URL} -b ${QT_BRANCH} --tags ${QTBASE_SRC_DIR}
		[ $? -eq 0 ] || exit $?;
	fi

	if [ ! -z "${QT_TAG}" ] ; then
		echo "Checking out git tag: tags/${QT_TAG}"
		git -C ${QTBASE_SRC_DIR} checkout tags/${QT_TAG}
		[ $? -eq 0 ] || exit $?;
	fi

	for MODULE in "${QT_MODULES[@]}" ; do
		QT_MODULE_DIR=${QT_ROOT_DIR}/${MODULE}
		QT_MODULE_URL=${QT_GIT_ROOT}/${MODULE}.git

		if [ "${QT_UPDATE_SOURCES}" = yes ] ; then
			echo "Forcing full source update ${MODULE}"
			rm -rf ${QT_MODULE_DIR}
		fi

		if [ -d ${QT_MODULE_DIR} ] && [ -d ${QT_MODULE_DIR}/.git ] ; then
			local old_module_url=$(git -C ${QT_MODULE_DIR} config --get remote.origin.url)
			if [ "${old_module_url}" != "${QT_MODULE_URL}" ] ; then
				rm -rf ${QT_MODULE_DIR}
			fi
		fi
		if [ -d ${QT_MODULE_DIR} ] && [ -d ${QT_MODULE_DIR}/.git ] ; then
			# update sources
			git -C ${QT_MODULE_DIR} fetch origin --tags
			[ $? -eq 0 ] || exit $?;

			git -C ${QT_MODULE_DIR} reset --hard
			git -C ${QT_MODULE_DIR} clean -fdx

			echo "Checking out branch: ${QT_BRANCH}"
			git -C ${QT_MODULE_DIR} checkout -B $QT_BRANCH origin/$QT_BRANCH
			[ $? -eq 0 ] || exit $?;

			git -C ${QT_MODULE_DIR} pull
			[ $? -eq 0 ] || exit $?;
		else
			[[ -d ${QT_MODULE_DIR} ]] && rm -rf ${QT_MODULE_DIR}

			# clone sources
			git clone ${QT_MODULE_URL} -b $QT_BRANCH --tags ${QT_MODULE_DIR}
			[ $? -eq 0 ] || exit $?;
		fi

		if [ ! -z "${QT_TAG}" ] ; then
			echo "Checking out git tag: tags/${QT_TAG}"
			git -C ${QT_MODULE_DIR} checkout tags/$QT_TAG
			[ $? -eq 0 ] || exit $?;
		fi
        done

	display_alert "Sources ready" "release ${QT_RELEASE}" "info"
}

# ----------------------------------------------------------------------------

qt5_apply_patch()
{
	local PATCH_BASE_DIR=${QT_PATCH_BASE_DIR}
	local PATCH_COUNT=$(count_files "${PATCH_BASE_DIR}/qtbase/*.patch")

	echo "Applying patches from '${PATCH_BASE_DIR}' ..."

        # apply qtbase patches
	if [ $PATCH_COUNT -gt 0 ] ; then
		echo "Found ${PATCH_COUNT} patches for QtBase ..."
		for PATCHFILE in $PATCH_BASE_DIR/qtbase/*.patch; do
			echo "Applying patch '${PATCHFILE}' to 'qtbase'..."
			patch -d $QTBASE_SRC_DIR --batch -p1 -N < $PATCHFILE
			echo "Patched."
		done
	fi

        for MODULE in "${QT_MODULES[@]}" ; do
		PATCH_COUNT=$(count_files "${PATCH_BASE_DIR}/${MODULE}/*.patch")
		# apply module patches
		if [ $PATCH_COUNT -gt 0 ] ; then
			echo "Found ${PATCH_COUNT} patches for ${MODULE} ..."
			for PATCHFILE in $PATCH_BASE_DIR/$MODULE/*.patch; do
				echo "Applying patch '${PATCHFILE}' to '${MODULE}'..."
				patch -d ${QT_ROOT_DIR}/${MODULE} --batch -p1 -N < $PATCHFILE
				echo "Patched."
			done
		fi
	done

	echo "Done."
}

# ----------------------------------------------------------------------------

qt5_make_qtbase()
{
	display_alert "Selected toolchain:" "${QT_CROSS_COMPILE}gcc" "ext"

	mkdir -p $QTBASE_OUT_DIR
        cd $QTBASE_OUT_DIR

        if [ "${QT_FORCE_REBUILD}" = yes ] ; then
		echo "Force rebuild qtbase"
		rm -rf ./*
	fi

        # prepare prefix directories
        mkdir -p ${QT_HOST_PREFIX}
        mkdir -p ${QT_EXT_PREFIX}
        rm -rf ${QT_HOST_PREFIX}/*
        rm -rf ${QT_EXT_PREFIX}/*

        echo "Configure qtbase..."


	export PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1
	${QTBASE_SRC_DIR}/configure -v \
			-silent \
			-release \
			-opensource -confirm-license \
			-device ${QT_DEVICE_CONFIG} \
			-device-option CROSS_COMPILE=${QT_CROSS_COMPILE} \
			-device-option LINUX_PLATFORM=${LINUX_PLATFORM} \
			-device-option TOOLCHAIN_INCDIR="${QT_TOOLCHAIN_INCDIR}" \
			-device-option TOOLCHAIN_LIBDIR="${QT_TOOLCHAIN_LIBDIR}" \
			-sysroot ${SYSROOT_DIR} \
			-no-gcc-sysroot \
			-hostprefix ${QT_HOST_PREFIX} \
			-extprefix ${QT_EXT_PREFIX} \
			-make libs \
			-nomake examples \
			-nomake tests \
			-no-pch \
			-no-use-gold-linker \
			-no-openvg \
			-no-cups \
			${QT_OPENGL_OPTION} \
			${QT_XCB_OPTION} \
			-system-zlib \
			-system-libjpeg \
			-system-libpng \
			-system-freetype \
			-system-pcre \
			-system-harfbuzz \
			-no-openssl \
			-no-sql-db2 -no-sql-ibase -no-sql-mysql -no-sql-oci -no-sql-odbc -no-sql-psql -no-sql-tds -no-sql-sqlite -no-sql-sqlite2

        echo "Configured."

	echo "Making qtbase..."

        chrt -i 0 make -j${HOST_CPU_CORES}
	[ $? -eq 0 ] || exit $?;

        make install

        echo "Make finished."
}

# ----------------------------------------------------------------------------

qt5_make_modules()
{
	for MODULE in "${QT_MODULES[@]}" ; do

		echo "Making module '$MODULE'..."
		QT_MODULE_SRC_DIR=${QT_ROOT_DIR}/${MODULE}
		QT_MODULE_BUILD_DIR=${QT_BUILD_DIR}/${MODULE}

		mkdir -p ${QT_MODULE_BUILD_DIR}
		cd ${QT_MODULE_BUILD_DIR}

		if [ "${QT_FORCE_REBUILD}" = yes ] ; then
			echo "Force rebuild '${MODULE}'"
			rm -rf ./*
		else
			# otherwise delete only makefiles
			find ./ -type f -name Makefile -exec rm -f {} \;
		fi

		${QT_QMAKE} -makefile ${QT_MODULE_SRC_DIR}/

		chrt -i 0 make -j${HOST_CPU_CORES}
		[ $? -eq 0 ] || exit $?;

		make install

		echo "Make finished."
	done
}

# ----------------------------------------------------------------------------

qt5_fix_pkgconfig()
{
	local PREFIX=`echo "${QT_TARGET_PREFIX}" | sed -e 's/\//\\\\\//g'`
	local EXT_PREFIX=`echo "${QT_EXT_PREFIX}" | sed -e 's/\//\\\\\//g'`
	local SRC="prefix=$EXT_PREFIX"
	local DST="prefix=$PREFIX"

	for PCFILE in ${QT_EXT_PREFIX}/lib/pkgconfig/*.pc ; do
	    sed -i -e 's/'"$SRC"'/'"$DST"'/g' $PCFILE
	done
}

# ----------------------------------------------------------------------------

qt5_deploy()
{
	echo "Deploy QT5 to target system..."

	mkdir -p ${QT5_DEB_DIR}
	dpkg -x ${QT5_DEB_PKG_FILE} ${QT5_DEB_DIR} 2> /dev/null
	mkdir -p ${SYSROOT_DIR}${QT_TARGET_LOCATION}
	rsync -az ${QT5_DEB_DIR}${QT_TARGET_PREFIX} ${SYSROOT_DIR}${QT_TARGET_LOCATION}
	${LIBDIR}/make-relativelinks.sh $SYSROOT_DIR
	rm -rf ${QT5_DEB_DIR}

	cp ${QT5_DEB_PKG_FILE} ${R}/tmp/
	chroot_exec dpkg -i /tmp/${QT5_DEB_PKG}.deb
	rm -f ${R}/tmp/${QT5_DEB_PKG}.deb

        echo "Done."
}

# ----------------------------------------------------------------------------

qt5_deb_pkg()
{
	echo "Create QT5 deb package..."

	mkdir -p ${QT5_DEB_DIR}
	rm -rf ${QT5_DEB_DIR}/*

	mkdir ${QT5_DEB_DIR}/DEBIAN

	cat <<-EOF > ${QT5_DEB_DIR}/DEBIAN/control
Package: ${QT5_DEB_PKG}
Version: ${QT5_DEB_PKG_VER}
Maintainer: ${MAINTAINER_NAME} <${MAINTAINER_EMAIL}>
Architecture: all
Priority: optional
Description: This package provides the Qt5 libraries
EOF

	cat <<-EOF > ${QT5_DEB_DIR}/DEBIAN/postinst
#!/bin/sh

set -e

case "\$1" in
  configure)
    echo "${QT_TARGET_PREFIX}/lib" > /etc/ld.so.conf.d/qt5.conf
    ldconfig -X
    ;;
esac

exit 0
EOF

	chmod +x ${QT5_DEB_DIR}/DEBIAN/postinst

	mkdir -p ${QT5_DEB_DIR}${QT_TARGET_LOCATION}
	rsync -az ${QT_EXT_PREFIX} ${QT5_DEB_DIR}${QT_TARGET_LOCATION}

	cp ${QTBASE_OUT_DIR}/config.summary ${QT5_DEB_DIR}${QT_TARGET_PREFIX}

	dpkg-deb -z0 -b ${QT5_DEB_DIR} ${QT5_DEB_PKG_FILE}
	[ $? -eq 0 ] || exit $?;

	rm -rf $QT5_DEB_DIR

	echo "Done."
}

# ----------------------------------------------------------------------------

if [ "${ENABLE_QT}" = yes ] && [ -n "${QT_DEVICE_CONFIG}" ] ; then

	if [[ ${CLEAN} =~ (^|,)qt(,|$) ]] ; then
		rm -f ${QT5_DEB_PKG_FILE}
	fi

	if [ ! -f ${QT5_DEB_PKG_FILE} ] ; then

		echo -n -e "\n*** Build Settings ***\n"
		set -x
		# force update sources
		QT_UPDATE_SOURCES=${QT_UPDATE_SOURCES:="no"}
		# go for a full rebuild
		QT_FORCE_REBUILD=${QT_FORCE_REBUILD:="yes"}
		set +x

		qt_update

		qt5_apply_patch

		qt5_make_qtbase

		qt5_make_modules

		qt5_fix_pkgconfig

		qt5_deb_pkg
	fi

	qt5_deploy
else
	echo "Skip."
fi
