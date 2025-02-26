#
# Prepare root file system
#

BUSYBOX_REPO_URL="https://git.busybox.net/busybox"
BUSYBOX_BRANCH=master
BUSYBOX_VERSION=1_37_0
BUSYBOX_TAG=
BUSYBOX_SRC_DIR=${EXTRADIR}/busybox
BUSYBOX_BUILD_DIR=${BUSYBOX_SRC_DIR}/${BB_BUILD_OUT}
BUSYBOX_REBUILD=yes

BB_SHDOWN_SCRIPT=to_be_tested
BB_SHDOWN_SRC_DIR=${BUSYBOX_SRC_DIR}/examples/shutdown-1.0/script
BB_SHDOWN_DST_DIR=/app/shutdown-1.0/script

GLIBC_REPO_URL="https://sourceware.org/git/glibc.git"
GLIBC_VERSION=2.41
GLIBC_BRANCH="release/${GLIBC_VERSION}/master"
GLIBC_TAG=
GLIBC_SRC_DIR=${EXTRADIR}/glibc
GLIBC_BUILD_DIR=${GLIBC_SRC_DIR}/${BB_BUILD_OUT}
GLIBC_REBUILD=yes

MUSLLIBC_REPO_URL="https://git.musl-libc.org/git/musl"
MUSLLIBC_VERSION=1.2.5
MUSLLIBC_BRANCH="master"
MUSLLIBC_TAG=
MUSLLIBC_SRC_DIR=${EXTRADIR}/musl-libc
MUSLLIBC_BUILD_DIR=${MUSLLIBC_SRC_DIR}/${BB_BUILD_OUT}
MUSLLIBC_REBUILD=yes

SOURCE_NAME=$(basename ${BASH_SOURCE[0]})
SOURCE_DIR=$(dirname $(realpath ${BASH_SOURCE[0]}))

#
# ############ helper functions ##############
#

busybox_install()
{
    # build busybox
    update_src_pkg "busybox" \
                    $BUSYBOX_VERSION \
                    $BUSYBOX_SRC_DIR \
                    $BUSYBOX_REPO_URL \
                    $BUSYBOX_BRANCH \
                    $BUSYBOX_TAG

    if [ "${BUSYBOX_REBUILD}" = yes ] ; then
	rm -rf ${BUSYBOX_BUILD_DIR}
    fi

    export ARCH=${KERNEL_ARCH}
    export CROSS_COMPILE="${BB_CROSS_COMPILE}"

    if [ "${BUSYBOX_REBUILD}" = yes ] ; then
	cd ${BUSYBOX_SRC_DIR}
	make mrproper
    fi

    mkdir -p ${BUSYBOX_BUILD_DIR}
    cd ${BUSYBOX_BUILD_DIR}/

    make  KBUILD_SRC=${BUSYBOX_SRC_DIR} -f ${BUSYBOX_SRC_DIR}/Makefile defconfig


    # check user config
    local user_config=${CONFIGDIR}/busybox/${CONFIG}/${BUSYBOX_VERSION}/${BUSYBOX_BUILD_CONFIG}

    if [ -n "${BUSYBOX_BUILD_CONFIG}" ] && [ -f ${user_config} ] ; then
	echo "Select user-provided config file: ${user_config}"
	cp ${user_config}  ${BUSYBOX_BUILD_DIR}/.config
	make  oldconfig
    fi

    echo "${SOURCE_NAME}: Make BusyBox ..."

    chrt -i 0 make  -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."

    echo "${SOURCE_NAME}: Install BusyBox to ${R} ..."

    make  install CONFIG_PREFIX=${R}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."

    if [ "${BB_SHUTDOWN_SCRIPT}" = yes ] ; then
	echo "${SOURCE_NAME}: Make shutdown script ..."
	cd ${SHUTDOWN_SRC_DIR}
	${BB_GCC} -Wall -Os -o hardshutdown hardshutdown.c
	${BB_STRIP} hardshutdown
	echo "${SOURCE_NAME}: Done."
    fi

    unset ARCH	CROSS_COMPILE
}

