#!/bin/bash

DST_DIR=$(pwd)
SCRIPT_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
. $SCRIPT_DIR/common.sh
. $DST_DIR/patch.info

git -C $SRC_DIR checkout -f tags/$TAG

if [ -f $DST_DIR/CHANGED_FILES/$REPO/files1-$VER ] ; then
  files1=$DST_DIR/CHANGED_FILES/$REPO/files1-$VER
else
  files1=$DST_DIR/CHANGED_FILES/$REPO/files1
fi
mapfile -t filenames < $files1

rm -rf $DST_DIR/.git/
git -C $DST_DIR init
git -C $DST_DIR branch -m master

for filen in ${filenames[@]}
do
  git -C $SRC_DIR checkout $filen
  dirn=$(dirname "${filen}")
  [[ -n "${dirn}" ]] && mkdir -p $DST_DIR/$dirn
  cp $SRC_DIR/$filen	$DST_DIR/$dirn/
  git -C $DST_DIR add $filen
done

git -C $DST_DIR commit -m "initial commit"
