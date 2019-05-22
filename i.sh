#!/usr/bin/env bash

CDN=https://cdn.jsdelivr.net/gh/etherdream/jsproxy-bin@master

JSPROXY_VER=0.0.9
OPENRESTY_VER=1.15.8.1

SUPPORTED_OS="Linux-x86_64"
OS="$(uname)-$(uname -m)"

NGX_DIR="$HOME/openresty"

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

install() {
  log "下载 nginx 程序 ..."
  curl -O $CDN/$OS/openresty-$OPENRESTY_VER.tar.gz
  tar zxf openresty-$OPENRESTY_VER.tar.gz
  rm -f openresty-$OPENRESTY_VER.tar.gz

  local ngx_exe="$NGX_DIR/nginx/sbin/nginx"
  local ngx_ver=$($ngx_exe -v 2>&1)

  if [[ "$ngx_ver" != *"nginx version:"* ]]; then
    err "$ngx_exe 无法执行！尝试编译安装"
    exit 1
  fi
  log "$ngx_ver"
  log "nginx path: $NGX_DIR"

  log "下载代理服务 ..."
  curl -s -O $CDN/server-$JSPROXY_VER.tar.gz

  if [ -x ./server/run.sh ]; then
    warn "尝试停止当前服务 ..."
    ./server/run.sh quit
  fi

  if [ -d "server" ]; then
    backup="$PWD/bak/$(date +%Y_%m_%d_%H_%M_%S)"
    warn "当前 server 目录备份到 $backup"
    mkdir -p $backup
    mv server $backup
  fi

  tar zxf server-$JSPROXY_VER.tar.gz
  rm -f server-$JSPROXY_VER.tar.gz

  log "启动服务 ..."
  ./server/run.sh

  log "服务已开启。后续维护参考 https://github.com/EtherDream/jsproxy"
}

main() {
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

  local src=$0
  local dst=/home/jsproxy/i.sh
  warn "当前脚本移动到 $dst"

  mv -f $src $dst
  chmod +x $dst

  log "切换到 jsproxy 用户，执行安装脚本 ..."
  su - jsproxy -c "$dst install"
}


if [[ "$1" == "install" ]]; then
  install
else
  main
fi