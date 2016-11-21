#copy this file to /etc/cron.daily/
d=$(pwd)
i=0
loc="/media/a8510270-6ecd-4eba-8482-b16ee4af414a/NikiKiri"

while [ ! -d "$loc" ]; do
    if [ "$i" -gt 300 ]; then
        echo "Error: $loc is not found"
        exit 1
    fi
    sleep 2
    i=i+1
done

cd $loc 
python3.4 feed.py
cd $d

exit 0