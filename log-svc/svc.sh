#!/usr/bin/env bash
# 功能：定时调用 backup.sh

echo "log svc running"

# 也可用 crontab
while true
do
  ./backup.sh
  sleep 60
done