#!/bin/bash

########################################################################
# The script installs Docker - Virtualization tool for delivering 
#				software in isolated containers
########################################################################

apt-get -qq -y update

curl -fsSL https://get.docker.com -o /chroot_scripts/get-docker.sh
chmod +x /chroot_scripts/get-docker.sh
/chroot_scripts/get-docker.sh
rm -f /chroot_scripts/get-docker.sh

# docker volume create portainer_data
# docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
