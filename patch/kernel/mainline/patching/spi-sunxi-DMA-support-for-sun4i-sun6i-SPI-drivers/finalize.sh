#!/bin/bash

DST_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

git -C $DST_DIR add drivers/spi/*.c

git -C $DST_DIR commit -m "spi: sunxi: DMA support for sun4i,sun6i SPI drivers"

rm -f *.patch

git -C $DST_DIR format-patch -1

