#!/bin/bash

#LVM_GROUP=$1
#LVM_VOLUME=$2
RAW_DEV=$1
DST_DIR=$2
SNAPSHOT_SIZE=$3
FSTYPE=$4

TIMESTAMP=`date +%Y%m%d%H%M`
#RAW_DEV="/dev/${LVM_GROUP}/${LVM_VOLUME}"
LVM_GROUP=`echo ${RAW_DEV}|gawk -F '/' '{print $3}'`
LVM_VOLUME=`echo ${RAW_DEV}|gawk -F '/' '{print $4}'`
SNAPSHOT_DEV="/dev/${LVM_GROUP}/${LVM_VOLUME}_${TIMESTAMP}"
PARTITION_PREFIX="/dev/mapper/${LVM_GROUP}-${LVM_VOLUME}_${TIMESTAMP}p"
echo ${PARTITION_PREFIX}

#create the snapshot for current state
echo "lvcreate -L${SNAPSHOT_SIZE} -s -n ${SNAPSHOT_DEV} ${RAW_DEV}"
lvcreate -L${SNAPSHOT_SIZE} -s -n ${SNAPSHOT_DEV} ${RAW_DEV} > /dev/null || ( echo "Failed to create snapshot" >&2 && exit 1 )

# map the snapshot
echo "kpartx -av ${SNAPSHOT_DEV}"
kpartx -av ${SNAPSHOT_DEV} >/dev/null || ( echo "kpartx failed" >&2 && exit 1 )
#dir -al ${PARTITION_PREFIX}*

#get the meta info
BYTE_SIZE=`fdisk -l ${SNAPSHOT_DEV} | grep "bytes" |gawk '/Disk/{print $5}'`
#echo ${BYTE_SIZE} > ${DST_DIR}/${LVM_VOLUME}_${TIMESTAMP}.meta
echo "${BYTE_SIZE} bytes"> ${DST_DIR}/meta
echo "${TIMESTAMP}">> ${DST_DIR}/meta
echo "${RAW_DEV}" >> ${DST_DIR}/meta

#backup the mbr info
#MBR_FILE=${DST_DIR}/${LVM_GROUP}-${LVM_VOLUME}.mbr.lzo
MBR_FILE=${DST_DIR}/mbr.lzo
echo $DST_FILE
dd if=${SNAPSHOT_DEV} bs=512 count=2048|lzop -c >${MBR_FILE}

# backup all the partitions
for P in ${PARTITION_PREFIX}*; do
    #add error handle for no backend file
    PARTITION_NUM=${P#${PARTITION_PREFIX}}
    ./${FSTYPE}_backend.sh "${P}" "${DST_DIR}" "${PARTITION_NUM}"
done

# unmap the snapshot
sleep 5
kpartx -d ${SNAPSHOT_DEV}

# remove the snapshot
sleep 5
lvremove -f ${SNAPSHOT_DEV}


