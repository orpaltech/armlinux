#!/bin/bash

DST_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

git -C $DST_DIR add mkspecs/

git -C $DST_DIR commit -m "qtbase: Add mkspec for Allwinner sun50i-a64 with fb"

rm -f *.patch

git -C $DST_DIR format-patch -1
