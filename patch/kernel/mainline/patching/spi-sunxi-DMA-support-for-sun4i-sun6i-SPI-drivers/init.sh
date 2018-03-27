#!/bin/bash

DST_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DST_DIR/../common.sh

git -C $SRC_DIR checkout drivers/spi/spi-sun4i.c
git -C $SRC_DIR checkout drivers/spi/spi-sun6i.c
git -C $SRC_DIR checkout drivers/spi/spi.c

mkdir -p $DST_DIR/drivers/spi/


cp $SRC_DIR/drivers/spi/spi-sun4i.c	$DST_DIR/drivers/spi/
cp $SRC_DIR/drivers/spi/spi-sun6i.c	$DST_DIR/drivers/spi/
cp $SRC_DIR/drivers/spi/spi.c		$DST_DIR/drivers/spi/


rm -rf $DST_DIR/.git/
git -C $DST_DIR init


git -C $DST_DIR add drivers/spi/spi-sun4i.c
git -C $DST_DIR add drivers/spi/spi-sun6i.c
git -C $DST_DIR add drivers/spi/spi.c

git -C $DST_DIR commit -m "initial commit"
