#
# First boot actions
#

SOURCE_NAME=$(basename ${BASH_SOURCE[0]})

#
# ############ helper functions ##############
#

setup_firstboot()
{

FIRSTBOOT_SCRIPT=${ETC_DIR}/init.d/S99firstboot

# Prepare firstboot script
cat ${FILES_DIR}/firstboot/10-begin.sh > ${FIRSTBOOT_SCRIPT}

# Resize rootfs partition
cat ${FILES_DIR}/firstboot/40-resize-rootfs.sh >> ${FIRSTBOOT_SCRIPT}

# Add custom scripts in the range 50..89
for custom_script in ${FILES_DIR}/firstboot/{5..8}{0..9}-*.sh; do
  if [ -f "${custom_script}" ] ; then
    cat ${custom_script} >> ${FIRSTBOOT_SCRIPT}
  fi
done

# Finalize script
cat ${FILES_DIR}/firstboot/99-finish.sh >> ${FIRSTBOOT_SCRIPT}
chmod +x ${FIRSTBOOT_SCRIPT}

}


#
# ############# setup actions  ###############
#

setup_firstboot
