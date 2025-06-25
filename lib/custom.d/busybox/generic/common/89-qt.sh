#
# Build QT framework
#
QT_GIT_ROOT="git://code.qt.io/qt"
QT_RELEASE=${QT_RELEASE:="6.8.3"}
QT_BRANCH=${QT_BRANCH:="$QT_RELEASE"}
QT_TAG=${QT_TAG:=""}
QT_PREFIX=${QT_PREFIX:="/usr/local/qt-$QT_RELEASE"}

QT_MODULES=("qtshadertools" \
"qtsvg" \
"qtimageformats" \
"qtlanguageserver" \
"qtdeclarative" \
"qtquicktimeline" \
"qtquick3d" \
"qtquickeffectmaker" \
"qtmultimedia" \
"qtcharts" \
"qtgraphs" \
"qt5compat" \
"qtdeviceutilities" \
"qtserialport" \
"qtvirtualkeyboard" \
"qtactiveqt" \
"qttools")

set -x

QT_ROOT_DIR=${EXTRADIR}/qt-build/qt6
QT_BUILD_DIR=${QT_ROOT_DIR}/build/${QT_DEVICE_CONFIG}
QTBASE_REPO_URL=${QT_GIT_ROOT}/qtbase.git
QTBASE_SRC_DIR=${QT_ROOT_DIR}/qtbase
QTBASE_OUT_DIR=${QT_BUILD_DIR}/qtbase

# if host  QT is pre-built then use it
QT_PREBUILT_HOST=${QT_PREBUILT_HOST:=""}
#${QT_PREFIX}

QT_HOST_PREFIX=${QT_BUILD_DIR}/qt-host
QT_EXT_PREFIX=${QT_BUILD_DIR}/qt-board

QTBASE_OUT_HOST_DIR=${QTBASE_OUT_DIR}/build-qt-host
QTBASE_OUT_EXT_DIR=${QTBASE_OUT_DIR}/build-qt-board

QT_CROSS_COMPILE=${QT_CROSS_COMPILE:="$BB_CROSS_COMPILE"}

[[ "${ENABLE_X11}" = yes ]] && QT_XCB_OPTION="-xcb -xcb-xlib" || QT_XCB_OPTION="-no-xcb"
set +x


SOURCE_NAME=$(basename ${BASH_SOURCE[0]})


# ----------------------------------------------------------------------------

qt_install()
{
    # make sure QT root directory exists
    mkdir -p ${QT_ROOT_DIR}

    PKG_FORCE_UPDATE=${QT_UPDATE_SOURCES} PKG_FORCE_CLEAN=${QT_FORCE_REBUILD} \
        update_src_pkg "qtbase" \
            $QT_RELEASE \
	    $QTBASE_SRC_DIR \
	    $QTBASE_REPO_URL \
	    $QT_BRANCH \
	    $QT_TAG


    for MODULE in "${QT_MODULES[@]}" ; do

	local QT_MOD_SRC_DIR="${QT_ROOT_DIR}/${MODULE}"
	local QT_MOD_REPO_URL="${QT_GIT_ROOT}/${MODULE}.git"

	PKG_FORCE_UPDATE=${QT_UPDATE_SOURCES} PKG_FORCE_CLEAN=${QT_FORCE_REBUILD} \
	    update_src_pkg "${MODULE}" \
		$QT_RELEASE \
		$QT_MOD_SRC_DIR \
		$QT_MOD_REPO_URL \
		$QT_BRANCH \
		$QT_TAG

    done

    QT_MODULE_DIR=${QT_ROOT_DIR}/qtquickdesigner-components
    rm -rf $QT_MODULE_DIR
    git clone "https://codereview.qt-project.org/qt-labs/qtquickdesigner-components" --recursive $QT_MODULE_DIR
    git -C $QT_MODULE_DIR submodule update --init --recursive


    if [ "${QT_FORCE_REBUILD}" = yes ] ; then
	rm -rf ${QTBASE_OUT_DIR}
    fi

    if [ -n "${QT_PREBUILT_HOST}" ] && [ -d "${QT_PREBUILT_HOST}" ] ; then
	QT_HOST_PREFIX=${QT_PREBUILT_HOST}
    else
	qt_make_host
    fi

    qt_make_board
}

