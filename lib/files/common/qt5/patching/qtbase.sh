#!/bin/bash

BRANCH=$1
BASEDIR="/home/sergey/Projects/orpaltech"

if [ -z "$BRANCH" ] ;  then
  echo "Please, specify branch name"
  exit 1
fi
SRC_DIR=$BASEDIR/qt5-build/qt5/qtbase

git -C $SRC_DIR checkout $BRANCH
