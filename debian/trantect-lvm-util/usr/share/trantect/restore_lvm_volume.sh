#!/bin/bash
ORIGIAL_PATH=$(pwd)
cd "$(dirname "${BASH_SOURCE[0]}")"

#include log functions
source log.sh

#include backends functions
for bk in ./backends/*; do
    source ${bk}
done

#include mbr functions
source mbr.bash

#include meta functions
source meta.bash
cd "${ORIGIAL_PATH}"


TEMP=`getopt -o l:d:np: -l lvm:,dir:,nodata,part: -- "$@"`

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP"

ACTION="clone"
while [ $# -gt 0 ]
do
    case "$1" in
        -l|--lvm ) LVM_AGRGS="$2"; shift;;
        -d|--dir ) BACKUP_IMAGE="$2"; shift;;
        -n|--nodata ) ACTION="nodata";;
        -p|--part ) ACTION="part"; PART_NUM=$2; shift;;
        -- ) shift; break;;
        -* ) echo "$0: error - unrecognized option $1" 1>&2; exit 1;;
        *  ) break;;
    esac
    shift
done

LVM_GROUP=$(echo ${LVM_AGRGS}|gawk -F ":" '{print $1}')
LVM_VOLUME=$(echo ${LVM_AGRGS}|gawk -F ":" '{print $2}')


if [ -z "${LVM_GROUP}" ]; then
    echo "Please provide the lvm group"
    exit 1
fi
if [ -z "${LVM_VOLUME}" ]; then
    echo "Please provide the lvm volume"
    exit 1
fi
if [ -z "${BACKUP_IMAGE}" ]; then
    echo "Please provide the backup image"
    exit 1
fi


#checkimage() {
#}

create_volume() {
    local lvm_group=$1
    local lvm_volume=$2
    local size=$3
    lvcreate -L ${size} ${lvm_group} -n ${lvm_volume}
}


#restore one partition to target dev
restorepartition() {
    local partition_num=$1
    local backup_directory=$2

    local last_char=${LVM_VOLUME#${LVM_VOLUME%?}}
    local target_dev="/dev/mapper/${LVM_GROUP}-${LVM_VOLUME}${partition_num}"

    if [[ ${last_char} = [0-9] ]]; then
        target_dev="/dev/mapper/${LVM_GROUP}-${LVM_VOLUME}p${partition_num}"
    fi

    local meta_file=${backup_directory}/meta

    local fstype=$(meta_pt_info ${meta_file} ${partition_num}|gawk '{print $2}')
    _${fstype}_restore "${backup_directory}/p${partition_num}" "${target_dev}"
}

restorevolume() {
    logstep "Create a new volume with same partition"
    logaction "Create volume"
    create_volume $LVM_GROUP $LVM_VOLUME $(meta_volume_size ${BACKUP_IMAGE}/meta)
    logaction "Restore partition table"
    restore_mbr /dev/${LVM_GROUP}/${LVM_VOLUME} ${BACKUP_IMAGE}/mbr.lzo ${BACKUP_IMAGE}/table.sf
}

#restore one partition
restoreone()
{
    local partition_num=$1
    local pt_type=$(meta_pt_info ${BACKUP_IMAGE}/meta ${partition_num}|gawk '{print $1}')

    case "$pt_type" in
        "" )
            logaction "Skip partition${partition_num}"
            ;;
        "extended" )
            logaction "Skip partition${partition_num}"
            ;;
        * )
            logaction "Restore partition${partition_num} data"
            restorepartition $partition_num $BACKUP_IMAGE
            ;;
    esac
}

#restore all partitions
restoreall()
{
    logstep "Restore all partitions' data"
    for num in $(cat ${BACKUP_IMAGE}/meta|gawk 'NR>7{print $1}'); do
        restoreone $num
    done
}

TARGET=/dev/${LVM_GROUP}/${LVM_VOLUME}

case "${ACTION}" in
    #no data restore
        nodata)
            restorevolume
            ;;

    #only data
        part)
            logstep "Maping all partitions"
            kpartx -av $TARGET
            if [ ${PART_NUM} != 0 ]; then
                restoreone ${PART_NUM}
            else
                restoreall
            fi
            logstep "Unmap all partitions"
            sleep 5
            kpartx -d $TARGET
            ;;

        clone)
            restorevolume
            logstep "Maping all partitions"
            kpartx -av $TARGET
            restoreall
            logstep "Unmap all partitions"
            sleep 5
            kpartx -d $TARGET
            ;;

        *)
            echo "Invalid arguments."
            exit 1
esac
