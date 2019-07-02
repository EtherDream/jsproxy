#!/usr/bin/env bash
# 功能：同步文件到所有节点，并重启服务

HOST=etherdream.com
NODE=(
  aliyun-hk-0
  # aliyun-hk-1
  aliyun-hk-2
  aliyun-hk-3
  aliyun-hk-4
  aliyun-sg
)
for v in ${NODE[@]}; do
  echo "$v upload ..."

  rsync . jsproxy@$v.$HOST:server \
    -a \
    --exclude='nginx/cache/*' \
    --exclude='nginx/logs/*'

  echo "$v restart ..."

  ssh jsproxy@$v.$HOST "./server/run.sh reload"
done

echo "done"
