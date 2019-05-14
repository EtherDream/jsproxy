#!/usr/bin/env bash
# 功能：定时调用 backup.sh

echo "log svc running"
CUR_DIR=$(cd `dirname $0` && pwd)

# 也可用 crontab
while true
do
  $CUR_DIR/backup.sh
  sleep 60
done