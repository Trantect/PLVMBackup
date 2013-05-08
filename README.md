PLVMBackup
==========

Backup/restore utilities of LVM with partitions.
If you use the volume as a disk (not a partition) and want to backup/restore them, you will be glad to try this tool.

## Scenario
Imagine You having three LVM lvs

    /dev/lvm/v1             1 partition
    /dev/lvm/v2             2 partitions
    /dev/lvm/v3             3 partitions

Then this tool can backup those lvs' partitions table and all the partition data.

## Building Debian/Ubuntu package
### Build it

    dpkg-buildpackage -tc -b

## Install with PPA repository (Ubuntu)

	sudo add-apt-repository ppa:xiaobo-fei/ppa
	sudo apt-get update
	sudo apt-get install trantect-lvm-util

## Run it

    trantect-backup -s 2G /dev/lvm/v1 /tmp/backup
    trantect-restore -l lvm/v2 -d /tmp/backup
