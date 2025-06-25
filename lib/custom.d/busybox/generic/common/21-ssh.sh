#
# Setup SSH packages
#

LIBXCRYPT_REPO_URL="https://github.com/besser82/libxcrypt.git"
LIBXCRYPT_VERSION=4.4.38
LIBXCRYPT_BRANCH=master
LIBXCRYPT_TAG="v${LIBXCRYPT_VERSION}"
LIBXCRYPT_SRC_DIR=${EXTRADIR}/libxcrypt
LIBXCRYPT_BUILD_DIR=${LIBXCRYPT_SRC_DIR}/${BB_BUILD_OUT}
LIBXCRYPT_REBUILD=yes

OPENSSH_REPO_URL="https://github.com/openssh/openssh-portable.git"
OPENSSH_VERSION=10_0_P2
OPENSSH_BRANCH=master
OPENSSH_TAG="V_${OPENSSH_VERSION}"
OPENSSH_SRC_DIR=${EXTRADIR}/openssh-portable
OPENSSH_BUILD_DIR=${OPENSSH_SRC_DIR}/${BB_BUILD_OUT}
OPENSSH_REBUILD=yes

DROPBEAR_REPO_URL="https://github.com/mkj/dropbear.git"
DROPBEAR_VERSION="2025.88"
DROPBEAR_BRANCH=master
DROPBEAR_TAG="DROPBEAR_${DROPBEAR_VERSION}"
DROPBEAR_SRC_DIR=${EXTRADIR}/dropbear
DROPBEAR_BUILD_DIR=${DROPBEAR_SRC_DIR}/${BB_BUILD_OUT}
DROPBEAR_REBUILD=yes
# extra arguments for dropbear
DROPBEAR_ARGS=

SOURCE_NAME=$(basename ${BASH_SOURCE[0]})


#
# ############ helper functions ##############
#

libxcrypt_install()
{
    # build libxcrypt
    PKG_FORCE_CLEAN="${LIBXCRYPT_REBUILD}" \
	update_src_pkg "libxcrypt" \
                    $LIBXCRYPT_VERSION \
                    $LIBXCRYPT_SRC_DIR \
                    $LIBXCRYPT_REPO_URL \
                    $LIBXCRYPT_BRANCH \
                    $LIBXCRYPT_TAG

    cd ${LIBXCRYPT_SRC_DIR}
    autoreconf --install

    mkdir -p ${LIBXCRYPT_BUILD_DIR}
    cd ${LIBXCRYPT_BUILD_DIR}/

    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    MAKEINFO=/bin/true \
	../configure --host=${BB_PLATFORM} \
		--srcdir=${LIBXCRYPT_SRC_DIR} \
		--prefix=/

    echo "${SOURCE_NAME}: Make libxcrypt ..."

    chrt -i 0 make -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Deploy libxcrypt to ${R} ..."

    make  install DESTDIR=${R}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
}

install_ssh_key()
{
        local user_name=$1
        local local_ssh_dir=/home/${CURRENT_USER}/.ssh
        local ssh_algo=$2
        local local_ssh_pkey=${local_ssh_dir}/id_${ssh_algo}
        local key_len=$3

        [[ -n "${key_len}" ]] && key_len="-b ${key_len}"

        echo "${SOURCE_NAME}: Install SSH key ${ssh_algo} for ${user_name} ..."

        mkdir -p ${local_ssh_dir}

        # Generate local key, if needed
        if [ ! -f ${local_ssh_pkey} ] ; then
                su -m ${CURRENT_USER} -c "ssh-keygen -f ${local_ssh_pkey} -m PEM -t ${ssh_algo} ${key_len} -N '' &> /dev/null"
		chmod 600 ${local_ssh_pkey}
		chmod 644 ${local_ssh_pkey}.pub
        fi
        dropbearconvert openssh dropbear ${local_ssh_pkey}  ${local_ssh_pkey}.db

        # Make sure .ssh folder belongs to the user
        chown -R ${CURRENT_USER}:${CURRENT_USER}  ${local_ssh_dir}

        local target_ssh_dir=
        [[ "${user_name}" = root ]] && target_ssh_dir=/root/.ssh || target_ssh_dir=/home/${user_name}/.ssh
        mkdir -p "${R}${target_ssh_dir}"

        cat ${local_ssh_pkey}.pub >> "${R}${target_ssh_dir}/authorized_keys"
        chmod 644 "${R}${target_ssh_dir}/authorized_keys"

        if [ "${user_name}" = root ] ; then
                cat ${local_ssh_pkey}.pub >> ${ETC_DIR}/dropbear/authorized_keys
                chmod 644 ${ETC_DIR}/dropbear/authorized_keys
        fi

        # Set the owner
        chroot_exec chown -R ${user_name}:${user_name}  ${target_ssh_dir}/

        echo "${SOURCE_NAME}: Done."
}

