#!/bin/bash

DST_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

git -C $DST_DIR add mkspecs/

git -C $DST_DIR commit -m "qtbase: Add mkspec for Raspberry Pi3 64bit"
rm -f *.patch

git -C $DST_DIR format-patch -1
