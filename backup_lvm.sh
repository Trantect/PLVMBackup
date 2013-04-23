#!/bin/bash

LVM_GROUP=$1
LVM_VOLUME=$2
DST_DIR=$3
SNAPSHOT_SIZE=$4
FSTYPE=$5

TIMESTAMP=`date +%Y%m%d%H%M`
RAW_DEV="/dev/${LVM_GROUP}/${LVM_VOLUME}"
SNAPSHOT_DEV="/dev/${LVM_GROUP}/${LVM_VOLUME}_${TIMESTAMP}"
PARTITION_PREFIX="/dev/mapper/${LVM_GROUP}-${LVM_VOLUME}_${TIMESTAMP}p"
echo ${PARTITION_PREFIX}

echo "lvcreate -L${SNAPSHOT_SIZE} -s -n ${SNAPSHOT_DEV} ${RAW_DEV}"
lvcreate -L${SNAPSHOT_SIZE} -s -n ${SNAPSHOT_DEV} ${RAW_DEV} || ( echo "Failed to create snapshot" >&2 && exit 1 )
echo "kpartx -av ${SNAPSHOT_DEV}"
kpartx -av ${SNAPSHOT_DEV} || ( echo "kpartx failed" >&2 && exit 1 )
dir -al ${PARTITION_PREFIX}*
for A in ${PARTITION_PREFIX}*; do
	echo $A
	if [ ${FSTYPE} == "ext4" ]; then
		fsck.${FSTYPE} -y $A
	fi
	DST_FILE=${DST_DIR}/`echo ${A}|gawk -F'/' '{print $4}'`.pcl.lzo
	echo $DST_FILE
	echo "partclone.${FSTYPE} -c -s ${A} | lzop -c >${DST_FILE}"
	partclone.${FSTYPE} -c -s ${A} | lzop -c >${DST_FILE}
done
sleep 5
kpartx -d ${SNAPSHOT_DEV}
sleep 5
lvremove -f ${SNAPSHOT_DEV}


