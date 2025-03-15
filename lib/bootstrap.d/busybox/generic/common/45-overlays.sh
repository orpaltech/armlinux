#
# Install DT overlays
#

SOURCE_NAME=$(basename ${BASH_SOURCE[0]})

#
# ############ helper functions ##############
#

install_overlays()
{
	local dest_overlay_dir="${BOOT_DIR}/overlays"
	local build_overlay_dir="${KERNEL_SOURCE_DIR}/arch/${KERNEL_ARCH}/boot/dts/${KERNEL_OVERLAY_DIR}"

	local dtbo_count=$(count_files "${build_overlay_dir}/${OVERLAY_PREFIX}-*.dtbo")
	if [ ${dtbo_count} -gt 0 ] ; then
                echo "${SOURCE_NAME}: Found ${dtbo_count} overlays in ${build_overlay_dir}"
                mkdir -p ${dest_overlay_dir}

                for path in ${build_overlay_dir}/${OVERLAY_PREFIX}-*.dtbo ; do
                        test -f "$path" || continue
                        echo "${SOURCE_NAME}: Installing ${path}"
                        install_readonly $path	${dest_overlay_dir}/
                done

                for path in ${build_overlay_dir}/${OVERLAY_PREFIX}-*.scr ; do
                        test -f "$path" || continue
                        echo "${SOURCE_NAME}: Installing ${path}"
                        install_readonly $path	${dest_overlay_dir}/
                done

                local readme_file="${build_overlay_dir}/README.${OVERLAY_PREFIX}-overlays"

                if [ -f ${readme_file} ] ; then
                        echo "${SOURCE_NAME}: Installing ${readme_file}"
                        install_readonly $readme_file	${dest_overlay_dir}/
                fi
        elif [ -d ${build_overlay_dir} ] ; then
                echo "${SOURCE_NAME}: [WARNING] Directory ${build_overlay_dir} exists but 0 overlays found"
        else
                echo "${SOURCE_NAME}: No overlays found, skip"
        fi
}


#
# ############ install packages ##############
#

install_overlays
