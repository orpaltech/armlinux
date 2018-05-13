#!/bin/bash

#------------------------------------------------------------------------------------------------------

get_build_deps()
{
	display_alert "Updating host packages..." "" "info"

        sudo apt-get install -y \
                debootstrap \
                debian-archive-keyring \
                qemu-user-static \
                binfmt-support \
                dosfstools \
                rsync \
		patch \
                bmap-tools \
                whois git bc \
                device-tree-compiler \
		cmake \
		texi2html texinfo \
		dialog
	[ $? -eq 0 ] || exit $?;
}

#------------------------------------------------------------------------------------------------------

get_uboot_source()
{
	local BRANCH_FIXED=$(echo $UBOOT_REPO_BRANCH | sed -e 's/\//-/g')
        UBOOT_SOURCE_DIR=$UBOOT_BASE_DIR/$BRANCH_FIXED

        if [ -d $UBOOT_SOURCE_DIR ] && [ -d $UBOOT_SOURCE_DIR/.git ] ; then
		local UBOOT_OLD_URL=$(git -C $UBOOT_SOURCE_DIR config --get remote.origin.url)
		if [ "${UBOOT_OLD_URL}" != "${UBOOT_REPO_URL}" ] ; then
			rm -rf $UBOOT_SOURCE_DIR
		fi
	fi
	if [ -d $UBOOT_SOURCE_DIR ] && [ -d $UBOOT_SOURCE_DIR/.git ] ; then
		display_alert "Updating U-Boot from" "${UBOOT_REPO_URL} | ${UBOOT_REPO_BRANCH}" "info"

                # update sources
		git -C $UBOOT_SOURCE_DIR fetch --tags origin $UBOOT_REPO_BRANCH
		git -C $UBOOT_SOURCE_DIR reset --hard origin/$UBOOT_REPO_BRANCH
		git -C $UBOOT_SOURCE_DIR clean -fd

		rm -f "${UBOOT_SOURCE_DIR}/*.bin"
        else
		display_alert "Cloning U-Boot from" "${UBOOT_REPO_URL} | ${UBOOT_REPO_BRANCH}" "info"

                rm -rf $UBOOT_SOURCE_DIR
                mkdir -p $UBOOT_BASE_DIR

                git clone $UBOOT_REPO_URL -b $UBOOT_REPO_BRANCH --tags $UBOOT_SOURCE_DIR
        fi

        if [ ! -z "${UBOOT_REPO_TAG}" ] ; then
		display_alert "Checking out u-boot tag" "tags/${UBOOT_REPO_TAG}" "info"
		git -C $UBOOT_SOURCE_DIR checkout tags/$UBOOT_REPO_TAG
	fi

	echo "Done."
}

