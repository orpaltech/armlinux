#!/bin/bash

DST_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DST_DIR/../qtbase.sh

rm -rf $DST_DIR/.git/
git -C $DST_DIR init
