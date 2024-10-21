#!/bin/bash

DST_DIR=$(pwd)
#$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DST_DIR/../common.sh
source $DST_DIR/patch.info

readarray -t filenames < $DST_DIR/CHANGED_FILES/$REPO/files1-$VER

rm -rf $DST_DIR/.git/
git -C $DST_DIR init

for filen in ${filenames[@]}
do
  git -C $SRC_DIR checkout $filen
  dirn=$(dirname "${filen}")
  [[ -n "${dirn}" ]] && mkdir -p $DST_DIR/$dirn
  cp $SRC_DIR/$filen	$DST_DIR/$dirn/
  git -C $DST_DIR add $filen
done

git -C $DST_DIR commit -m "initial commit"