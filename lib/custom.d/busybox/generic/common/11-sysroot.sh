#
# Prepare device sysroot for crosscompile
#

mkdir -p ${SYSROOT_DIR}
rm -rf ${SYSROOT_DIR}/*
mkdir ${SYSROOT_DIR}/usr

rsync -az ${R}/usr/*		${SYSROOT_DIR}/usr
rsync -az ${R}/lib		${SYSROOT_DIR}

# adjust symlinks to be relative
${LIBDIR}/make-relativelinks.sh	${SYSROOT_DIR}

chown -R ${CURRENT_USER}:${CURRENT_USER}	${SYSROOT_DIR}
