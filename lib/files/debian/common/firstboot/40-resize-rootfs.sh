logger -t "rc.firstboot" "Resizing rootfs..."

root_part=$(cat /proc/cmdline | grep -Po "root=\K[-=\w]*\s")

# if partition is given as a uuid, then find the device name
if [[ ${root_part} =~ ^"PARTUUID=" ]] ; then
	part_uuid=$(echo "${root_part}" | cut -d "=" -f 2)
	root_part=$(readlink -en /dev/disk/by-partuuid/${part_uuid})
fi
blk_dev=$(lsblk -lnp -o PKNAME ${root_part})
part_num=$(echo "${root_part}" | grep -Eo '[0-9]+$')

start_pos=$(fdisk -l | grep ${root_part} | awk '{print $2}')

fdisk ${blk_dev} <<EOF
p
d
${part_num}
n
p
${part_num}
${start_pos}

y
w
EOF

partx -u ${blk_dev}
resize2fs ${root_part}

echo "Done!"
