#!/usr/bin/env bash

echo "关闭 jsproxy 程序 ..."
killall -u jsproxy

echo "关闭 ssrf 防护 ..."
line=$(iptables -L --line-numbers | grep jsproxy)
if [[ $line ]]; then
  iptables -D OUTPUT ${line%% *}
fi

ipset destroy ngx-ban-dstip

echo "删除 jsproxy 用户 ..."
userdel -r jsproxy

# 如果安装脚本中途退出，iptables 可能会有残留
line=$(iptables -t nat -L --line-numbers | grep "jsproxy acme redir")
if [[ $line ]]; then
  iptables -t nat -D PREROUTING ${line%% *}
fi
