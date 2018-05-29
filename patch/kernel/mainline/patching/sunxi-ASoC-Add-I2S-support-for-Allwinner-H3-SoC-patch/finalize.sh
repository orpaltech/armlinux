#!/bin/bash

DST_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


git -C $DST_DIR add sound/soc/sunxi/Kconfig
git -C $DST_DIR add sound/soc/sunxi/Makefile
git -C $DST_DIR add sound/soc/sunxi/*.h
git -C $DST_DIR add sound/soc/sunxi/*.c
git -C $DST_DIR add sound/soc/codecs/*.h
git -C $DST_DIR add sound/soc/codecs/*.c

git -C $DST_DIR commit -m "sunxi: ASoC: Add I2S support for Allwinner H3 SoC"


rm -f *.patch


git -C $DST_DIR format-patch -1
