#!/bin/bash

DST_DIR=$( pwd )
SCRIPT_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
. $SCRIPT_DIR/common.sh
. $DST_DIR/patch.info

if [ -f $DST_DIR/CHANGED_FILES/$REPO/files1-$VER ] ; then
  files1=$DST_DIR/CHANGED_FILES/$REPO/files1-$VER
else
  files1=$DST_DIR/CHANGED_FILES/$REPO/files1
fi
if [ -f $DST_DIR/CHANGED_FILES/$REPO/files2-$VER ] ; then
  files2=$DST_DIR/CHANGED_FILES/$REPO/files2-$VER
else
  files2=$DST_DIR/CHANGED_FILES/$REPO/files2
fi
readarray -t filenames < <( cat -s $files1 $files2 )

for filen in ${filenames[@]}
do
  git -C $DST_DIR add $filen
done

git -C $DST_DIR commit -m "${COMMENT}"

rm -f *.patch

git -C $DST_DIR format-patch -1
