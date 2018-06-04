#
# Install firmware files
#

rsync -avz ${FILES_DIR}/firmware/edid ${LIB_DIR}/firmware
rsync -avz ${FILES_DIR}/firmware/brcm ${LIB_DIR}/firmware

