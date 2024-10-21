#!/bin/bash

DST_DIR=$( pwd )
#$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DST_DIR/../common.sh
source $DST_DIR/patch.info

readarray -t filenames < <( cat -s $DST_DIR/CHANGED_FILES/$REPO/files1-$VER $DST_DIR/CHANGED_FILES/$REPO/files2-$VER )

for filen in ${filenames[@]}
do
  git -C $DST_DIR add $filen
done

git -C $DST_DIR commit -m "${COMMENT}"

rm -f *.patch

git -C $DST_DIR format-patch -1
