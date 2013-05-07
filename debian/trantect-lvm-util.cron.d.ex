#
# Regular cron jobs for the trantect-lvm-util package
#
0 4	* * *	root	[ -x /usr/bin/trantect-lvm-util_maintenance ] && /usr/bin/trantect-lvm-util_maintenance