#------------------------------------------------------------------------------------------------------
# copy_patches(src_dir, patch_dir)
#------------------------------------------------------------------------------------------------------
copy_patches()
{
	local PATCH_SRC_DIR=$1
	local PATCH_TMP_DIR=$2
	local PATCH_OVERLAY_DIR=$PATCH_SRC_DIR/overlays
	local PATCH_SOC_DIR=$PATCH_SRC_DIR/$SOC_FAMILY
	local PATCH_BOARD_DIR=$PATCH_SOC_DIR/$BOARD

	#
	# Phase 1 - copy common patches
	#
	echo "--- 1) Copy common patches from '${PATCH_SRC_DIR}/common'"
	cp $PATCH_SRC_DIR/common/*.patch $PATCH_TMP_DIR/ 2> /dev/null

	#
	# Pahes 2 - copy SoC-spec patches, allow ovewrite the common patches
	#
	if [ -d $PATCH_SOC_DIR ] ; then
		echo "--- 2) Copy SoC-specific patches from '${PATCH_SOC_DIR}'"
		cp $PATCH_SOC_DIR/*.patch $PATCH_TMP_DIR/ 2> /dev/null
	fi

	#
	# Phase 3 - copy board-spec patches, allow ovewrite the common & SoC-spec patches
	#
	if [ -d $PATCH_BOARD_DIR ] ; then
		echo "--- 3) Copy board-specific patches '${PATCH_BOARD_DIR}'"
		cp $PATCH_BOARD_DIR/*.patch $PATCH_TMP_DIR/ 2> /dev/null
	fi

	#
	# Phase 4 - kernel specific - copy DT-overlay patches
	#
	if [ ! -z "${OVERLAY_PREFIX}" ]  &&  [ -d $PATCH_OVERLAY_DIR ] ; then
		local PATCHFILE=$(find $PATCH_OVERLAY_DIR -regextype posix-extended -regex ".*[0-9]+-${OVERLAY_PREFIX}-.*\.patch")
		if [ ! -z "${PATCHFILE}" ] && [ -f $PATCHFILE ] ; then
			echo "--- 4) Copy DT-overlays patch '${PATCHFILE}'"
                	cp $PATCHFILE $PATCH_TMP_DIR/
        	fi
	fi
}

#------------------------------------------------------------------------------------------------------

patch_uboot()
{
	local PATCH_BASE_DIR=$BASEDIR/patch/u-boot
	local PATCH_OUT_DIR=$OUTPUTDIR/patches

	rm -rf $PATCH_OUT_DIR/u-boot.*

	if [[ "$UBOOT_DISABLE_PATCH" != "yes"  &&  -d $PATCH_BASE_DIR ]] ; then
		local PATCH_TMP_DIR=$(mktemp -u $PATCH_OUT_DIR/u-boot.XXXXXXXXX)

		# Prepare files for patching
		mkdir -p $PATCH_TMP_DIR

		echo "Copy U-Boot base patches"

		copy_patches $PATCH_BASE_DIR	$PATCH_TMP_DIR

		if [ -d $PATCH_BASE_DIR/$UBOOT_REPO_TAG ] ; then
			echo "Copy U-Boot tag-specific patches for '${UBOOT_REPO_TAG}', allow ovewrite base patches"

			copy_patches $PATCH_BASE_DIR/$UBOOT_REPO_TAG	$PATCH_TMP_DIR
		fi

		display_alert "Patching U-Boot..." "" "info"

		local PATCH_COUNT=$(ls $PATCH_TMP_DIR/*.patch 2> /dev/null | wc -l)
		if [ $PATCH_COUNT -gt 0 ] ; then
			# patching
			for PATCHFILE in $PATCH_TMP_DIR/*.patch; do
				echo "Applying patch '${PATCHFILE}' to U-Boot..."
				patch -d $UBOOT_SOURCE_DIR --batch -p1 -N < $PATCHFILE
				[ $? -eq 0 ] || exit $?;
				echo "Patched."
			done
		fi

		echo "Done."
	fi
}

#------------------------------------------------------------------------------------------------------

get_kernel_source()
{
	local BRANCH_FIXED=$(echo $KERNEL_REPO_BRANCH | sed -e 's/\//-/g')
	LINUX_SOURCE_DIR=$KERNEL_BASE_DIR/$BRANCH_FIXED

	if [ -d $LINUX_SOURCE_DIR ] && [ -d $LINUX_SOURCE_DIR/.git ] ; then
                local KERNEL_OLD_URL=$(git -C $LINUX_SOURCE_DIR config --get remote.origin.url)
                if [ "${KERNEL_OLD_URL}" != "${KERNEL_REPO_URL}" ] ; then
			echo "Kernel repository has changed, clean up directory ?"
			pause
                        rm -rf ${LINUX_SOURCE_DIR}
                fi
        fi

	if [ -d $LINUX_SOURCE_DIR ] && [ -d $LINUX_SOURCE_DIR/.git ] ; then
		display_alert "Updating kernel from" "${KERNEL_REPO_NAME} | ${KERNEL_REPO_BRANCH}" "info"

		# update sources
		git -C $LINUX_SOURCE_DIR fetch --tags --depth=1 origin $KERNEL_REPO_BRANCH
		git -C $LINUX_SOURCE_DIR reset --hard origin/$KERNEL_REPO_BRANCH
		git -C $LINUX_SOURCE_DIR clean -fd
	else
		display_alert "Cloning kernel" "${KERNEL_REPO_NAME} | ${KERNEL_REPO_BRANCH}" "info"

		rm -rf $LINUX_SOURCE_DIR
		mkdir -p $KERNEL_BASE_DIR

		git clone $KERNEL_REPO_URL -b $KERNEL_REPO_BRANCH --depth=1 --tags $LINUX_SOURCE_DIR
	fi

	if [ ! -z $KERNEL_REPO_TAG ] ; then
		display_alert "Checking out kernel tag" "tags/${KERNEL_REPO_TAG}" "info"
		git -C $LINUX_SOURCE_DIR checkout tags/$KERNEL_REPO_TAG
	fi

	echo "Done."
}

#------------------------------------------------------------------------------------------------------

patch_kernel()
{
	local PATCH_BASE_DIR=$BASEDIR/patch/kernel/$KERNEL_REPO_NAME
	local PATCH_OUT_DIR=$OUTPUTDIR/patches

	rm -rf $PATCH_OUT_DIR/kernel.*

	if [[ "$KERNEL_DISABLE_PATCH" != "yes"  &&  -d $PATCH_BASE_DIR ]] ; then
                local PATCH_TMP_DIR=$(mktemp -u $PATCH_OUT_DIR/kernel.XXXXXXXXX)

		display_alert "Patching kernel..." "" "info"

		mkdir -p $PATCH_TMP_DIR

                echo "Copy Kernel base patches"

                copy_patches $PATCH_BASE_DIR	$PATCH_TMP_DIR

                if [ -d $PATCH_BASE_DIR/$KERNEL_REPO_TAG ] ; then
                        echo "Copy Kernel tag-specific patches for '${KERNEL_REPO_TAG}', allow ovewrite base patches"

                        copy_patches $PATCH_BASE_DIR/$KERNEL_REPO_TAG	$PATCH_TMP_DIR
                fi

		local PATCH_COUNT=$(ls $PATCH_TMP_DIR/*.patch 2> /dev/null | wc -l)
		if [ $PATCH_COUNT -gt 0 ] ; then
			# patching
			for PATCHFILE in $PATCH_TMP_DIR/*.patch; do
				echo "Applying patch '${PATCHFILE}' to kernel..."
				patch -d $LINUX_SOURCE_DIR --batch -p1 -N -F5 < $PATCHFILE
				[ $? -eq 0 ] || exit $?;
				echo "Patched."
			done
		fi

		echo "Done."
	fi
}

#------------------------------------------------------------------------------------------------------

get_firmware()
{
	if [ ! -z "${FIRMWARE_URL}" ] ; then
		mkdir -p $FIRMWARE_BASE_DIR

		if [ -d $FIRMWARE_SOURCE_DIR ] && [ -d $FIRMWARE_SOURCE_DIR/.git ] ; then
			display_alert "Updating Firmware in" "${FIRMWARE_SOURCE_DIR}" "info"

                	# update sources
			git -C $FIRMWARE_SOURCE_DIR fetch --depth=1 origin $FIRMWARE_BRANCH
			git -C $FIRMWARE_SOURCE_DIR reset --hard origin/$FIRMWARE_BRANCH
			git -C $FIRMWARE_SOURCE_DIR clean -fd
	        else
			display_alert "Cloning Firmware into" "${FIRMWARE_SOURCE_DIR}" "info"

			rm -rf $FIRMWARE_SOURCE_DIR

	                git clone $FIRMWARE_URL -b $FIRMWARE_BRANCH --depth=1 $FIRMWARE_SOURCE_DIR
        	fi
		echo "Done."
	fi
}

#------------------------------------------------------------------------------------------------------
