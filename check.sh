CF_HOSTS=(
  shrill-unit-8594.jsproxy.workers.dev
  a.007.workers.dev
  a.hehe.workers.dev
  a.lulu.workers.dev
)

while true; do
  for v in ${CF_HOSTS[@]}; do
    if [[ $(curl -s https://$v/works) != "it works" ]]; then
      echo "https://$v err"
    else
      echo "https://$v ok"
    fi
  done

  sleep 5
  clear
done