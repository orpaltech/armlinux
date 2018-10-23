#!/bin/bash

DST_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


git -C $DST_DIR add mkspecs/devices/linux-rasp-pi2-g++/
git -C $DST_DIR add mkspecs/devices/linux-rasp-pi3-g++/
git -C $DST_DIR add mkspecs/devices/linux-rasp-pi3-vc4-g++/


git -C $DST_DIR commit -m "qtbase: Fix mkspecs for Raspberry-Pi"

rm -f *.patch

git -C $DST_DIR format-patch -1
