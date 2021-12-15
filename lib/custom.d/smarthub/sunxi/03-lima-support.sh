#
# Check LIMA support (sunxi)
#

if [ "${MALI_BLOB_TYPE}" = "lima" ] ; then

        # If LIMA support flag was explicitly set let's figure out if we can support it
        if [[ $KERNEL_VER_MAJOR -ge 5  &&  $KERNEL_VER_MINOR -ge 2 ]] ; then
		echo "Mali GPU support by LIMA Kernel driver"
        else
		display_alert "LIMA driver is supported by Kernel v${KERNEL_VER_MAJOR}.${KERNEL_VER_MINOR} or above. Please, switch to a newer Kernel or use any of 3-rd party Mali blobs." "" "err"
		exit 1
        fi
fi
