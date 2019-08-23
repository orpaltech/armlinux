#
# Build Qt5 framework
#

# force clone the remote repository
QT5_REFRESH_SOURCES=${QT5_REFRESH_SOURCES:="no"}

# remove all intermediate files and go for a full rebuild
QT5_FORCE_REBUILD=${QT5_FORCE_REBUILD:="yes"}

QT5_GIT_ROOT="git://code.qt.io/qt"
QT5_RELEASE="5.13"
QT5_BRANCH="${QT5_RELEASE}"
QT5_TAG=""
QT5_MODULES=("qtxmlpatterns" "qtimageformats" "qtgraphicaleffects" "qtsvg" "qtscript" "qtdeclarative" "qtquickcontrols" "qtquickcontrols2" "qtcharts" "qtvirtualkeyboard")
QT5_ROOT_DIR=${EXTRADIR}/qt5-build/qt5
QT5_DEVCFG_DIR=${QT5_ROOT_DIR}/build/${QT5_DEVICE_CONFIG}
QTBASE_URL=${QT5_GIT_ROOT}/qtbase.git
QTBASE_SRC_DIR=${QT5_ROOT_DIR}/qtbase
QTBASE_OUT_DIR=${QT5_DEVCFG_DIR}/qtbase

# version directory is named after the branch
QT5_CUSTOM_VER="${QT5_RELEASE}"
# here we keep resources needed for QT5 customization
QT5_CUSTOM_ROOT=${FILES_DIR}/qt5/${QT5_CUSTOM_VER}

QT5_TARGET_LOCATION="/usr/local"
QT5_TARGET_PREFIX=${QT5_TARGET_LOCATION}/qt5pi
QT5_HOST_PREFIX=${QT5_DEVCFG_DIR}/qt5host
QT5_EXT_PREFIX=${QT5_DEVCFG_DIR}/qt5pi
QT5_QMAKE=${QT5_HOST_PREFIX}/bin/qmake

[[ -z "${QT5_TAG}" ]] && QT5_DEB_VER="${QT5_RELEASE}" || QT5_DEB_VER="${QT5_RELEASE}-tag-${QT5_TAG}"
QT5_DEB_PKG_VER="${QT5_DEB_VER}-${QT5_DEVICE_CONFIG}-${CONFIG}-${VERSION}"
QT5_DEB_PKG="qt-${QT5_DEB_PKG_VER}"
QT5_DEB_DIR="${DEBS_DIR}/${QT5_DEB_PKG}-deb"

QT5_CROSS_COMPILE=${QT5_CROSS_COMPILE:="$CROSS_COMPILE"}

[[ "${ENABLE_X11}" = "yes" ]] && QT5_XCB_OPTION="-system-xcb" || QT5_XCB_OPTION="-no-xcb"

# ----------------------------------------------------------------------------

qt5_update()
{
        display_alert "Prepare QT5 sources..." "${QT5_GIT_ROOT}" "info"

	# make sure qt5 root directory exists
	mkdir -p $QT5_ROOT_DIR

	if [ "${QT5_REFRESH_SOURCES}" = yes ] ; then
		echo "Forcing full source update qtbase"
		rm -rf $QTBASE_SRC_DIR
	fi

	if [ -d $QTBASE_SRC_DIR ] && [ -d $QTBASE_SRC_DIR/.git ] ; then
                local OLD_URL=$(git -C $QTBASE_SRC_DIR config --get remote.origin.url)
                if [ "${OLD_URL}" != "${QTBASE_URL}" ] ; then
                        rm -rf $QTBASE_SRC_DIR
                fi
        fi
	if [ -d $QTBASE_SRC_DIR ] && [ -d $QTBASE_SRC_DIR/.git ] ; then
		# update sources
		git -C $QTBASE_SRC_DIR fetch origin --tags

		git -C $QTBASE_SRC_DIR reset --hard
		git -C $QTBASE_SRC_DIR clean -fdx

		echo "Checking out branch: ${QT5_BRANCH}"
		git -C $QTBASE_SRC_DIR checkout -B $QT5_BRANCH origin/$QT5_BRANCH
		git -C $QTBASE_SRC_DIR pull
	else
		[[ -d $QTBASE_SRC_DIR ]] && rm -rf $QTBASE_SRC_DIR

		# clone sources
		git clone $QTBASE_URL -b $QT5_BRANCH $QTBASE_SRC_DIR
		[ $? -eq 0 ] || exit $?;
	fi

	if [ ! -z "${QT5_TAG}" ] ; then
		echo "Checking out git tag: tags/${QT5_TAG}"
		git -C $QTBASE_SRC_DIR checkout tags/$QT5_TAG
	fi

	for MODULE in "${QT5_MODULES[@]}" ; do
		QT5_MODULE_DIR=${QT5_ROOT_DIR}/${MODULE}
		QT5_MODULE_URL=${QT5_GIT_ROOT}/${MODULE}.git

		if [ "${QT5_REFRESH_SOURCES}" = yes ] ; then
			echo "Forcing full source update ${MODULE}"
			rm -rf $QT5_MODULE_DIR
		fi

		if [ -d $QT5_MODULE_DIR ] && [ -d $QT5_MODULE_DIR/.git ] ; then
			local OLD_MODULE_URL=$(git -C $QT5_MODULE_DIR config --get remote.origin.url)
			if [ "${OLD_MODULE_URL}" != "${QT5_MODULE_URL}" ] ; then
				rm -rf $QT5_MODULE_DIR
			fi
		fi
		if [ -d $QT5_MODULE_DIR ] && [ -d $QT5_MODULE_DIR/.git ] ; then
			# update sources
			git -C $QT5_MODULE_DIR fetch origin --tags

			git -C $QT5_MODULE_DIR reset --hard
			git -C $QT5_MODULE_DIR clean -fdx

			echo "Checking out branch: ${QT5_BRANCH}"
			git -C $QT5_MODULE_DIR checkout -B $QT5_BRANCH origin/$QT5_BRANCH
			git -C $QT5_MODULE_DIR pull
		else
			[[ -d $QT5_MODULE_DIR ]] && rm -rf $QT5_MODULE_DIR

			# clone sources
			git clone $QT5_MODULE_URL -b $QT5_BRANCH $QT5_MODULE_DIR
			[ $? -eq 0 ] || exit $?;
		fi

		if [ ! -z "${QT5_TAG}" ] ; then
			echo "Checking out git tag: tags/${QT5_TAG}"
			git -C $QT5_MODULE_DIR checkout tags/$QT5_TAG
		fi
        done

	display_alert "Sources ready" "release ${QT5_RELEASE}" "info"
}

