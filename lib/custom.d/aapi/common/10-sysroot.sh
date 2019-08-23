#
# Prepare device sysroot for crosscompile
#

SYSROOT_DIR="${EXTRADIR}/boards/${BOARD}/sysroot"

mkdir -p ${SYSROOT_DIR}
rm -rf ${SYSROOT_DIR}/*
mkdir ${SYSROOT_DIR}/usr ${SYSROOT_DIR}/opt ${SYSROOT_DIR}/etc

rsync -az ${R}/lib		${SYSROOT_DIR}
rsync -az ${R}/usr/include	${SYSROOT_DIR}/usr
rsync -az ${R}/usr/lib		${SYSROOT_DIR}/usr

if [ -d ${R}/etc/ld.so.conf.d ] ; then
  for ldconf in ${R}/etc/ld.so.conf.d/*.conf; do
    cat $ldconf >> ${SYSROOT_DIR}/etc/ld.so.conf
  done
else
  rsync -az ${R}/etc/ld.so.conf	${SYSROOT_DIR}/etc
fi

# adjust symlinks to be relative
${LIBDIR}/make-relativelinks.sh $SYSROOT_DIR