qt_make_board()
{
    mkdir -p ${QTBASE_OUT_EXT_DIR}

    # prepare prefix directories
    mkdir -p ${QT_EXT_PREFIX}
    rm -rf ${QT_EXT_PREFIX}/*


    cd ${QTBASE_OUT_EXT_DIR}/

    echo "${SOURCE_NAME}: [board] Configure qtbase .."

    ${QTBASE_SRC_DIR}/configure \
		-release \
		-opensource -confirm-license \
		-device ${QT_DEVICE_CONFIG} \
		-device-option CROSS_COMPILE=${QT_CROSS_COMPILE} \
		-prefix ${QT_PREFIX} \
		-qt-host-path ${QT_HOST_PREFIX} \
		-extprefix ${QT_EXT_PREFIX} \
		-nomake examples \
		-nomake tests \
		-no-pch \
		-no-use-gold-linker \
		-no-openvg \
		-no-cups \
		${QT_OPENGL_OPTION} \
		-no-feature-vulkan \
		${QT_XCB_OPTION} \
		-no-sql-db2 -no-sql-ibase -no-sql-mysql -no-sql-oci -no-sql-odbc -no-sql-psql -no-sql-sqlite \
		-- -DCMAKE_TOOLCHAIN_FILE=${BB_CMAKE_TOOLCHAIN_QT_FILE}

    [ $? -eq 0 ] || exit 1

    cat ./config.summary

    if [ "${QT_STOP_ON_CONFIG}" = yes ]; then
	echo "=================================================================================="
	read -p "Please, review configuration output. Press any key to continue or Ctrl+C to exit... " -n1 -s
	echo ""
    fi

    echo "${SOURCE_NAME}: [board] Done."
    echo "${SOURCE_NAME}: [board] Make & install qtbase .."

    cmake --build . --parallel ${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit 1

    cmake --install .

    echo "${SOURCE_NAME}: [board] Done."
    echo "${SOURCE_NAME}: [board] Processing modules .."

    qt_make_mods "${QTBASE_OUT_EXT_DIR}" "${QT_EXT_PREFIX}"

    qt_make_mod "qtquickdesigner-components" "${QTBASE_OUT_EXT_DIR}" "${QT_EXT_PREFIX}"

    echo "${SOURCE_NAME}: [board] Done."
    echo "${SOURCE_NAME}: [board] Deploy to rootfs .."

    mkdir -p ${R}${QT_PREFIX}
    rsync -az ${QT_EXT_PREFIX}/	${R}${QT_PREFIX}
    echo "${QT_PREFIX}/lib" >> ${ETC_DIR}/ld.so.conf

    echo "${SOURCE_NAME}: [board] Done."
}

# ----------------------------------------------------------------------------

qt_make_host()
{
    mkdir -p ${QTBASE_OUT_HOST_DIR}

    # prepare prefix directories
    mkdir -p ${QT_HOST_PREFIX}
    rm -rf ${QT_HOST_PREFIX}/*


    cd ${QTBASE_OUT_HOST_DIR}/

    echo "${SOURCE_NAME}: [host] Configure qtbase .."

    cmake ${QTBASE_SRC_DIR} -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DQT_BUILD_EXAMPLES=OFF \
        -DQT_BUILD_TESTS=OFF \
	-DBUILD_WITH_PCH=OFF \
        -DCMAKE_INSTALL_PREFIX=${QT_HOST_PREFIX} \
	-DFEATURE_vulkan=OFF \
	-DFEATURE_sql_db2=OFF -DFEATURE_sql_ibase=OFF -DFEATURE_sql_mysql=OFF -DFEATURE_sql_oci=OFF -DFEATURE_sql_odbc=OFF -DFEATURE_sql_psql=OFF -DFEATURE_sql_sqlite=OFF

    [ $? -eq 0 ] || exit 1

    cat ./config.summary

    if [ "${QT_STOP_ON_CONFIG}" = yes ]; then
	echo "=================================================================================="
	read -p "Please, review configuration output. Press any key to continue or Ctrl+C to exit... " -n1 -s
	echo ""
    fi

    echo "${SOURCE_NAME}: [host] Done."
    echo "${SOURCE_NAME}: [host] Make & install qtbase .."

    cmake --build . --parallel ${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit 1

    cmake --install .

    echo "${SOURCE_NAME}: [host] Done."
    echo "${SOURCE_NAME}: [host] Processing modules .."

    qt_make_mods "${QTBASE_OUT_HOST_DIR}" "${QT_HOST_PREFIX}"

    qt_make_mod "qtquickdesigner-components" "${QTBASE_OUT_HOST_DIR}" "${QT_HOST_PREFIX}"

    echo "${SOURCE_NAME}: [host] Done."
}

qt_make_mods()
{
    local QT_PREFIX_OUT_DIR=$1
    local QT_PREFIX_DIR=$2

    for MODULE in "${QT_MODULES[@]}" ; do

	qt_make_mod $MODULE	$QT_PREFIX_OUT_DIR	$QT_PREFIX_DIR

    done
}

qt_make_mod()
{
	local MODULE=$1
	local QT_PREFIX_OUT_DIR=$2
	local QT_PREFIX_DIR=$3

	echo "${SOURCE_NAME}: Configure ${MODULE} .."

	local QT_MOD_SRC_DIR=${QT_ROOT_DIR}/${MODULE}
	local QT_MOD_OUT_DIR=${QT_PREFIX_OUT_DIR}/${MODULE}

	mkdir -p ${QT_MOD_OUT_DIR}
	cd ${QT_MOD_OUT_DIR}/

	if [ "${QT_FORCE_REBUILD}" = yes ] ; then
		echo "${SOURCE_NAME}: Force rebuild ${MODULE}"
		rm -rf ./*
	fi

	${QT_PREFIX_DIR}/bin/qt-configure-module  ${QT_MOD_SRC_DIR}/
	[ $? -eq 0 ] || exit $?

	echo "${SOURCE_NAME}: Done."
	echo "${SOURCE_NAME}: Make & install ${MODULE} .."

	cmake --build . --parallel ${HOST_CPU_CORES}
	[ $? -eq 0 ] || exit $?

	cmake --install .

	echo "${SOURCE_NAME}: Done."
}

# ----------------------------------------------------------------------------

if [ "${ENABLE_QT}" = yes ] ; then

    if [ -z "${QT_DEVICE_CONFIG}" ] ; then
	echo "ERROR: QT device config was not specified - can't continue."
	exit 1
    fi

    if [[ ${CLEAN} =~ (^|,)qt(,|$) ]] ; then
	QT_UPDATE_SOURCES=yes
	QT_FORCE_REBUILD=yes
    fi

    echo -n -e "\n*** Build Settings ***\n"
    set -x
    QT_UPDATE_SOURCES=${QT_UPDATE_SOURCES:="no"}
    QT_FORCE_REBUILD=${QT_FORCE_REBUILD:="no"}
    set +x

    qt_install

else
    echo "${SOURCE_NAME}: Skip."
fi
