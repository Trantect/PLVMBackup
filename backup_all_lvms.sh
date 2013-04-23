#!/bin/bash

BACKUP_LVM=./backup_lvm.sh
LVM_GROUP=SHARED_LVM
LVMS=`grep -v '#' /usr/local/etc/lvm_backup/lvms.txt`
DST_DIR=/home/yale/TimeMachine/lvm
SNAPSHOT_SIZE=2G
FS_TYPE=ext4
EXPIRE_DAYS=+7

find "${DST_DIR}" -type f -mtime "${EXPIRE_DAYS}" -name "*.pcl.*" |xargs -n1 rm 

for A in ${LVMS}; do
	echo "${A}"
	${BACKUP_LVM} "${LVM_GROUP}" "${A}" "${DST_DIR}" "${SNAPSHOT_SIZE}" "${FS_TYPE}"
done

