#!/bin/bash

IMAGE_FILE=$1
LVM_PARTITION=$2

#Do we need this
ntfsfix $LVM_PARTITION

lzop -dc ${IMAGE_FILE}|ntfsclone -r -O ${LVM_PARTITION} -
