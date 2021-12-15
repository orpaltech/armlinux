logger -t "rc.firstboot" "Resizing rootfs..."

BLOCK_DEV=/dev/sdX
PART_NUM=1
START=$(fdisk -l ${BLOCK_DEV}|grep ${BLOCK_DEV}p${PART_NUM}|awk '{print $2}')

fdisk ${BLOCK_DEV} <<EOF
p
d
${PART_NUM}
n
p
${PART_NUM}
${START}

w
EOF

partx -u ${BLOCK_DEV}
resize2fs ${BLOCK_DEV}p${PART_NUM}

echo "Done!"
