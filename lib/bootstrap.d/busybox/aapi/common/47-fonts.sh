#
# Install fonts
#

SOURCE_NAME=$(basename ${BASH_SOURCE[0]})

#
# ############ helper functions ##############
#
install_fonts()
{
	mkdir -p ${USR_DIR}/share/fonts/
	cp -R ${FILES_DIR}/fonts/*	${USR_DIR}/share/fonts/

	if [ "${BB_LIBC}" = gnu ] ; then

		chroot_exec ldconfig -v
	fi
	chroot_exec /usr/bin/fc-cache -fv
}


#
# ############ install packages ##############
#

install_fonts
