#!/usr/bin/env bash

CDN=https://cdn.jsdelivr.net/gh/etherdream/jsproxy-bin@master

JSPROXY_VER=dev
OPENRESTY_VER=1.15.8.1

SUPPORTED_OS="Linux-x86_64"
OS="$(uname)-$(uname -m)"
USER=`whoami`

COLOR_RESET="\033[0m"
COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"

output() {
  local color=$1
  shift 1
  local sdata=$@
  local stime=$(date "+%H:%M:%S")
  printf "$color[jsproxy $stime]$COLOR_RESET $sdata\n"
}
log() {
  output $COLOR_GREEN $1
}
warn() {
  output $COLOR_YELLOW $1
}
err() {
  output $COLOR_RED $1
}

gen_cert() {
  log "准备申请 HTTPS 证书，使用 服务器IP.xip.io 域名"

  local ip_api="https://api.ipify.org"
  log "正在获取服务器公网 IP，通过接口: $ip_api"

  local ip=$(curl -s $ip_api)
  log "服务器公网 IP: $ip"

  log "安装 acme.sh 脚本 ..."
  curl https://raw.githubusercontent.com/Neilpang/acme.sh/master/acme.sh | INSTALLONLINE=1  sh

  local acme=~/.acme.sh/acme.sh
  local domain=$ip.xip.io

  local dist=server/cert/$domain
  mkdir -p $dist

  log "执行 acme.sh 脚本 ..."
  $acme \
    --issue \
    -d $domain \
    --keylength ec-256 \
    --webroot server/acme

  $acme \
    --install-cert \
    -d $domain \
    --ecc \
    --key-file $dist/ecc.key \
    --fullchain-file $dist/ecc.cer

  echo "
listen                8443 ssl http2;
ssl_certificate       cert/$domain/ecc.cer;
ssl_certificate_key   cert/$domain/ecc.key;
" > server/cert/cert.conf

  log "证书申请完成，重启服务 ..."
  server/run.sh reload

  log "在线预览: https://zjcqoo.github.io/#test=$ip"
}


install() {
  cd /home/jsproxy

  log "下载 nginx 程序 ..."
  curl -O $CDN/$OS/openresty-$OPENRESTY_VER.tar.gz
  tar zxf openresty-$OPENRESTY_VER.tar.gz
  rm -f openresty-$OPENRESTY_VER.tar.gz

  local ngx_exe=openresty/nginx/sbin/nginx
  local ngx_ver=$($ngx_exe -v 2>&1)

  if [[ "$ngx_ver" != *"nginx version:"* ]]; then
    err "$ngx_exe 无法执行！尝试编译安装"
    exit 1
  fi
  log "$ngx_ver"
  log "nginx path: $NGX_DIR"

  log "下载代理服务 ..."
  curl -o jsproxy.tar.gz https://codeload.github.com/EtherDream/jsproxy/tar.gz/$JSPROXY_VER
  tar zxf jsproxy.tar.gz
  rm -f jsproxy.tar.gz

  if [ -x server/run.sh ]; then
    warn "尝试停止当前服务 ..."
    server/run.sh quit
  fi

  if [ -d server ]; then
    backup="$PWD/bak/$(date +%Y_%m_%d_%H_%M_%S)"
    warn "当前 server 目录备份到 $backup"
    mkdir -p $backup
    mv server $backup
  fi

  mv jsproxy-$JSPROXY_VER server

  log "启动服务 ..."
  server/run.sh

  log "服务已开启"
  gen_cert
}

main() {
  log "自动安装脚本开始执行"

  if [[ "$SUPPORTED_OS" != *"$OS"* ]]; then
    err "当前系统 $OS 不支持自动安装。尝试编译安装"
    exit 1
  fi

  if [[ "$USER" != "root" ]]; then
    err "自动安装需要 root 权限。如果无法使用 root，尝试编译安装"
    exit 1
  fi

  if ! id -u jsproxy > /dev/null 2>&1 ; then
    log "创建用户 jsproxy ..."
    groupadd nobody > /dev/null 2>&1
    useradd jsproxy -g nobody --create-home
  fi

  warn "HTTPS 证书申请需要验证 80 端口，确保 TCP:80 已添加到防火墙"
  warn "如果当前已有 80 端口的服务，将暂时无法收到数据"
  iptables \
    -m comment --comment "acme challenge svc" \
    -t nat \
    -I PREROUTING 1 \
    -p tcp --dport 80 \
    -j REDIRECT \
    --to-ports 10080

  local src=$0
  local dst=/home/jsproxy/i.sh
  warn "当前脚本移动到 $dst"

  mv -f $src $dst
  chmod +x $dst

  log "切换到 jsproxy 用户，执行安装脚本 ..."
  su - jsproxy -c "$dst install"

  local line=$(iptables -t nat -L --line-numbers | grep "acme challenge svc")
  iptables -t nat -D PREROUTING ${line%% *}

  log "安装完成。后续维护参考 https://github.com/EtherDream/jsproxy"
}


case $1 in
"install")
  install;;
"cert")
  gen_cert;;
*)
  main;;
esac