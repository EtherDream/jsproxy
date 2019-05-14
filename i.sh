#!/usr/bin/env sh

CDN=https://cdn.jsdelivr.net/gh/etherdream/jsproxy-bin@master/dist/
DST=/home/jsproxy/setup.sh


groupadd nobody
useradd jsproxy -g nobody --create-home

curl -s "$CDN/setup.sh" -o $DST
chmod +x $DST

su - jsproxy -c $DST