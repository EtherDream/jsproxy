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
  # echo "$v upload ..."
  # rsync . jsproxy@$v.$HOST:server \
  #   -a \
  #   --exclude='nginx/cache/*' \
  #   --exclude='nginx/logs/*'


  # echo "$v reload nginx ..."
  # ssh jsproxy@$v.$HOST "./server/run.sh reload"


  echo "$v kill log-svc.sh"
  ssh jsproxy@$v.$HOST "kill $(ps aux | grep svc.sh | head -n1 | awk '{print $2}')"


  # echo "$v run log-svc.sh"
  # ssh jsproxy@$v.$HOST "./server/log-svc/svc.sh &"


  # echo "$v update www"
  # ssh jsproxy@$v.$HOST "cd server/www && git pull"
done

echo "done"
