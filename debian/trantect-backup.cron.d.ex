#
# Regular cron jobs for the trantect-backup package
#
0 4	* * *	root	[ -x /usr/bin/trantect-backup_maintenance ] && /usr/bin/trantect-backup_maintenance
