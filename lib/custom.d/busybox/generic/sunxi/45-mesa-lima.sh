#
# Install MESA 3D library (lima)
#

MESA_REPO_URL="https://gitlab.freedesktop.org/mesa/mesa.git"
MESA_BRANCH="main"
MESA_VERSION=25.2.2
MESA_TAG="mesa-${MESA_VERSION}"
MESA_SRC_DIR=${EXTRADIR}/mesa/lima
MESA_OUT_DIR=${MESA_SRC_DIR}/${BB_BUILD_OUT}


SOURCE_NAME=$(basename ${BASH_SOURCE[0]})


#
# ############ helper functions ##############
#


mesa_install()
{
    PKG_FORCE_UPDATE=${MESA_FORCE_UPDATE} PKG_FORCE_CLEAN=${MESA_FORCE_REBUILD} \
	update_src_pkg "mesa" \
		$MESA_VERSION \
		$MESA_SRC_DIR \
		$MESA_REPO_URL \
		$MESA_BRANCH \
		$MESA_TAG

    if [ "${MESA_FORCE_REBUILD}" = yes ] ; then
        rm -rf ${MESA_OUT_DIR}
    fi

    mkdir -p ${MESA_OUT_DIR}
    cd ${MESA_SRC_DIR}/

    meson_cross_init "${MESA_OUT_DIR}/${MESON_CROSSFILE}"

    echo "${SOURCE_NAME}: Configure mesa ..."

    PKG_CONFIG=${BB_PKG_CONFIG} \
	${MESON_PY} setup ${MESA_OUT_DIR}/ \
		--cross-file="${MESA_OUT_DIR}/${MESON_CROSSFILE}" \
		--prefix=/usr \
		--errorlogs \
		--backend=ninja \
		-Dplatforms= \
		-Dgallium-drivers=lima \
		-Dtools=lima \
		-Degl-native-platform=drm \
		-Dvulkan-drivers= \
		-Dgles2=enabled \
		-Degl=enabled \
		-Dgbm=enabled \
		-Dglx=disabled \
		-Dllvm=disabled \
		-Dlibunwind=disabled \
		-Dgallium-vdpau=disabled

    [ $? -eq 0 ] || exit 1

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Make mesa..."

    ${MESON_PY} compile -C ${MESA_OUT_DIR}/

    [ $? -eq 0 ] || exit 1

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Install mesa into ${R} ..."

    DESTDIR="${R}" \
	${MESON_PY} install -C ${MESA_OUT_DIR}/

    [ $? -eq 0 ] || exit 1

#    cd ${MESA_OUT_DIR}

    # NOTE: only need sun4i-drm, so remove other libraries
#    mv ./dist/usr/lib/dri/sun4i-drm_dri.so ./dist/usr/lib/dri/sun4i-drm_dri.so.tmp
#    rm -f ./dist/usr/lib/dri/*_dri.so
#    mv ./dist/usr/lib/dri/sun4i-drm_dri.so.tmp ./dist/usr/lib/dri/sun4i-drm_dri.so

    echo "${SOURCE_NAME}: Done."
}


#
# ############ install packages ##############
#


if [ "${ENABLE_MESA}" = yes ] ; then
    echo -n -e "\n*** Build Settings ***\n"

    if [[ ${CLEAN} =~ (^|,)(mesa|mesa-lima)(,|$) ]] ; then
	MESA_FORCE_UPDATE=yes
	MESA_FORCE_REBUILD=yes
    fi

    set -x
    MESA_FORCE_UPDATE=${MESA_FORCE_UPDATE:="no"}
    MESA_FORCE_REBUILD=${MESA_FORCE_REBUILD:="no"}
    set +x


    mesa_install

    # Update QT toolchain file
    sed -i "s|^\(set(MESA_VERSION[[:space:]]\).*|\1${MESA_VERSION})|"  ${BB_CMAKE_TOOLCHAIN_QT_FILE}

else
    echo "${SOURCE_NAME}: Skip building MESA (lima backend) library."
fi
