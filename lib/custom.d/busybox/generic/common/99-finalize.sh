#
# Finalize image customization
#

if [ "${BB_LIBC}" = gnu ] ; then

    chroot_exec ldconfig -v
fi
