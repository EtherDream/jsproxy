#
# 该脚本用于禁止 jsporxy 用户访问内网，防止 SSRF 攻击
# 需要 root 权限运行，依赖 ipset 命令
#
if [[ $(iptables -L | grep "anti ssrf") ]]; then
  exit
fi

ipset create ngx-ban-dstip hash:net

iptables \
  -m comment --comment "anti ssrf" \
  -A OUTPUT \
  -p tcp --syn \
  -m owner --uid-owner jsproxy \
  -m set --match-set ngx-ban-dstip dst \
  -j REJECT

# https://en.wikipedia.org/wiki/Reserved_IP_addresses
REV_NET=(
  0.0.0.0/8
  10.0.0.0/8
  100.64.0.0/10
  127.0.0.0/8
  169.254.0.0/16
  172.16.0.0/12
  192.0.0.0/24
  192.0.2.0/24
  192.88.99.0/24
  192.168.0.0/16
  198.18.0.0/15
  198.51.100.0/24
  203.0.113.0/24
  224.0.0.0/4
  240.0.0.0/4
  255.255.255.255/32
)

for v in ${REV_NET[@]}; do
  ipset add ngx-ban-dstip $v
done

# 可屏蔽更多的网段：
# ipset add ngx-ban-dstip xxx