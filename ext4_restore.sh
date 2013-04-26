#!/bin/bash

IMAGE_FILE=$1
LVM_VOLUME=$2

lzop -dc ${IMAGE_FILE}|partclone.ext4 -r -o $LVM_VOLUME
