#
# Build TSLIB - Touchscreen access library
#

TSLIB_URL="https://github.com/kergoth/tslib.git"
TSLIB_BRANCH="master"

TSLIB_SRC_DIR=$EXTRADIR/tslib
TSLIB_OUT_DIR=$TSLIB_SRC_DIR/build/$LINUX_PLATFORM

TSLIB_FORCE_UPDATE="yes"

TSLIB_PREFIX=/usr

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
		git -C $TSLIB_SRC_DIR fetch origin --tags

		git -C $TSLIB_SRC_DIR reset --hard
		git -C $TSLIB_SRC_DIR clean -fd

		git -C $TSLIB_SRC_DIR checkout -B $TSLIB_BRANCH origin/$TSLIB_BRANCH
	else
		[[ -d $TSLIB_SRC_DIR ]] && rm -rf $TSLIB_SRC_DIR

		# clone sources
		git clone $TSLIB_URL -b $TSLIB_BRANCH	$TSLIB_SRC_DIR
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

	mkdir -p ./dist
	rm -rf ./dist/*

	CC="${CROSS_COMPILE}gcc" CXX="${CROSS_COMPILE}g++" \
		$TSLIB_SRC_DIR/configure \
				--prefix=$TSLIB_PREFIX \
				--host=$LINUX_PLATFORM

	echo "Making TSLIB..."

	chrt -i 0 make -j${NUM_CPU_CORES}
	[ $? -eq 0 ] || exit $?;


	make DESTDIR="${TSLIB_OUT_DIR}/dist" install

	echo "Make finished."
}

tslib_deploy()
{
	echo "Deploying TSLIB..."

	rsync -az ${TSLIB_OUT_DIR}/dist${TSLIB_PREFIX}/	${SYSROOT_DIR}${TSLIB_PREFIX}
	${LIBDIR}/make-relativelinks.sh $SYSROOT_DIR
	rsync -az ${TSLIB_OUT_DIR}/dist${TSLIB_PREFIX}/	${R}${TSLIB_PREFIX}

	echo "Done."
}

# ----------------------------------------------------------------------------

tslib_update

tslib_build

tslib_deploy
