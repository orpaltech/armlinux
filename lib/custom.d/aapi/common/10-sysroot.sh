#
# Prepare device sysroot for crosscompile
#

SYSROOT_DIR=${EXTRADIR}/boards/${BOARD}/sysroot

mkdir -p ${SYSROOT_DIR}
rm -rf ${SYSROOT_DIR}/*
mkdir ${SYSROOT_DIR}/usr ${SYSROOT_DIR}/opt

rsync -az ${R}/lib		${SYSROOT_DIR}
rsync -az ${R}/usr/include	${SYSROOT_DIR}/usr
rsync -az ${R}/usr/lib		${SYSROOT_DIR}/usr

# adjust symlinks to be relative
${LIBDIR}/make-relativelinks.sh $SYSROOT_DIR
