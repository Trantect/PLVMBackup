#!/bin/bash

SNAPSHOT_SIZE=100M
TEMP=`getopt -o s: -- "$@"`

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP"

#set -- $(getopt s: "$@")
while [ $# -gt 0 ]
do
    case "$1" in
        -s ) SNAPSHOT_SIZE="$2"; shift;;
        -- ) shift; break;;
        -* ) echo "$0: error - unrecognized option $1" 1>&2; exit 1;;
        *  ) break;;
    esac
    shift
done

RAW_DEV=$1
DST_DIR=$2

if [ -z "$RAW_DEV" ]; then
    echo Error Parameters
    exit 1
fi
if [ -z "$DST_DIR" ]; then
    echo Error Parameters
    exit 1
fi
if [ ! -b "$RAW_DEV" ]; then
    echo $RAW_DEV is not existed.
    exit 1
fi

if [ ! -d "$DST_DIR" ]; then
    echo No such directory: $DST_DIR.
    exit 1
fi

TIMESTAMP=`date +%Y%m%d%H%M`
LVM_GROUP=`echo ${RAW_DEV}|gawk -F '/' '{print $3}'`
LVM_VOLUME=`echo ${RAW_DEV}|gawk -F '/' '{print $4}'`
SNAPSHOT_DEV="/dev/${LVM_GROUP}/${LVM_VOLUME}_${TIMESTAMP}"
PARTITION_PREFIX="/dev/mapper/${LVM_GROUP}-${LVM_VOLUME}_${TIMESTAMP}p"

#include log functions
source log.sh

snapshot() {
    logstep "Parepre for backuping..."
    local raw_dev=$1
    local snapshot_dev=$2
    local snapshot_size=$3
    logaction "Create snapshot for current state"
    output=$(lvcreate -L${snapshot_size} -s -n ${snapshot_dev} ${raw_dev} 2>&1)
    local result=$?
    case $result in
        0) listresult "$output"
           ;;
        *) logerror "Failed to create snapshot"
           listresult "${output}"
           exit 1
           ;;
    esac
}

rmsnapshot() {
    logstep "Finish backuping"
    local snapshot_dev=$1
    logaction "Remove snapshot"
    sleep 5
    local output=`lvremove -f ${snapshot_dev}`
    listresult "$output"
}


backupmeta() {
    local snapshot_dev=$1
    local timestamp=$2
    local raw_dev=$3
    local meta_file=$4
    #get the meta info
    local byte_size=`fdisk -l ${snapshot_dev}|grep "bytes" |gawk '/Disk/{print $5}'`

    #get partition info
    local partitions="`parted ${snapshot_dev} print|gawk '{print $1,$5,$6}'|sed '1,6d'|sed '$d'`"
    #backup the mbr info
    cat <<EOF > $meta_file
[Size]
${byte_size} bytes
[Time]
${timestamp}
[Path]
${raw_dev}
[Partition]
EOF
    echo "$partitions" >> $meta_file
}

#get partition info
getptinfo() {
    local dev=$1
    local partition_num=$2
    local partitions="`parted ${dev} print|gawk '{print $1,$5,$6}'|sed '1,6d'|sed '$d'`"
    echo "$partitions" | (while read l; do
        local num=`echo $l|gawk '{print $1}'`
        if [ "$num" -eq $partition_num ]; then
            #return "partition_type" "filesystem_type"
            echo "`echo $l|gawk '{print $2}'` `echo $l|gawk '{print $3}'`"
            exit 0
        fi
    done)
    exit 1
}

backupmbr() {
    local snapshot_dev=$1
    local mbr_file=$2
    local table_file=$3
    dd if=${snapshot_dev} bs=512 count=2048 |lzop -c >${mbr_file}
    sfdisk ${snapshot_dev} -d > ${table_file}
}
# backup all the partitions
backupparts() {
    local partition_perfix=$1
    local dev=$2
    # map the snapshot
    #echo "kpartx -av ${dev}"
    logstep "Backuping partitions"
    logaction "Map all partitions"
    local output=`kpartx -av ${dev} || ( echo "kpartx failed" >&2 && exit 1 )`
    listresult "$output"

    for p in ${partition_perfix}*; do
        #add error handle for no backend file
        local pnum=${p#${partition_perfix}}
        local ptinfo=`getptinfo ${dev} ${pnum}`

        local pttype=`echo $ptinfo|gawk '{print $1}'`
        local fstype=`echo $ptinfo|gawk '{print $2}'`
        #add error handle for no filesystem
        case $fstype in
            fat16)
                fstype="vfat"
                ;;
            fat32)
                fstype="vfat"
                ;;
            *)
                ;;
        esac
        if [ "$pttype" != extended ]; then
            logaction "backup partition${pnum} ${pttype} ${fstype}"
            output=$(./${fstype}_backup.sh "${p}" "${DST_DIR}" "${pnum}" 2>&1)
            listresult "$output"
        fi
        # unmap the snapshot
    done
    sleep 5
    logaction "Unmap the partitions"
    kpartx -d ${dev}
}

snapshot $RAW_DEV $SNAPSHOT_DEV $SNAPSHOT_SIZE
backupmeta $SNAPSHOT_DEV $TIMESTAMP $RAW_DEV ${DST_DIR}/meta
backupmbr ${SNAPSHOT_DEV} ${DST_DIR}/mbr.lzo ${DST_DIR}/table.sf
backupparts ${PARTITION_PREFIX} ${SNAPSHOT_DEV}
rmsnapshot $SNAPSHOT_DEV
