#!/usr/bin/env bash
# 功能：备份 nginx 日志到 backup 目录

SVC_DIR=/home/jsproxy/server
LOG_DIR=$SVC_DIR/nginx/logs

LOG_FILE=$LOG_DIR/proxy.log
LOG_SIZE=$(( 32 * 1024 * 1024 ))

ERR_FILE=$LOG_DIR/error.log
ERR_SIZE=$(( 1 * 1024 * 1024 * 1024 ))


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
logfile=$SVC_DIR/log-svc/backup/$logtime.log

#
# 先移走日志文件，然后创建新的日志文件，通知 nginx 重新打开
#
mv $LOG_FILE $logfile
touch $LOG_FILE
$SVC_DIR/run.sh reopen
sleep 1

#
# 日志压缩
# 根据实际情况调整策略，在不影响系统的前提下，充分利用剩余 CPU
# 可尝试其他工具（例如 7z），在开销和效果之间找一个平衡点
#
echo "compress $logtime ($logsize bytes)"

nice -n 19 \
  gzip $logfile

echo "done"