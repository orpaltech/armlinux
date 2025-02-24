#!/bin/bash

DST_DIR=$(pwd)
. $DST_DIR/../common.sh


cp -v -r ${DST_DIR}/CHANGED_FILES/${REPO}/${VER}/.	${DST_DIR}/

if [ -f $DST_DIR/copy.sh ] ; then
. $DST_DIR/copy.sh
fi