glibc_install()
{
    # build GLIBC
    update_src_pkg "glibc" \
                    $GLIBC_VERSION \
                    $GLIBC_SRC_DIR \
                    $GLIBC_REPO_URL \
                    $GLIBC_BRANCH \
                    $GLIBC_TAG

    if [ "${GLIBC_REBUILD}" = yes ] ; then
        rm -rf ${GLIBC_BUILD_DIR}
    fi

    mkdir -p ${GLIBC_BUILD_DIR}
    cd ${GLIBC_BUILD_DIR}/

#IMPORTANT:  LD_LIBRARY_PATH shouldn't contain the current directory when building glibc.
    LD_LIBRARY_PATH= \
    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    MAKEINFO=/bin/true \
        ../configure \
		--host=${LINUX_PLATFORM} \
		--srcdir=${GLIBC_SRC_DIR} \
		--prefix=/ \
		--enable-add-ons

    chrt -i 0 make -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    make  install install_root=${R}
    [ $? -eq 0 ] || exit $?;
}


musl_libc_install()
{
    # build MUSL LIBC
    update_src_pkg "musl-libc" \
                    $MUSLLIBC_VERSION \
                    $MUSLLIBC_SRC_DIR \
                    $MUSLLIBC_REPO_URL \
                    $MUSLLIBC_BRANCH \
                    $MUSLLIBC_TAG

    if [ "${MUSLLIBC_REBUILD}" = yes ] ; then
        rm -rf ${MUSLLIBC_BUILD_DIR}
    fi

    mkdir -p ${MUSLLIBC_BUILD_DIR}
    cd ${MUSLLIBC_BUILD_DIR}/

    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    MAKEINFO=/bin/true \
	../configure \
		--host=${MUSL_TOOLCHAIN_PLATFORM} \
		--srcdir=${MUSLLIBC_SRC_DIR} \
		--prefix=/

    echo "${SOURCE_NAME}: Make MUSL libc..."

    chrt -i 0 make  -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Install MUSL libc into rootfs ${R} ..."

    make  install DESTDIR=${R}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
}


meson_cross_init()
{
    local CROSS_FILE=$1
    cat <<-EOF > ${CROSS_FILE}
# Meson cross-file
[constants]
compile_flags = [ '-I${R}/usr/include' ]
linker_flags = [ '-L${R}/usr/lib' ]

[binaries]
c = '${BB_GCC}'
cpp = '${BB_CXX}'
strip = '${BB_STRIP}'
ar = '${BB_AR}'
objcopy = '${BB_OBJCOPY}'
pkg-config = '/usr/bin/pkg-config'
# exe_wrapper = 'QEMU_LD_PREFIX=${R} ${QEMU_BINARY}'

[built-in options]
c_args = compile_flags
cpp_args = compile_flags
c_link_args = linker_flags
cpp_link_args = linker_flags

[properties]
sys_root = '${R}'
pkg_config_libdir = '${R}/lib/pkgconfig:${R}/usr/lib/pkgconfig:${R}/usr/share/pkgconfig'

[host_machine]
system = 'linux'
cpu_family = '${MESON_CPU_FAMILY}'
cpu = '${MESON_CPU}'
endian = 'little'
EOF
}


#
# ########### pkg-config wrapper  ############
#

SYSROOT_DIR=${EXTRADIR}/boards/${BOARD}/sysroot
BB_PKG_CONFIG=${BASEDIR}/images/busybox/build/cross-pkg-config.sh

# Create wrapper script for pkg-config
cat <<-EOF > ${BB_PKG_CONFIG}
#!/bin/sh
R=${R}
export PKG_CONFIG_SYSROOT_DIR="\${R}"
export PKG_CONFIG_LIBDIR="\${R}/lib/pkgconfig:\${R}/usr/lib/pkgconfig:\${R}/usr/share/pkgconfig"
export PKG_CONFIG_PATH=
exec /usr/bin/pkg-config "\$@"
EOF
chmod +x ${BB_PKG_CONFIG}


#
# ############ configure rootfs ##############
#

if [ "${BB_LIBC}" = gnu ] ; then

  BB_LIBC_FULL="${BB_LIBC}-${GLIBC_VERSION}"
elif [ "${BB_LIBC}" = musl ] ; then

  BB_LIBC_FULL="${BB_LIBC}-${MUSLLIBC_VERSION}"
else

  display_alert "BB_LIBC isn't set correctly! Please, update scripts and try again." "BB_LIBC=${BB_LIBC}" "err"
  exit 1
fi


ROOTFS_TAR="rootfs-busybox-${SOC_ARCH}_${PRODUCT_FULL_VER}-${SOC_FAMILY}-${CONFIG}"

BB_TAR_DIR=${BASEDIR}/debs
mkdir -p ${BB_TAR_DIR}

