#!/bin/bash

DST_DIR=$(pwd)
SCRIPT_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
. $SCRIPT_DIR/common.sh


cp -v -r ${DST_DIR}/CHANGED_FILES/${REPO}/${VER}/.	${DST_DIR}/

if [ -f $DST_DIR/copy.sh ] ; then
. $DST_DIR/copy.sh
fi