dropbear_install()
{
    # build dropbear
    update_src_pkg "dropbear" \
                    $DROPBEAR_VERSION \
                    $DROPBEAR_SRC_DIR \
                    $DROPBEAR_REPO_URL \
                    $DROPBEAR_BRANCH \
                    $DROPBEAR_TAG

    if [ "${DROPBEAR_REBUILD}" = yes ] ; then
        rm -rf ${DROPBEAR_BUILD_DIR}
    fi

    cd ${DROPBEAR_SRC_DIR}/

    # read actual version from sources
    DROPBEAR_VER=$(echo '#include "src/default_options.h"\n#include "src/sysoptions.h"\necho DROPBEAR_VERSION' | cpp -DHAVE_CRYPT - | sh)

    echo "Detected dropbear version: ${DROPBEAR_VER}"

    mkdir -p ${DROPBEAR_BUILD_DIR}
    cd ${DROPBEAR_BUILD_DIR}/

    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    LDFLAGS="-Wl,--gc-sections -lz -L${R}/usr/lib -Wl,--rpath=/usr/lib" \
    CFLAGS="-ffunction-sections -fdata-sections -I${R}/usr/include" \
    MAKEINFO=/bin/true \
	../configure --host=${BB_PLATFORM} \
		--srcdir=${DROPBEAR_SRC_DIR} \
		--prefix=/

    echo "${SOURCE_NAME}: Make dropbear ..."

    chrt -i 0 make -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Deploy dropbear to ${R} ..."

    make  install DESTDIR=${R}
    [ $? -eq 0 ] || exit $?;

    mkdir -p ${ETC_DIR}/dropbear

    # DropBear requires encryption keys to be generated
    chroot_exec dropbearkey -t rsa	-f /etc/dropbear/dropbear_rsa_host_key
    chroot_exec dropbearkey -t ed25519	-f /etc/dropbear/dropbear_ed25519_host_key


    # if you need to put extra dropbear options
    if [ "${ENABLE_ROOT_SSH}" != yes ] ; then
	DROPBEAR_ARGS="${DROPBEAR_ARGS} -w"
    fi


    # Configure publickey access for root
    install_ssh_key  root rsa 4096
    install_ssh_key  root ed25519


    if [ "${ENABLE_USER}" = yes ] ; then

        # Configure publickey access for the user
        install_ssh_key  ${USER_NAME} rsa 4096
        install_ssh_key  ${USER_NAME} ed25519
    fi

    echo "DROPBEAR_ARGS=\"${DROPBEAR_ARGS}\"" > ${ETC_DIR}/default/dropbear
    chmod 644 ${ETC_DIR}/default/dropbear

    install_exec ${FILES_DIR}/init/optional/S50dropbear	${ETC_DIR}/init.d/

    echo "${SOURCE_NAME}: Done."
}

openssh_install()
{
    # build openssh
    PKG_FORCE_CLEAN="${OPENSSH_REBUILD}" \
	update_src_pkg "openssh-portable" \
                    $OPENSSH_VERSION \
                    $OPENSSH_SRC_DIR \
                    $OPENSSH_REPO_URL \
                    $OPENSSH_BRANCH \
                    $OPENSSH_TAG

    if [ "${OPENSSH_REBUILD}" = yes ] ; then
        rm -rf ${OPENSSH_BUILD_DIR}
    fi

    cd ${OPENSSH_SRC_DIR}
    autoreconf --install

    mkdir -p ${OPENSSH_BUILD_DIR}
    cd ${OPENSSH_BUILD_DIR}/


    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    CFLAGS="-I${R}/usr/include" \
    LDFLAGS="-L${R}/usr/lib" \
    MAKEINFO=/bin/true \
        ../configure --host=${BB_PLATFORM} \
                --srcdir=${OPENSSH_SRC_DIR} \
                --prefix=/

    echo "${SOURCE_NAME}: Make sftp-server ..."

    chrt -i 0 make sftp-server  -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Deploy sftp-server to ${R} ..."

    mkdir -p ${R}/usr/libexec
    install_exec ${OPENSSH_BUILD_DIR}/sftp-server  ${R}/usr/libexec/

    echo "${SOURCE_NAME}: Done."
}


#
# ############ install packages ##############
#

if [ "${ENABLE_SSHD}" = yes ] ; then

    libxcrypt_install

    dropbear_install

    openssh_install
fi
