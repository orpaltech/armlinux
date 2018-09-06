#!/bin/bash


SRCDIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
PWD=$(pwd)
TARGET_DIR=$1

cd $SRCDIR

# adjust symlinks to be relative
if [ ! -f ./sysroot-relativelinks.py ] ; then
        wget "https://raw.githubusercontent.com/riscv/riscv-poky/master/scripts/sysroot-relativelinks.py"
        chmod +x ./sysroot-relativelinks.py
fi
./sysroot-relativelinks.py $TARGET_DIR

# get back to directory
cd $PWD
