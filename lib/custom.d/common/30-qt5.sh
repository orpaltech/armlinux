#
# Build Qt5 framework
#

# force clone the remote repository
QT5_FORCE_UPDATE="yes"

# remove all binaries and intermediate files and go for full rebuild
QT5_FORCE_REBUILD="yes"

QT5_GIT_ROOT="git://code.qt.io/qt"
QT5_RELEASE="5.11"
QT5_BRANCH="${QT5_RELEASE}"
QT5_TAG=""
QT5_MODULES=("qtxmlpatterns" "qtimageformats" "qtsvg" "qtscript" "qtdeclarative" "qtquickcontrols" "qtquickcontrols2" "qtcharts" "qtvirtualkeyboard")
QT5_ROOT_DIR=${EXTRADIR}/qt5-build/qt5
QT5_DEVCFG_DIR=${QT5_ROOT_DIR}/build/${QT5_DEVICE_CONFIG}
QTBASE_URL=${QT5_GIT_ROOT}/qtbase.git
QTBASE_SRC_DIR=${QT5_ROOT_DIR}/qtbase
QTBASE_OUT_DIR=${QT5_DEVCFG_DIR}/qtbase

# version directory is usually named as branch
QT5_CUSTOM_VER=$QT5_RELEASE
# here we keep resources needed for customizing Qt5
QT5_CUSTOM_ROOT=${SRCDIR}/custom.d/common/qt5/${QT5_CUSTOM_VER}

QT5_TARGET_PREFIX=/usr/local/qt5pi
QT5_HOST_PREFIX=${QT5_DEVCFG_DIR}/qt5host
QT5_EXT_PREFIX=${QT5_DEVCFG_DIR}/qt5pi
QT5_QMAKE=${QT5_HOST_PREFIX}/bin/qmake

[[ -z "${QT5_TAG}" ]] && QT5_DEB_VER="${QT5_RELEASE}" || QT5_DEB_VER="${QT5_RELEASE}-tag-${QT5_TAG}"
QT5_DEB_PKG_VER="${QT5_DEB_VER}-${QT5_DEVICE_CONFIG}-${VERSION}"
QT5_DEB_PKG="qt-${QT5_DEB_PKG_VER}"
QT5_DEB_DIR=$BASEDIR/debs/$QT5_DEB_PKG-deb

# ----------------------------------------------------------------------------

qt5_update()
{
        echo "Prepare QT5 sources..."

	# make sure qt5 root directory exists
	mkdir -p $QT5_ROOT_DIR

	if [ "${QT5_FORCE_UPDATE}" = yes ] ; then
		echo "Forcing update qtbase"
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
                git -C $QTBASE_SRC_DIR fetch --tags --recurse-submodules
                git -C $QTBASE_SRC_DIR reset --hard
                git -C $QTBASE_SRC_DIR clean -fd

		echo "Checking out branch: ${QT5_BRANCH}"
		git -C $QTBASE_SRC_DIR checkout -B origin/$QT5_BRANCH
        else
                rm -rf $QTBASE_SRC_DIR

                # clone sources
                git clone $QTBASE_URL -b $QT5_BRANCH $QTBASE_SRC_DIR
        fi

	if [ ! -z "${QT5_TAG}" ] ; then
		echo "Checking out git tag: tags/${QT5_TAG}"
		git -C $QTBASE_SRC_DIR checkout tags/$QT5_TAG
	fi

	for MODULE in "${QT5_MODULES[@]}" ; do
		QT5_MODULE_DIR=${QT5_ROOT_DIR}/${MODULE}
		QT5_MODULE_URL=${QT5_GIT_ROOT}/${MODULE}.git

		if [ "${QT5_FORCE_UPDATE}" = yes ] ; then
			echo "Forcing update ${MODULE}"
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
                        git -C $QT5_MODULE_DIR fetch --tags
                        git -C $QT5_MODULE_DIR reset --hard
                        git -C $QT5_MODULE_DIR clean -fd

			echo "Checking out branch: ${QT5_BRANCH}"
			git -C $QT5_MODULE_DIR checkout -B origin/$QT5_BRANCH
                else
                        rm -rf $QT5_MODULE_DIR

                        # clone sources
                        git clone $QT5_MODULE_URL -b $QT5_BRANCH $QT5_MODULE_DIR
                fi

		if [ ! -z "${QT5_TAG}" ] ; then
			echo "Checking out git tag: tags/${QT5_TAG}"
			git -C $QT5_MODULE_DIR checkout tags/$QT5_TAG
		fi
        done

        echo "Sources ready."
}

