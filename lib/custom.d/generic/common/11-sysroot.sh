#
# Prepare device sysroot for crosscompile
#

SYSROOT_DIR="${EXTRADIR}/boards/${BOARD}/sysroot"

mkdir -p ${SYSROOT_DIR}
rm -rf ${SYSROOT_DIR}/*
mkdir ${SYSROOT_DIR}/usr	${SYSROOT_DIR}/opt	${SYSROOT_DIR}/etc

rsync -az ${R}/usr/*		${SYSROOT_DIR}/usr
rsync -az ${R}/lib		${SYSROOT_DIR}
#rsync -az ${R}/usr/include	${SYSROOT_DIR}/usr
#rsync -az ${R}/usr/lib		${SYSROOT_DIR}/usr

if [ -d ${R}/etc/ld.so.conf.d ] ; then
	for ldconf in ${R}/etc/ld.so.conf.d/*.conf; do
		cat $ldconf >> ${SYSROOT_DIR}/etc/ld.so.conf
	done
else
	rsync -az ${R}/etc/ld.so.conf	${SYSROOT_DIR}/etc
fi

# chown -R ${CURRENT_USER}:${CURRENT_USER} ${SYSROOT_DIR}

# adjust symlinks to be relative
${LIBDIR}/make-relativelinks.sh	${SYSROOT_DIR}

MACHINE_DUMP=$(${DEV_GCC} -dumpmachine)

if [ "${MACHINE_DUMP}" != "${LINUX_PLATFORM}" ] ; then
	cd ${SYSROOT_DIR}/usr/include
	ln -s	${LINUX_PLATFORM}	./${MACHINE_DUMP}

	cd ${SYSROOT_DIR}/usr/lib
	ln -s	${LINUX_PLATFORM}	./${MACHINE_DUMP}
fi

chown -R ${CURRENT_USER}:${CURRENT_USER}	${SYSROOT_DIR}

# fix pkgconfig files
num_pc_files=$(count_files "${SYSROOT_DIR}/usr/lib/${LINUX_PLATFORM}/pkgconfig/*.pc")
if [ ${num_pc_files} -gt 0 ] ; then
	for pc_file in ${SYSROOT_DIR}/usr/lib/${LINUX_PLATFORM}/pkgconfig/*.pc; do
		sed -i "s/^\(libdir=\).*\/lib$/\1\/usr\/lib\/${LINUX_PLATFORM}/" ${pc_file}
	done
fi

#fix libjpeg pkgconfig file
LIBJPEG_PC=${SYSROOT_DIR}/usr/lib/${LINUX_PLATFORM}/pkgconfig/libjpeg.pc
if [ -f ${LIBJPEG_PC} ] ; then
	sed -i "s/^\(Cflags:\).*/\1 -I\${includedir} -I\/usr\/include\/${LINUX_PLATFORM}/"	${LIBJPEG_PC}
fi
