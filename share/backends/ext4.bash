#!/bin/bash

_ext4_backup()
{
    local partition=$1
    #the ouput path do not contain the extend name
    #you can add any extended name as you like
    local output=$2

    local dst_file=${output}.ext4.lzo
    fsck.ext4 -y "${partition}"
    partclone.ext4 -c -s ${partition} | lzop -c >${dst_file}
}

_ext4_restore()
{
    local input=$1
    local partition=$2

    #fix the extended name
    local input_file=${input}.ext4.lzo
    lzop -dc ${input_file}|partclone.ext4 -r -O $partition
}
