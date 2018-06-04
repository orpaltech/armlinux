#
# Prepare device sysroot for crosscompile (RPi2 2/3 script)
#

SYSROOT_DIR=$EXTRADIR/boards/$BOARD/sysroot

mkdir -p $SYSROOT_DIR
rm -rf $SYSROOT_DIR/*
mkdir $SYSROOT_DIR/usr $SYSROOT_DIR/opt
rsync -az ${R}/lib $SYSROOT_DIR
rsync -az ${R}/usr/include $SYSROOT_DIR/usr
rsync -az ${R}/usr/lib $SYSROOT_DIR/usr
if [ -d "${R}/opt/vc" ] ; then
	rsync -az ${R}/opt/vc $SYSROOT_DIR/opt
fi

# adjust symlinks to be relative
cd $EXTRADIR/boards

if [ ! -f "./sysroot-relativelinks.py" ] ; then
	wget "https://raw.githubusercontent.com/riscv/riscv-poky/master/scripts/sysroot-relativelinks.py"
	chmod +x ./sysroot-relativelinks.py
fi
./sysroot-relativelinks.py $SYSROOT_DIR
