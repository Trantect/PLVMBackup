#!/bin/bash

LVM_GROUP=$1
LVM_VOLUME=$2
BACKUP_IMAGE=$3

#include log functions
source log.sh

#checkimage() {
#}

createvolume() {
    local lvm_group=$1
    local lvm_volume=$2
    local size=$3
    lvcreate -L ${size} ${lvm_group} -n ${lvm_volume}
}

restorembr() {
    local dev=$1
    local mbr_file=$2
    lzop -dc ${mbr_file}|dd bs=512 count=2048 of=${dev}
}

#get volumesize (bytes)
getvolumesize() {
    local meta_file=$1

    echo $(cat ${meta_file}|gawk 'NR==2{print $1}')b
}

getptinfo() {
    local meta_file=$1
    local partition_num=$2

    cat ${meta_file}|sed '1,7d'|(while read l; do
        local num=$(echo $l|gawk '{print $1}')
        if [ "$num" -eq $partition_num ]; then
            echo "$(echo $l|gawk '{print $2,$3}')"
            exit 0
        fi
    done)
    exit 1
}

#getptinfo tmp/meta 5|gawk '{print $2}'

restorepartition() {
    local partition_num=$1
    local backup_directory=$2

    local last_char=${LVM_VOLUME#${LVM_VOLUME%?}}
    local target_dev="/dev/mapper/${LVM_GROUP}-${LVM_VOLUME}${partition_num}"
    if [[ $c = [0-9] ]]; then
        local target_dev="/dev/mapper/${LVM_GROUP}-${LVM_VOLUME}p${partition_num}"
    fi

    local meta_file=${backup_directory}/meta

    local fstype=$(getptinfo ${meta_file} ${partition_num}|gawk '{print $2}')
    ./${fstype}_restore.sh "${backup_directory}/p${partition_num}.${fstype}.lzo" "${target_dev}"
}

#restoreallpartitions(){
    #restorepartition /dev 1 tmp/
#}
clonevolume() {
    createvolume $LVM_GROUP $LVM_VOLUME $(getvolumesize ${BACKUP_IMAGE}/meta)
    restorembr /dev/${LVM_GROUP}/${LVM_VOLUME} ${BACKUP_IMAGE}/mbr.lzo
}


restoreone() {
    local partition_num=$1
    restorepartition $partition_num $BACKUP_IMAGE
}

restoreall() {
    for num in $(cat ${BACKUP_IMAGE}/meta|gawk 'NR>7{print $1}'); do
        local pttype=$(getptinfo ${BACKUP_IMAGE}/meta ${num}|gawk '{print $1}')
        if [ "$pttype" != extended ]; then
            restoreone $num
        fi
    done
}

clonevolume
#kpartx -av /dev/$LVM_GROUP/$LVM_VOLUME
#restoreall
#sleep 5
#kpartx -d /dev/$LVM_GROUP/$LVM_VOLUME

clone() {
    createvolume $LVM_GROUP $LVM_VOLUME $(getvolumesize ${BACKUP_IMAGE}/meta)
    restorembr /dev/${LVM_GROUP}/${LVM_VOLUME} ${BACKUP_IMAGE}/mbr.lzo
}
