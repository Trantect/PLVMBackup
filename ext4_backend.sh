#!/bin/bash

LVM_PARTITION=$1
DST_DIR=$2
PARTITION_NUM=$3
FSTYPE=ext4

# add error handle for no filesystem
# add error handle for not ext4
echo $LVM_PARTITION
fsck.${FSTYPE} -y $LVM_PARTITION
#DST_FILE=${DST_DIR}/`echo ${LVM_PARTITION}|gawk -F'/' '{print $4}'`.pcl.lzo
DST_FILE=${DST_DIR}/p${PARTITION_NUM}.ext4.lzo
echo $DST_FILE
echo "partclone.${FSTYPE} -c -s ${LVM_PARTITION} | lzop -c >${DST_FILE}"
partclone.${FSTYPE} -c -s ${LVM_PARTITION} | lzop -c >${DST_FILE}
