#!/bin/sh
#Update installation_dir with the folder where feed.py is located
installation_dir="/media/a8510270-6ecd-4eba-g8482-b16ee4af414a/NikiKiri"
python_exec="python3.4"
#End of configuration


waitformedia(){
    i=0
    while [ ! -d "$installation_dir" ]; do
        if [ "$i" -gt 300 ]; then
            echo "Error: $installation_dir is not found"
            exit 1
        fi
        sleep 2
        i=i+1
    done
}

case "$1" in
  locate)
        echo $installation_dir
        ;;
  startserver)
        waitformedia
        $python_exec -m http.server 9999
        ;;
  run)
        waitformedia
        current_dir=$(pwd)
        cd $installation_dir
        $python_exec feed.py
        cd $current_dir
        ;;
  *)
        echo $"Usage: $0 {locate|startserver|run}"
        echo "    locate - returns location of the feed.py"
        echo "    startserver - starts python3 http.server at feed.py dir on port 9999"
        echo "    run - runs feed.py and downloads group updates"
        exit 1
esac