# ----------------------------------------------------------------------------

qt5_apply_patch()
{
	PATCH_BASE_DIR=$QT5_CUSTOM_ROOT/patches
	PATCH_COUNT=$(ls $PATCH_BASE_DIR/qtbase/*.patch 2> /dev/null | wc -l)

        # apply qtbase patches
	if [ $PATCH_COUNT -gt 0 ] ; then
            for PATCHFILE in $PATCH_BASE_DIR/qtbase/*.patch; do
                echo "Applying patch '${PATCHFILE}' to 'qtbase'..."
                patch -d $QTBASE_SRC_DIR --batch -p1 -N < $PATCHFILE
                echo "Patched."
            done
	fi

        for MODULE in "${QT5_MODULES[@]}" ; do
		PATCH_COUNT=$(ls $PATCH_BASE_DIR/$MODULE/*.patch 2> /dev/null | wc -l)

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

	${QTBASE_SRC_DIR}/configure \
                        -release \
			-silent \
                        -opensource \
			-confirm-license \
                        -device $QT5_DEVICE_CONFIG \
                        -device-option CROSS_COMPILE=$CROSS_COMPILE \
                        -sysroot $SYSROOT_DIR \
                        -prefix $QT5_TARGET_PREFIX \
                        -hostprefix $QT5_HOST_PREFIX \
                        -extprefix $QT5_EXT_PREFIX \
			-optimized-qmake \
                        -v \
			-make libs \
                        -nomake examples \
			-nomake tests \
                        -no-pch \
                        -no-use-gold-linker \
                        -no-xcb \
                        $QT5_OPENGL_OPTION \
                        -no-openssl \
                        -system-zlib \
                        -system-libjpeg \
                        -system-libpng \
                        -system-freetype \
                        -no-sql-db2 -no-sql-ibase -no-sql-mysql -no-sql-oci -no-sql-odbc -no-sql-psql \
                        -no-sql-tds -no-sql-sqlite -no-sql-sqlite2 \
		| tee "${QTBASE_OUT_DIR}/.configure_output"

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

	mkdir -p $QT5_DEB_DIR
	dpkg -x $BASEDIR/debs/$QT5_DEB_PKG.deb $QT5_DEB_DIR 2> /dev/null
	mkdir -p $SYSROOT_DIR/usr/local
	rsync -az $QT5_DEB_DIR/usr/local/qt5pi $SYSROOT_DIR/usr/local
	rm -rf $QT5_DEB_DIR

	cp $BASEDIR/debs/$QT5_DEB_PKG.deb ${R}/tmp/
	chroot_exec dpkg -i /tmp/$QT5_DEB_PKG.deb
	rm -f ${R}/tmp/$QT5_DEB_PKG.deb

        echo "Done."
}

# ----------------------------------------------------------------------------

qt5_deb_pkg()
{
	echo "Create QT5 deb package..."

	mkdir -p $QT5_DEB_DIR
	rm -rf $QT5_DEB_DIR/*

	mkdir $QT5_DEB_DIR/DEBIAN

	cat <<-EOF > $QT5_DEB_DIR/DEBIAN/control
	Package: $QT5_DEB_PKG
	Version: $QT5_DEB_PKG_VER
	Maintainer: $MAINTAINER_NAME <$MAINTAINER_EMAIL>
	Architecture: all
	Priority: optional
	Description: This package provides the Qt5 libraries
	EOF

	mkdir -p $QT5_DEB_DIR/usr/local
	rsync -az $QT5_EXT_PREFIX $QT5_DEB_DIR/usr/local
	cp $QTBASE_OUT_DIR/.configure_output $QT5_DEB_DIR/usr/local/qt5pi

	dpkg-deb -z0 -b $QT5_DEB_DIR $BASEDIR/debs/$QT5_DEB_PKG.deb 2> /dev/null
	[ $? -eq 0 ] || exit $?;

	rm -rf $QT5_DEB_DIR

	echo "Done."
}

# ----------------------------------------------------------------------------

if [ ! -z "${QT5_DEVICE_CONFIG}" ] ; then

  if [[ $CLEAN_OPTIONS =~ (^|,)"qt5"(,|$) ]] ; then
	rm -f "${BASEDIR}/debs/${QT5_DEB_PKG}.deb"
  fi

  if [ ! -f "${BASEDIR}/debs/${QT5_DEB_PKG}.deb" ] ; then
	qt5_update

	qt5_apply_patch

	qt5_make_qtbase

	qt5_make_modules

	qt5_fix_pkgconfig

	qt5_deb_pkg
  fi

  qt5_deploy
fi
