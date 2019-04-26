HOST=etherdream.com
NODE=(
  node-aliyun-hk
  node-aliyun-sg
  node-bwh-los
)
for v in ${NODE[@]}; do
  echo "$v upload ..."

  rsync . jsproxy@$v.$HOST:server \
    -r \
    --exclude='nginx/cache/*' \
    --exclude='nginx/logs/*'

  echo "$v restart ..."

  ssh jsproxy@$v.$HOST "./server/run.sh reload"
done

echo "done"