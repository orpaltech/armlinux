#
# Build GDB server/libraries
#

# force download source code tarball
GDB_FORCE_UPDATE="no"

# remove all binaries and intermediate files and go for full rebuild
GDB_FORCE_REBUILD="no"

GDB_VERSION="8.1.1"
GDB_NAME="gdb-${GDB_VERSION}"

GDB_SRC_DIR=${EXTRADIR}/${GDB_NAME}
GDB_OUT_DIR=${GDB_SRC_DIR}/build/${LINUX_PLATFORM}

GDB_DEB_PKG_VER="${GDB_VERSION}-${DEBIAN_RELEASE_ARCH}-${SOC_FAMILY}-${VERSION}"
GDB_DEB_PKG="gdb-${GDB_DEB_PKG_VER}"
GDB_DEB_DIR=${BASEDIR}/debs/${GDB_DEB_PKG}-deb

GDB_PREFIX=/usr

# ----------------------------------------------------------------------------

gdb_get_source()
{
        if [ ! -d $GDB_SRC_DIR ] || [ "${GDB_FORCE_UPDATE}" = yes ] ; then
                echo "Download GDB sources..."

                rm -rf $GDB_SRC_DIR
                local TAR_PATH="${GDB_SRC_DIR}.tar.gz"
                [ ! -f $TAR_PATH ] && wget -O $TAR_PATH "http://ftp.gnu.org/gnu/gdb/${GDB_NAME}.tar.gz"
                tar -xvf $TAR_PATH -C "${EXTRADIR}/"
                rm -f $TAR_PATH

                echo "Done."
        fi
}

# ----------------------------------------------------------------------------

gdb_make()
{
        mkdir -p $GDB_OUT_DIR
        cd $GDB_OUT_DIR

        if [ "${GDB_FORCE_REBUILD}" = yes ] ; then
		echo "Forcing GDB rebuild"
		rm -rf ./*
	fi

	mkdir -p ./dist
	rm -rf ./dist/*

        echo "Configure GDB..."

        $GDB_SRC_DIR/configure \
                --prefix="${GDB_PREFIX}" \
                --host="${LINUX_PLATFORM}" \
                --with-build-sysroot="${SYSROOT_DIR}" \
		--verbose \
                CC="${DEV_GCC}" \
		CXX="${DEV_CXX}" \
                LD="${DEV_LD}" \
		LDFLAGS="-L/usr/lib/{LINUX_PLATFORM}/" \
                AS="${DEV_AS}" \
		AR="${DEV_AR}" \
		NM="${DEV_NM}" \
		STRIP="${DEV_STRIP}" \
                RANLIB="${DEV_RANLIB}" \
		READELF="${DEV_READELF}" \
                OBJCOPY="${DEV_OBJCOPY}" \
		OBJDUMP="${DEV_OBJDUMP}"
        echo "Done."

	echo "Making GDB..."

        chrt -i 0 make -j${NUM_CPU_CORES}
	[ $? -eq 0 ] || exit $?;

        make DESTDIR="${GDB_OUT_DIR}/dist" install

        echo "Make finished."
}

# ----------------------------------------------------------------------------

gdb_deploy()
{
        echo "Deploy GDB to target system..."

	mkdir -p $GDB_DEB_DIR
	dpkg -x ${BASEDIR}/debs/${GDB_DEB_PKG}.deb	$GDB_DEB_DIR	2> /dev/null
	rsync -az ${GDB_DEB_DIR}/	$SYSROOT_DIR
	${LIBDIR}/make-relativelinks.sh	${SYSROOT_DIR}${GDB_PREFIX}/lib
	rm -rf $GDB_DEB_DIR

	cp $BASEDIR/debs/${GDB_DEB_PKG}.deb	${R}/tmp/
	chroot_exec dpkg -i /tmp/${GDB_DEB_PKG}.deb
	rm -f ${R}/tmp/${GDB_DEB_PKG}.deb

	echo "Done."
}

# ----------------------------------------------------------------------------

gdb_deb_pkg()
{
	echo "Create gdb-${GDB_VERSION} deb package..."

	mkdir -p $GDB_DEB_DIR
	rm -rf $GDB_DEB_DIR/*

	mkdir $GDB_DEB_DIR/DEBIAN

	cat <<-EOF > $GDB_DEB_DIR/DEBIAN/control
	Package: $GDB_DEB_PKG
	Version: $GDB_DEB_PKG_VER
	Maintainer: $MAINTAINER_NAME <$MAINTAINER_EMAIL>
	Architecture: all
	Priority: optional
	Description: This package provides gdb-$GDB_VERSION
	EOF

        rsync -az $GDB_OUT_DIR/dist/	$GDB_DEB_DIR

        dpkg-deb -z0 -b $GDB_DEB_DIR	$BASEDIR/debs/$GDB_DEB_PKG.deb
        [ $? -eq 0 ] || exit $?;

        rm -rf $GDB_DEB_DIR

        echo "Done."
}

# ----------------------------------------------------------------------------

if [ ! -f ${BASEDIR}/debs/${GDB_DEB_PKG}.deb ] ; then
	echo "Building GDB..."

	gdb_get_source

	gdb_make

	gdb_deb_pkg

	echo "GDB build finished."
else
	echo "deb-package ${GDB_DEB_PKG} already exists."
fi

gdb_deploy
