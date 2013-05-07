#!/bin/bash

meta_backup()
{
    local snapshot_dev=$1
    local timestamp=$2
    local raw_dev=$3
    local meta_file=$4

    #get the meta info
    local byte_size=`fdisk -l ${snapshot_dev}|grep "bytes"|gawk '/Disk/{print $5}'`

    #get partition info
    local partitions="`parted ${snapshot_dev} print|gawk '{print $1,$5,$6}'|sed '1,6d'|sed '$d'`"

cat <<EOF > $meta_file
Size=${byte_size}b
Time=${timestamp}
Path=${raw_dev}
Partition="${partitions}"
EOF
}


meta_volume_size()
{
    local meta_file=$1
    source ${meta_file}
    echo $Size
}

#get the partitions type and filesystem type
meta_pt_info()
{
    local meta_file=$1
    local partition_num=$2
    source ${meta_file}

    echo "${Partition}"|(while read l; do
        local num=$(echo $l|gawk '{print $1}')
        if [ "$num" -eq $partition_num ]; then
            echo "$(echo $l|gawk '{print $2,$3}')"
            exit 0
        fi
    done)
    exit 1
}