if [[ ${CLEAN} =~ (^|,)rootfs(,|$) ]] ; then
    rm -f ${BB_TAR_DIR}/${ROOTFS_TAR}.txt
fi

ROOTFS_PKGS=()
ROOTFS_VPKGS=()
# Add custom scripts in the range 10..89
for pkg_script in ${SOURCE_DIR}/packages/{1..8}{0..9}-*.sh; do
    if [ -f "${pkg_script}" ] ; then
	. ${pkg_script}

	pkg_name=$(basename "${pkg_script}" | cut -d'-' -f 2 | cut -d'.' -f 1)
        pk_name_up=$(echo "${pkg_name}" | awk '{print toupper($0)}')
        pkg_ver="${pk_name_up}_VERSION"
	pkg_libc="${pk_name_up}_LIBC"
	if [ "${BB_LIBC}" = "${!pkg_libc}" ] || [ -z "${!pkg_libc}" ]; then
		ROOTFS_PKGS+=("${pkg_name}")
		ROOTFS_VPKGS+=("${pkg_name}-${!pkg_ver}")
	fi
    fi
done


# Gather mandatory details about rootfs
    cat <<-EOF > ${BB_TAR_DIR}/${ROOTFS_TAR}.txt~
busybox="${BUSYBOX_VERSION}"
libc="${BB_LIBC_FULL}"
pkgs="${ROOTFS_VPKGS[@]}"
EOF

if [ ! -f ${BB_TAR_DIR}/${ROOTFS_TAR}.txt ] ; then
    rm -f ${BB_TAR_DIR}/${ROOTFS_TAR}.tar.gz
else
    hash=$(md5sum ${BB_TAR_DIR}/${ROOTFS_TAR}.txt | cut -f1 -d" ")
    hash2=$(md5sum ${BB_TAR_DIR}/${ROOTFS_TAR}.txt~ | cut -f1 -d" ")

    if [ "${hash}" != "${hash2}" ] ; then
      rm -f ${BB_TAR_DIR}/${ROOTFS_TAR}.tar.gz
      rm -f ${BB_TAR_DIR}/${ROOTFS_TAR}.txt
    fi
fi


if [ ! -f ${BB_TAR_DIR}/${ROOTFS_TAR}.tar.gz ] ; then
    echo "Rootfs '${ROOTFS_TAR}' was not found, build it again from scratch"


    busybox_install

    if [ "${BB_LIBC}" = gnu ] ; then

	glibc_install

    elif [ "${BB_LIBC}" = musl ] ; then

	musl_libc_install
    fi


    # IMPORTANT: need to install some of gcc libraries
    if [ -n "${TOOLCHAIN_LIB_DIR}" ] ; then
	cp -P ${TOOLCHAIN_LIB_DIR}/libgcc_s.so*	  ${R}/lib/
	cp -P ${TOOLCHAIN_LIB_DIR}/libatomic.so*  ${R}/lib/
    fi


    echo "${SOURCE_NAME}: Create required filesystem folders..."
    mkdir ${R}/app	${R}/dev	${R}/opt	${R}/tmp	${R}/proc	${R}/sys	${R}/root	${R}/home

    mkdir -p ${ETC_DIR}/default	${ETC_DIR}/init.d	${ETC_DIR}/sysctl.d	${ETC_DIR}/syslog.d	${ETC_DIR}/mdev

    mkdir -p ${USR_DIR}/share	${USR_DIR}/lib

    mkdir -p ${R}/var/run	${R}/var/log	${R}/var/lock	${R}/var/spool/cron/crontabs
    echo "${SOURCE_NAME}: Done."


    if [ "${BB_SHDOWN_SCRIPT}" = yes ] ; then
	echo "${SOURCE_NAME}: Install shutdown script ..."

	# install shutdown script files
	local dst_dir="${R}${BB_SHDOWN_DST_DIR}"
	mkdir -p ${dst_dir}

	install_exec ${BB_SHDOWN_SRC_DIR}/hardshutdown	${dst_dir}/
	install_exec ${BB_SHDOWN_SRC_DIR}/shutdown		${dst_dir}/
	install_exec ${BB_SHDOWN_SRC_DIR}/do_shutdown	${dst_dir}/
	install_exec ${BB_SHDOWN_SRC_DIR}/stop_storage	${dst_dir}/
	install_exec ${BB_SHDOWN_SRC_DIR}/stop_tasks	${dst_dir}/

	# change built-in handlers
	ln -sf ${BB_SHDOWN_DST_DIR}/shutdown	${R}/sbin/halt
	ln -sf ${BB_SHDOWN_DST_DIR}/shutdown	${R}/sbin/reboot
	ln -sf ${BB_SHDOWN_DST_DIR}/shutdown	${R}/sbin/poweroff

	echo "${SOURCE_NAME}: Done."
    fi

    # Create my custom shutdown script
    install_exec ${FILES_DIR}/misc/shutdown	${R}/bin/


    # ldconfig will search for libraries in the trusted directory /lib.
    # Add more search paths to the configuration file.
    if [ "${BB_LIBC}" = gnu ] ; then

	echo "/usr/lib" >> ${ETC_DIR}/ld.so.conf
	chroot_exec ldconfig -v
    elif [ "${BB_LIBC}" = musl ] ; then

	echo "/usr/lib" >> ${ETC_DIR}/ld-musl-${MUSL_ARCH}.path
	chmod 644 ${ETC_DIR}/ld-musl-${MUSL_ARCH}.path
    fi

    # Install user management files as they are needed by packages
    # that we are going to install below
    install_readonly ${FILES_DIR}/etc/passwd  ${ETC_DIR}/
    install_readonly ${FILES_DIR}/etc/group   ${ETC_DIR}/
    install_readonly ${FILES_DIR}/etc/shadow  ${ETC_DIR}/


    echo "${SOURCE_NAME}: Install mandatory packages ..."

    for pkg_name in "${ROOTFS_PKGS[@]}"
    do
	pkg_install="${pkg_name}_install"
	$pkg_install "${pkg_name}"
    done

    echo "${SOURCE_NAME}: mandatory packages installed."


    echo "${SOURCE_NAME}: compressing rootfs '${ROOTFS_TAR}' to speed-up next build..."
    tar -czf ${BB_TAR_DIR}/${ROOTFS_TAR}.tar.gz -C "${BUILDDIR}/" "chroot"

    mv ${BB_TAR_DIR}/${ROOTFS_TAR}.txt~	${BB_TAR_DIR}/${ROOTFS_TAR}.txt
