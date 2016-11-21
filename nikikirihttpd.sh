#!/bin/sh
### BEGIN INIT INFO
# Provides:          nikikirihttpd
# Required-Start:    $local_fs
# Required-Stop:     $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# X-Interactive:     false
# Short-Description: NikiKiri fb group backup HTTP server
# Description:       Start/stop NikiKiri fb group backup HTTP server
### END INIT INFO

DESC="NikiKiri fb group backup HTTP server"
NAME=nikikirihttpd
#DAEMON=
# Start the service MAT
start() {
        initlog -c "echo -n Starting nikikirihttpd server: "
        cd /media/a8510270-6ecd-4eba-8482-b16ee4af414a/NikiKiri
        ### Create the lock file ###
        touch /var/lock/subsys/nikikirihttpd
        success $"MAT server startup"
        echo
}
# Restart the service MAT
stop() {
        initlog -c "echo -n Stopping MAT server: "
        killproc MAT
        ### Now, delete the lock file ###
        rm -f /var/lock/subsys/MAT
        echo
}
### main logic ###
case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  status)
        status MAT
        ;;
  restart|reload|condrestart)
        stop
        start
        ;;
  *)
        echo $"Usage: $0 {start|stop|restart|reload|status}"
        exit 1
esac
exit 0