# ----------------------------------------------------------------------------

qt5_apply_patch()
{
	local PATCH_BASE_DIR=$QT5_CUSTOM_ROOT/patch
	local PATCH_COUNT=$(count_files "${PATCH_BASE_DIR}/qtbase/*.patch")

        # apply qtbase patches
	if [ $PATCH_COUNT -gt 0 ] ; then
            for PATCHFILE in $PATCH_BASE_DIR/qtbase/*.patch; do
                echo "Applying patch '${PATCHFILE}' to 'qtbase'..."
                patch -d $QTBASE_SRC_DIR --batch -p1 -N < $PATCHFILE
                echo "Patched."
            done
	fi

        for MODULE in "${QT5_MODULES[@]}" ; do
		PATCH_COUNT=$(count_files "${PATCH_BASE_DIR}/${MODULE}/*.patch")

                # apply module patches
		if [ $PATCH_COUNT -gt 0 ] ; then
                    for PATCHFILE in $PATCH_BASE_DIR/$MODULE/*.patch; do
                        echo "Applying patch '${PATCHFILE}' to '${MODULE}'..."
                        patch -d $QT5_ROOT_DIR/$MODULE --batch -p1 -N < $PATCHFILE
                        echo "Patched."
                    done
		fi
        done
}

# ----------------------------------------------------------------------------

qt5_make_qtbase()
{
	mkdir -p $QTBASE_OUT_DIR
        cd $QTBASE_OUT_DIR

        if [ "${QT5_FORCE_REBUILD}" = yes ] ; then
		echo "Force rebuild qtbase"
		rm -rf ./*
	fi

        # prepare prefix directories
        mkdir -p $QT5_HOST_PREFIX
        mkdir -p $QT5_EXT_PREFIX
        rm -rf $QT5_HOST_PREFIX/*
        rm -rf $QT5_EXT_PREFIX/*

        echo "Configure qtbase..."


	${QTBASE_SRC_DIR}/configure -v \
			-silent \
                        -release \
                        -opensource -confirm-license \
                        -device $QT5_DEVICE_CONFIG \
                        -device-option CROSS_COMPILE=$QT5_CROSS_COMPILE \
                        -sysroot $SYSROOT_DIR \
                        -hostprefix $QT5_HOST_PREFIX \
                        -extprefix $QT5_EXT_PREFIX \
			-make libs \
                        -nomake examples \
			-nomake tests \
                        -no-pch \
			-no-rpath \
                        -no-use-gold-linker \
                        -no-openvg \
			-no-cups \
                        $QT5_OPENGL_OPTION \
			$QT5_XCB_OPTION \
                        -no-openssl \
                        -system-zlib \
                        -system-libjpeg \
                        -system-libpng \
                        -system-freetype \
                        -no-sql-db2 -no-sql-ibase -no-sql-mysql -no-sql-oci -no-sql-odbc -no-sql-psql \
                        -no-sql-tds -no-sql-sqlite -no-sql-sqlite2


        echo "Configured."

	echo "Making qtbase..."

        chrt -i 0 make -j${NUM_CPU_CORES}
	[ $? -eq 0 ] || exit $?;

        make install

        echo "Make finished."
}

# ----------------------------------------------------------------------------

qt5_make_modules()
{
	for MODULE in "${QT5_MODULES[@]}" ; do

		echo "Making module '$MODULE'..."
		QT5_MODULE_DIR=$QT5_ROOT_DIR/$MODULE
		MODULE_BUILD_DIR=$QT5_DEVCFG_DIR/$MODULE

		mkdir -p $MODULE_BUILD_DIR
		cd $MODULE_BUILD_DIR

		if [ "${QT5_FORCE_REBUILD}" = yes ] ; then
			echo "Force rebuild '${MODULE}'"
			rm -rf ./*
		else
			# otherwise delete only makefiles
			find ./ -type f -name Makefile -exec rm -f {} \;
		fi

		$QT5_QMAKE -makefile $QT5_MODULE_DIR/

		chrt -i 0 make -j${NUM_CPU_CORES}
		[ $? -eq 0 ] || exit $?;

		make install

		echo "Make finished."
	done
}

# ----------------------------------------------------------------------------

qt5_fix_pkgconfig()
{
	local PREFIX=`echo "$QT5_TARGET_PREFIX" | sed -e 's/\//\\\\\//g'`
	local EXT_PREFIX=`echo "$QT5_EXT_PREFIX" | sed -e 's/\//\\\\\//g'`
	local SRC="prefix=$EXT_PREFIX"
	local DST="prefix=$PREFIX"

	for PCFILE in $QT5_EXT_PREFIX/lib/pkgconfig/*.pc ; do
	    sed -i -e 's/'"$SRC"'/'"$DST"'/g' $PCFILE
	done
}

# ----------------------------------------------------------------------------

qt5_deploy()
{
	echo "Deploy QT5 to target system..."

	mkdir -p ${QT5_DEB_DIR}
	dpkg -x ${BASEDIR}/debs/${QT5_DEB_PKG}.deb ${QT5_DEB_DIR} 2> /dev/null
	mkdir -p ${SYSROOT_DIR}${QT5_TARGET_LOCATION}
	rsync -az ${QT5_DEB_DIR}${QT5_TARGET_PREFIX} ${SYSROOT_DIR}${QT5_TARGET_LOCATION}
	${LIBDIR}/make-relativelinks.sh $SYSROOT_DIR
	rm -rf ${QT5_DEB_DIR}

	cp ${BASEDIR}/debs/${QT5_DEB_PKG}.deb ${R}/tmp/
	chroot_exec dpkg -i /tmp/${QT5_DEB_PKG}.deb
	rm -f ${R}/tmp/${QT5_DEB_PKG}.deb

        echo "Done."
}

# ----------------------------------------------------------------------------

qt5_deb_pkg()
{
	echo "Create QT5 deb package..."

	mkdir -p $QT5_DEB_DIR
	rm -rf ${QT5_DEB_DIR}/*

	mkdir ${QT5_DEB_DIR}/DEBIAN

	cat <<-EOF > ${QT5_DEB_DIR}/DEBIAN/control
Package: $QT5_DEB_PKG
Version: $QT5_DEB_PKG_VER
Maintainer: $MAINTAINER_NAME <$MAINTAINER_EMAIL>
Architecture: all
Priority: optional
Description: This package provides the Qt5 libraries
EOF

	cat <<-EOF > ${QT5_DEB_DIR}/DEBIAN/postinst
#!/bin/sh

set -e

case "\$1" in
  configure)
    echo "${QT5_TARGET_PREFIX}/lib" > /etc/ld.so.conf.d/qt5.conf
    ldconfig -X
    ;;
esac

exit 0
EOF

	chmod +x ${QT5_DEB_DIR}/DEBIAN/postinst

	mkdir -p ${QT5_DEB_DIR}${QT5_TARGET_LOCATION}
	rsync -az $QT5_EXT_PREFIX ${QT5_DEB_DIR}${QT5_TARGET_LOCATION}

	cp ${QTBASE_OUT_DIR}/config.summary ${QT5_DEB_DIR}${QT5_TARGET_PREFIX}

	dpkg-deb -z0 -b $QT5_DEB_DIR ${BASEDIR}/debs/${QT5_DEB_PKG}.deb
	[ $? -eq 0 ] || exit $?;

	rm -rf $QT5_DEB_DIR

	echo "Done."
}

# ----------------------------------------------------------------------------

if [ ! -z "${QT5_DEVICE_CONFIG}" ] ; then

  if [[ $CLEAN =~ (^|,)"qt5"(,|$) ]] ; then
	rm -f ${BASEDIR}/debs/${QT5_DEB_PKG}.deb
  fi

  if [ ! -f ${BASEDIR}/debs/${QT5_DEB_PKG}.deb ] ; then
	qt5_update

	qt5_apply_patch

	qt5_make_qtbase

	qt5_make_modules

	qt5_fix_pkgconfig

	qt5_deb_pkg
  fi

  qt5_deploy
fi
