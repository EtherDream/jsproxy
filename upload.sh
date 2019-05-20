#!/usr/bin/env bash
# 功能：同步文件到所有节点，并重启服务

HOST=etherdream.com
NODE=(
  node-aliyun-hk-0
  node-aliyun-hk-1
  node-aliyun-sg
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