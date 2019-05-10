#!/usr/bin/env bash
# 功能：同步文件到所有节点，并重启服务

HOST=etherdream.com
NODE=(
  node-aliyun-hk
  node-aliyun-sg
  node-bwh-los
  node-justhost-moscow
  node-bungee
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