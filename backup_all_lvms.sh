#!/bin/bash

LVM_GROUP=$1
LVMS_LIST=$2
DST_DIR=$3

BACKUP_LVM=./backup_lvm_volume.sh
#LVM_GROUP=SHARED_LVM
#LVMS=`grep -v '#' /usr/local/etc/lvm_backup/lvms.txt`
LVMS=`grep -v '#' ${LVMS_LIST}`
#DST_DIR=/home/yale/TimeMachine/lvm
SNAPSHOT_SIZE=2G
EXPIRE_DAYS=+7

#find "${DST_DIR}" -type f -mtime "${EXPIRE_DAYS}" -name "*.pcl.*" |xargs -n1 rm
TIME=$(date +%Y%m%d)
mkdir -p $DST_DIR/$TIME
for A in ${LVMS}; do
	echo "${A}"
    TARGET_DIR=$DST_DIR/${TIME}/${A}
    #mkdir -p $DST_DIR/${LVM_GROUP}
    mkdir -p ${TARGET_DIR}
	${BACKUP_LVM} -s "${SNAPSHOT_SIZE}" /dev/${LVM_GROUP}/${A} ${TARGET_DIR}
done

