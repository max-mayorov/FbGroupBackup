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
#copy this file to /etc/init.d/
DESC="NikiKiri fb group backup HTTP server"
NAME=nikikirihttpd
#DAEMON=
# Start the service MAT
start() {
        d=$(pwd)
        i=0
        loc="/media/a8510270-6ecd-4eba-8482-b16ee4af414a/NikiKiri"
        while [ ! -d "$loc" ]; do
          if [ "$i" -gt 300 ]; then
            #Time out here
            exit_var=1
            echo "Error: $loc is not found"
            return
          fi
          sleep 2
          i=i+1
        done
        cd $loc 
        ### Create the lock file ###
        python3.4 -m http.server 9999 &
        cd $d
        echo
}
# Restart the service MAT
stop() {
        kill $(netstat -tulpn 2>/dev/null | grep 0.0.0.0:9999 | grep -oE [0-9]+/python | grep -oE [0-9]+)

        ### Now, delete the lock file ###
        echo
}
status() {
      if netstat -tulpn 2>/dev/null | grep 0.0.0.0:9999; then
            exit_var=3
            echo "Service is not running"
      else
            exit_var=0
            echo "Service is running"
      fi
}
### main logic ###
exit_var=0
case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  status)
        status
        ;;
  restart|reload|condrestart)
        stop
        start
        ;;
  *)
        echo $"Usage: $0 {start|stop|restart|reload|status}"
        exit 1
esac
exit $exit_var