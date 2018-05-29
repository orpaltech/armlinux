#!/bin/bash

TAG=$1
SRC_DIR=/home/sergey/Projects/armlinux/sources/linux-mainline/master

if [ -z "$TAG" ] ; then
  echo "error: no tag is given!"
  exit 1
fi

git -C ${SRC_DIR} checkout -f tags/${TAG}
