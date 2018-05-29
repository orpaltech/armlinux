#!/bin/bash

DST_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DST_DIR/../common.sh


git -C $SRC_DIR checkout sound/soc/sunxi/Kconfig
git -C $SRC_DIR checkout sound/soc/sunxi/Makefile
git -C $SRC_DIR checkout sound/soc/sunxi/sun4i-i2s.c
git -C $SRC_DIR checkout sound/soc/codecs/wm8731.c
git -C $SRC_DIR checkout sound/soc/codecs/wm8731.h


mkdir -p $DST_DIR/sound/soc/sunxi/
mkdir -p $DST_DIR/sound/soc/codecs/


cp $SRC_DIR/sound/soc/sunxi/Kconfig	$DST_DIR/sound/soc/sunxi/
cp $SRC_DIR/sound/soc/sunxi/Makefile	$DST_DIR/sound/soc/sunxi/
cp $SRC_DIR/sound/soc/sunxi/sun4i-i2s.c	$DST_DIR/sound/soc/sunxi/
cp $SRC_DIR/sound/soc/codecs/wm8731.c	$DST_DIR/sound/soc/codecs/
cp $SRC_DIR/sound/soc/codecs/wm8731.h	$DST_DIR/sound/soc/codecs/


rm -rf $DST_DIR/.git/
git -C $DST_DIR init


git -C $DST_DIR add sound/soc/sunxi/Kconfig
git -C $DST_DIR add sound/soc/sunxi/Makefile
git -C $DST_DIR add sound/soc/sunxi/sun4i-i2s.c
git -C $DST_DIR add sound/soc/codecs/wm8731.c
git -C $DST_DIR add sound/soc/codecs/wm8731.h

git -C $DST_DIR commit -m "initial commit"
