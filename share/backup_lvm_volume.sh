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
#include mbr functions
source meta.bash
cd "${ORIGIAL_PATH}"

snapshot()
{
    logstep "Parepre for backuping"
    local raw_dev=$1
    local snapshot_dev=$2
    local snapshot_size=$3
    logaction "Create snapshot for current state"
    lvcreate -L${snapshot_size} -s -n ${snapshot_dev} ${raw_dev}
    local result=$?
    case $result in
        0) ;;
        *) logerror "Failed to create snapshot"
           exit 1
           ;;
    esac
}

rm_snapshot()
{
    logstep "Finish backuping"
    local snapshot_dev=$1
    logaction "Remove snapshot"
    sleep 5
    lvremove -f ${snapshot_dev}
}


# backup all the partitions
backup_parts()
{
    local partition_perfix=$1
    local dev=$2
    local dst_dir=$3
    # map the snapshot
    logstep "Backuping partitions"
    logaction "Map all partitions"
    kpartx -av ${dev} || ( echo "kpartx failed" >&2 && exit 1 )

    for p in ${partition_perfix}*; do
        #add error handle for no backend file
        local pnum=${p#${partition_perfix}}
        #local ptinfo=`getptinfo ${dev} ${pnum}`
        local ptinfo=$(meta_pt_info ${dst_dir}/meta ${pnum})

        local pttype=`echo $ptinfo|gawk '{print $1}'`
        local fstype=`echo $ptinfo|gawk '{print $2}'`
        #add error handle for no filesystem

        if [ "$pttype" != extended ]; then
            logaction "backup partition${pnum} ${pttype} ${fstype}"
            local output=${dst_dir}/p${pnum}
            _${fstype}_backup ${p} ${output}
        fi
    done

    # unmap the snapshot
    sleep 5
    logaction "Unmap the partitions"
    kpartx -d ${dev}
}

show_help()
{

    echo "Usage:"
    echo "   trantect-backup [options] <device> <backup_path>"
    echo
    echo "Parameters:"
    echo "device                             Target device for backuping"
    echo "backup_path                        Directory for backup"
    echo
    echo "Options:"
    echo "-s, --size <snapshot_size>         snapshot size to use during the backup process"
    echo "-h, --help                         Display this help"
    exit 0
}
main()
{

    local snapshot_size=100M
    local tmp=`getopt -o s:h -l help,size: -- "$@"`

    if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

    # Note the quotes around `$TEMP': they are essential!
    eval set -- "$tmp"

    while [ $# -gt 0 ]
    do
        case "$1" in
            -s|--size ) snapshot_size="$2"; shift;;
            -h|--help) show_help; shift;;
            -- ) shift; break;;
            -* ) echo "$0: error - unrecognized option $1" 1>&2; exit 1;;
            *  ) break;;
        esac
        shift
    done

    local raw_dev=$1
    local dst_dir=$2

    if [ -z "$raw_dev" ]; then
        echo Error Parameters
        exit 1
    fi
    if [ -z "$dst_dir" ]; then
        echo Error Parameters
        exit 1
    fi
    if [ ! -b "$raw_dev" ]; then
        echo $raw_dev is not existed.
        exit 1
    fi

    if [ ! -d "$dst_dir" ]; then
        pwd
        echo No such directory: $dst_dir
        exit 1
    fi

    timestamp=`date +%Y%m%d%H%M`
    lvm_group=`echo ${raw_dev}|gawk -F '/' '{print $3}'`
    lvm_volume=`echo ${raw_dev}|gawk -F '/' '{print $4}'`
    snapshot_dev="/dev/${lvm_group}/${lvm_volume}_${timestamp}"
    partition_prefix="/dev/mapper/${lvm_group}-${lvm_volume}_${timestamp}p"

    local meta_file="${dst_dir}/meta"
    local mbr_file="${dst_dir}/mbr.lzo"
    local table_file="${dst_dir}/table.sf"

    snapshot $raw_dev $snapshot_dev $snapshot_size
    meta_backup $snapshot_dev $timestamp $raw_dev ${meta_file}
    backup_mbr ${snapshot_dev} ${mbr_file} ${table_file}
    backup_parts ${partition_prefix} ${snapshot_dev} ${dst_dir}
    rm_snapshot $snapshot_dev
}

main "$@"
