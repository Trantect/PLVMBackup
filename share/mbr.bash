#!/bin/bash

backup_mbr()
{
    local dev=$1
    local mbr_file=$2
    local table_file=$3
    dd if=${dev} bs=512 count=2048|lzop -c >${mbr_file}
    sfdisk ${dev} -d > ${table_file}
}

restore_mbr()
{
    local dev=$1
    local mbr_file=$2
    local table_file=$3

    lzop -dc ${mbr_file}|dd bs=512 count=1 of=${dev}
    sfdisk --force ${dev} < ${table_file}
}
