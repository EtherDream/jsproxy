# 流量配额限制
DEV=eth0

# 上行流量 2TB
TX_MAX=$((2 * 1024 ** 4))

TX_USED=$(ifconfig $DEV | grep "TX packets" | awk '{ print $5 }')
# TX_USED=$(iptables -nvxL OUTPUT | grep "Chain OUTPUT" | awk '{ print $7 }')

TX_FREE=$(($TX_MAX - $TX_USED))
TX_RATE=$((100 * $TX_USED / $TX_MAX))

printf "tx used: %'d ($TX_RATE%%)\n" $TX_USED
printf "tx free: %'d\n" $TX_FREE


if [[ ! $(iptables -L | grep "tx quota") ]]; then
  iptables \
    -m comment --comment "tx quota" \
    -A OUTPUT \
    -m set ! --match-set ngx-ban-dstip dst \
    -m quota ! --quota $TX_FREE \
    -j DROP
fi