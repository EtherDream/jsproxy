#!/usr/bin/env bash
# 功能：备份 nginx 日志到 backup 目录

SVC_DIR=/home/jsproxy/server
LOG_DIR=$SVC_DIR/nginx/logs
DST_DIR=$SVC_DIR/log-svc/backup

LOG_FILE=$LOG_DIR/proxy.log
LOG_SIZE=$(( 256 * 1024 * 1024 ))

ERR_FILE=$LOG_DIR/error.log
ERR_SIZE=$(( 256 * 1024 * 1024 ))


# error.log 达到 ERR_SIZE，开始备份（目前只清理）
errsize=$(stat --printf=%s $ERR_FILE)
if (( $errsize >= $ERR_SIZE )); then
  echo > $ERR_FILE
fi

# proxy.log 达到 LOG_SIZE，开始备份
logsize=$(stat --printf=%s $LOG_FILE)
if (( $logsize < $LOG_SIZE )); then
  exit
fi

logtime=$(date "+%Y-%m-%d-%H-%M-%S")

#
# 先移走日志文件，然后创建新的日志文件，通知 nginx 重新打开
#
mv $LOG_FILE $DST_DIR/$logtime.log
touch $LOG_FILE
$SVC_DIR/run.sh reopen
sleep 1

#
# 日志压缩
# 根据实际情况调整策略，在不影响系统的前提下，充分利用剩余 CPU
#
echo "compress ..."

nice -n 19 xz $DST_DIR/*.log

echo "done"