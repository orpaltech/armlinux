#!/bin/bash

DST_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DST_DIR/../qtbase.sh

git -C $SRC_DIR checkout mkspecs/devices/linux-rasp-pi2-g++/qmake.conf
git -C $SRC_DIR checkout mkspecs/devices/linux-rasp-pi3-g++/qmake.conf
git -C $SRC_DIR checkout mkspecs/devices/linux-rasp-pi3-vc4-g++/qmake.conf


mkdir -p $DST_DIR/mkspecs/devices/linux-rasp-pi2-g++/
mkdir -p $DST_DIR/mkspecs/devices/linux-rasp-pi3-g++/
mkdir -p $DST_DIR/mkspecs/devices/linux-rasp-pi3-vc4-g++/


cp $SRC_DIR/mkspecs/devices/linux-rasp-pi2-g++/qmake.conf	$DST_DIR/mkspecs/devices/linux-rasp-pi2-g++/
cp $SRC_DIR/mkspecs/devices/linux-rasp-pi3-g++/qmake.conf	$DST_DIR/mkspecs/devices/linux-rasp-pi3-g++/
cp $SRC_DIR/mkspecs/devices/linux-rasp-pi3-vc4-g++/qmake.conf	$DST_DIR/mkspecs/devices/linux-rasp-pi3-vc4-g++/


rm -rf $DST_DIR/.git/
git -C $DST_DIR init


git -C $DST_DIR add mkspecs/devices/linux-rasp-pi2-g++/qmake.conf
git -C $DST_DIR add mkspecs/devices/linux-rasp-pi3-g++/qmake.conf
git -C $DST_DIR add mkspecs/devices/linux-rasp-pi3-vc4-g++/qmake.conf


git -C $DST_DIR commit -m "initial commit"