else

    echo "${SOURCE_NAME}: rootfs '${ROOTFS_TAR}' already exists, extract it"

    rm -rf ${R}/*
    tar -C "${R}/" --strip-components=1 -xzf	${BB_TAR_DIR}/${ROOTFS_TAR}.tar.gz

    rm -f ${BB_TAR_DIR}/${ROOTFS_TAR}.txt~

    # Create mandatory files for user management
    install_readonly ${FILES_DIR}/etc/passwd  ${ETC_DIR}/
    install_readonly ${FILES_DIR}/etc/group   ${ETC_DIR}/
    install_readonly ${FILES_DIR}/etc/shadow  ${ETC_DIR}/

fi
echo "${SOURCE_NAME}: Done."

echo "${SOURCE_NAME}: Do essential rootfs configuration ..."
echo "${SOURCE_NAME}: Install init & config files into rootfs ${R} ..."

# Create inittab file
install_readonly ${FILES_DIR}/etc/inittab	${ETC_DIR}/
# Create fstab file
install_readonly ${FILES_DIR}/mount/fstab	${ETC_DIR}/
# Create config files
install_readonly ${FILES_DIR}/etc/mdev.conf	${ETC_DIR}/
install_exec ${FILES_DIR}/etc/mdev-mount.sh	${ETC_DIR}/mdev/mdev-mount.sh

chroot_exec ln -s /proc/mounts /etc/mtab



# Create the main scripts
install_exec ${FILES_DIR}/init/rcS	${ETC_DIR}/init.d/
install_exec ${FILES_DIR}/init/rcK	${ETC_DIR}/init.d/

# Copy all init scripts
for src_file in $(ls ${FILES_DIR}/init/S??*) ; do
    scr_name=$(basename ${src_file})
    install_exec ${src_file}	${ETC_DIR}/init.d/${scr_name}
done



echo "${SOURCE_NAME}: Temporary mount system directories..."
chroot_exec mount -t proc none /proc
chroot_exec mount -t sysfs none /sys
chroot_exec echo /sbin/mdev > /proc/sys/kernel/hotplug
chroot_exec /sbin/mdev -s
chroot_exec mkdir /dev/pts
chroot_exec mount -t devpts none /dev/pts
echo "${SOURCE_NAME}: Done."





# TODO: add more stuff, if needed

echo "${SOURCE_NAME}: end of basic rootfs configuration."
