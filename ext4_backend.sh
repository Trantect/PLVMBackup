#!/bin/bash

LVM_PARTITION=$1
DST_DIR=$2
PARTITION_NUM=$3
FSTYPE=ext4

# add error handle for no filesystem
# add error handle for not ext4
fsck.${FSTYPE} -y "${LVM_PARTITION}"
DST_FILE=${DST_DIR}/p${PARTITION_NUM}.ext4.lzo
partclone.${FSTYPE} -c -s ${LVM_PARTITION} | lzop -c >${DST_FILE}
