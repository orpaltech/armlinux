logger -t "rc.firstboot" "Resizing rootfs..."

DEVICE="/dev/mmcblk0"
PART="1"
START=$(fdisk -l ${DEVICE}|grep ${DEVICE}p${PART}|awk '{print $2}')
echo "Range: ${START} - ${END}"

fdisk ${DEVICE} <<EOF
p
d
n
p
$PART
$START

w
EOF

partx -u ${DEVICE}
resize2fs ${DEVICE}p${PART}

echo "Done!"
