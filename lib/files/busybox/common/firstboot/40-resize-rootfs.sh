echo "Resize root partition..."

root_part=$(cat /proc/cmdline | grep -Eo 'root=([=\0-9a-zA-Z-]+)' | sed -e "s/^root=//")

# if partition is given as a partuuid, then find the device out of it
if [[ ${root_part} =~ ^"PARTUUID=" ]] ; then
        part_uuid=$(echo "${root_part}" | cut -d "=" -f 2)
        root_part=$(blkid -t PARTUUID="${part_uuid}" -o device)
fi

blk_dev=$(lsblk -lnp -o PKNAME ${root_part})
part_no=$(echo "${root_part}" | grep -Eo '[0-9]+$')

start_pos=$(fdisk -l 2> /dev/null | grep ${root_part} | awk '{print $2}')

fdisk ${blk_dev} <<EOF
p
d
${part_no}
n
p
${part_no}
${start_pos}

y
w
EOF

partx -u ${blk_dev}
resize2fs ${root_part}

echo "Done!"
