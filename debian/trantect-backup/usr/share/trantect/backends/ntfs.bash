#!/bin/bash

_ntfs_backup()
{
    local partition=$1
    #the ouput path do not contain the extra name
    #you can add any extra name as you like
    local output=$2

    local dst_file=${output}.ntfs.lzo
    ntfsfix ${partition}
    ntfsclone -f -s -o - ${partition}|lzop -c >${dst_file}
}

_ntfs_restore()
{
    local input=$1
    local partition=$2

    #fix the extended name
    local input_file=${input}.ntfs.lzo
    lzop -dc ${input_file}|ntfsclone -r -O ${partition} -
}
