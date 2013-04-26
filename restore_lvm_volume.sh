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
    local size=$2
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

    echo $(cat {meta_file}|gawk 'NR==2{print $1}')b
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

getptinfo tmp/meta 5|gawk '{print $2}'

restorepartition() {
    local dev=$1
    local partition_num=$2
    local backup_directory=$3

    local meta_file=${backup_directory}/meta_file

    local fstype=$(getptinfo ${meta_file} ${partition_num}|gawk 'print $2')
    ./${fstype}_restore.sh "${backup_directory}/p${partition_num}.${fstype}.lzo" "${dev}"
}

restoreallpartitions(){
    restorepartition /dev 1 tmp/
}
