#!/usr/bin/env sh

DST=/home/jsproxy/setup.sh

groupadd nobody
useradd jsproxy -g nobody --create-home

echo "download main script ..."
curl -s "https://raw.githubusercontent.com/EtherDream/jsproxy-bin/master/setup.sh" -o $DST
chmod +x $DST

su - jsproxy -c $DST