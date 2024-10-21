#!/bin/bash

REPO=$1
TAG=$2
VER=$(echo "${TAG//-/.}" | cut -d '.' -f1,2)

SCRIPT_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
PROJ_DIR="${SCRIPT_DIR}/../../.."

if [ -z "$REPO" ] ; then
  echo "error: no repo name is given!"
  exit 1
fi

SRC_DIR=${PROJ_DIR}/sources/linux/${REPO}

echo $SRC_DIR

if [ -z "$TAG" ] ; then
  echo "error: no tag is given!"
  exit 1
fi

git -C ${SRC_DIR} checkout -f tags/${TAG}
