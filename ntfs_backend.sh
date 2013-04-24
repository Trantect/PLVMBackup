#!/bin/bash

LVM_PARTITION=$1
DST_DIR=$2
PARTITION_NUM=$3

ntfsfix $LVM_PARTITION
#DST_FILE=${DST_DIR}/`echo ${LVM_PARTITION}|gawk -F'/' '{print $4}'`.ntfsclone.lzo
DST_FILE=${DST_DIR}/p${PARTITION_NUM}.ntfs.lzo
ntfsclone -f -s -o - ${LVM_PARTITION} | lzop -c >${DST_FILE}
