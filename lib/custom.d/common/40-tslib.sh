#
# Build TSLIB - Touchscreen access library
#

TSLIB_URL="https://github.com/kergoth/tslib.git"
TSLIB_BRANCH="master"

TSLIB_SRC_DIR=$EXTRADIR/tslib
TSLIB_OUT_DIR=$TSLIB_SRC_DIR/build/$LINUX_PLATFORM

TSLIB_FORCE_UPDATE=""

# ----------------------------------------------------------------------------

tslib_update()
{
	echo "Prepare TSLIB sources..."

	if [ "${TSLIB_FORCE_UPDATE}" = yes ] ; then
		echo "Forcing update TSLIB"
		rm -rf $TSLIB_SRC_DIR
        fi

	if [ -d $TSLIB_SRC_DIR ] && [ -d $TSLIB_SRC_DIR/.git ] ; then
		local OLD_URL=$(git -C $TSLIB_SRC_DIR config --get remote.origin.url)
		if [ "${OLD_URL}" != "${TSLIB_URL}" ] ; then
			rm -rf $TSLIB_SRC_DIR
		fi
	fi
	if [ -d $TSLIB_SRC_DIR ] && [ -d $TSLIB_SRC_DIR/.git ] ; then
		# update sources
		git -C $TSLIB_SRC_DIR fetch origin
		git -C $TSLIB_SRC_DIR reset --hard origin/$TSLIB_BRANCH
		git -C $TSLIB_SRC_DIR clean -fd
	else
		rm -rf $TSLIB_SRC_DIR

		# clone sources
		git clone $TSLIB_URL -b $TSLIB_BRANCH $TSLIB_SRC_DIR
	fi
}

# ----------------------------------------------------------------------------

tslib_build()
{
	cd $TSLIB_SRC_DIR

	[[ ! -f ./configure ]] && ./autogen.sh

	mkdir -p $TSLIB_OUT_DIR
	rm -rf $TSLIB_OUT_DIR/*
	cd $TSLIB_OUT_DIR

	CC="${CROSS_COMPILE}gcc" \
	CXX="${CROSS_COMPILE}g++" \
		$TSLIB_SRC_DIR/configure \
				--prefix=/usr/local \
				--host=$LINUX_PLATFORM

	echo "Making TSLIB..."

	chrt -i 0 make -j${NUM_CPU_CORES}
	[ $? -eq 0 ] || exit $?;

	make DESTDIR="${R}" install

	echo "Make finished."
}

# ----------------------------------------------------------------------------

tslib_update

tslib_build
