#!/bin/bash

RAW_DEV=$1
DST_DIR=$2
SNAPSHOT_SIZE=$3

TIMESTAMP=`date +%Y%m%d%H%M`
LVM_GROUP=`echo ${RAW_DEV}|gawk -F '/' '{print $3}'`
LVM_VOLUME=`echo ${RAW_DEV}|gawk -F '/' '{print $4}'`
SNAPSHOT_DEV="/dev/${LVM_GROUP}/${LVM_VOLUME}_${TIMESTAMP}"
PARTITION_PREFIX="/dev/mapper/${LVM_GROUP}-${LVM_VOLUME}_${TIMESTAMP}p"
#echo ${PARTITION_PREFIX}

logstep() {
    local content=$@
    echo "---${content}"
}
logaction() {
    local content=$@
    echo "   * ${content}"
}
logresult() {
    local content=$@
    echo "     ""${content}"
}

listresult() {
    local content=$@
    echo "$content" | (while read l; do
        logresult "$l"
    done)
}
logerror() {
    local content=$@
    echo "     ${content}"
}
listerror() {
    local content=$@
    echo "$content" | (while read l; do
        logerror $l
    done)
}

snapshot() {
    logstep "Parepre for backuping..."
    local raw_dev=$1
    local snapshot_dev=$2
    local snapshot_size=$3
    logaction "Create snapshot for current state"
    output=$(lvcreate -L${snapshot_size} -s -n ${snapshot_dev} ${raw_dev} 2>&1)
    local result=$?
    case $result in
        0)
            listresult "$output"
            ;;
        *)  logerror "Failed to create snapshot"
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
}

backupmbr() {
    local snapshot_dev=$1
    local mbr_file=$2
    dd if=${snapshot_dev} bs=512 count=2048|lzop -c >${mbr_file}
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
        #skip extended partition
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
            logaction "Backup partition${pnum} ${pttype} ${fstype}"
            output=$(./${fstype}_backend.sh "${p}" "${DST_DIR}" "${pnum}" 2>&1 1>/dev/null)
            listresult "$output"
        fi
        # unmap the snapshot
    done
    sleep 5
    logaction "Unmap the partitions"
    kpartx -d ${dev}
}

snapshot $RAW_DEV $SNAPSHOT_DEV $SNAPSHOT_SIZE
#backupmeta $SNAPSHOT_DEV $TIMESTAMP $RAW_DEV ${DST_DIR}/meta
#backupmbr ${SNAPSHOT_DEV} ${DST_DIR}/mbr.lzo
backupparts ${PARTITION_PREFIX} ${SNAPSHOT_DEV}
rmsnapshot $SNAPSHOT_DEV
