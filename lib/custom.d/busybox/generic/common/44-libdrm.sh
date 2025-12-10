#
# Install LIBDRM - userspace library for graphics drivers
#

LIBDRM_REPO_URL="https://gitlab.freedesktop.org/mesa/drm.git"
LIBDRM_BRANCH=main
LIBDRM_VERSION=2.4.127
LIBDRM_TAG="libdrm-${LIBDRM_VERSION}"
LIBDRM_SRC_DIR=${EXTRADIR}/libdrm
LIBDRM_OUT_DIR=${LIBDRM_SRC_DIR}/${BB_BUILD_OUT}


SOURCE_NAME=$(basename ${BASH_SOURCE[0]})


#
# ############ helper functions ##############
#


libdrm_install()
{
    PKG_FORCE_CLEAN=${LIBDRM_FORCE_REBUILD} \
	update_src_pkg "libdrm" \
                $LIBDRM_VERSION \
                $LIBDRM_SRC_DIR \
                $LIBDRM_REPO_URL \
                $LIBDRM_BRANCH \
                $LIBDRM_TAG

    if [ "${LIBDRM_FORCE_REBUILD}" = yes ] ; then
        rm -rf ${LIBDRM_OUT_DIR}
    fi

    mkdir -p ${LIBDRM_OUT_DIR}
    cd ${LIBDRM_SRC_DIR}/

    meson_cross_init "${LIBDRM_OUT_DIR}/${MESON_CROSSFILE}"

    echo "${SOURCE_NAME}: Configure libdrm ..."

    PKG_CONFIG=${BB_PKG_CONFIG} \
	${MESON_PY} setup ${LIBDRM_OUT_DIR}/ \
		--cross-file="${LIBDRM_OUT_DIR}/${MESON_CROSSFILE}" \
		--prefix=/usr \
		--errorlogs \
		--backend=ninja \
		-Dvc4=enabled \
		-Dintel=disabled \
		-Dexynos=disabled \
		-Domap=disabled \
		-Dtegra=disabled \
		-Dradeon=disabled \
		-Dnouveau=disabled \
		-Damdgpu=disabled \
		-Dfreedreno=disabled \
		-Detnaviv=disabled \
		-Dvmwgfx=disabled \
		-Dman-pages=disabled \
		-Dcairo-tests=disabled \
		-Dinstall-test-programs=true


    [ $? -eq 0 ] || exit 1

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Make libdrm ..."

    ${MESON_PY} compile -C ${LIBDRM_OUT_DIR}/
    [ $? -eq 0 ] || exit 1

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Install libdrm into ${R} ..."

    DESTDIR="${R}" \
        ${MESON_PY} install -C ${LIBDRM_OUT_DIR}/

    [ $? -eq 0 ] || exit 1

    echo "${SOURCE_NAME}: Done."
}


#
# ############ install packages ##############
#

if [ "${ENABLE_MESA}" = yes ] ; then
    echo -n -e "\n*** Build Settings ***\n"

    [[ ${CLEAN} =~ (^|,)(mesa|mesa-vc4|mesa-lima)(,|$) ]] && LIBDRM_FORCE_REBUILD=yes
    set -x
    LIBDRM_FORCE_UPDATE=${LIBDRM_FORCE_UPDATE:="no"}
    LIBDRM_FORCE_REBUILD=${LIBDRM_FORCE_REBUILD:="no"}
    set +x

    libdrm_install

else
    echo "${SOURCE_NAME}: Skip building libdrm."
fi
