#!/usr/bin/env bash

CDN=https://cdn.jsdelivr.net/gh/etherdream/jsproxy-bin@master

JSPROXY_VER=0.0.9
PCRE_VER=8.43
ZLIB_VER=1.2.11
OPENSSL_VER=1.1.1b
OPENRESTY_VER=1.15.8.1

SUPPORTED_OS="Linux-x86_64"
OS="$(uname)-$(uname -m)"

NGX_DIR="$HOME/openresty"

COLOR_RESET="\033[0m"
COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"

output() {
  color=$1
  shift 1
  sdata="$@"
  stime=$(date "+%H:%M:%S")
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

check_nginx() {
  NGX_EXE="$NGX_DIR/nginx/sbin/nginx"
  NGX_VER=$($NGX_EXE -v 2>&1)

  if [[ "$NGX_VER" != *"nginx version:"* ]]; then
    err "$NGX_EXE 无法执行！尝试编译安装"
    exit 1
  fi
  log "$NGX_VER"
  log "nginx path: $NGX_DIR"
}

install_jsproxy() {
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

compile() {
  TMP_DIR="$PWD/__tmp__"

  mkdir -p $TMP_DIR
  cd $TMP_DIR

  log "下载 pcre 源码 ..."
  curl -O https://ftp.pcre.org/pub/pcre/pcre-$PCRE_VER.tar.gz
  tar zxf pcre-$PCRE_VER.tar.gz

  log "下载 zlib 源码 ..."
  curl -O https://zlib.net/zlib-$ZLIB_VER.tar.gz
  tar zxf zlib-$ZLIB_VER.tar.gz

  log "下载 openssl 源码 ..."
  curl -O https://www.openssl.org/source/openssl-$OPENSSL_VER.tar.gz
  tar zxf openssl-$OPENSSL_VER.tar.gz

  log "下载 nginx 源码 ..."
  curl -O https://openresty.org/download/openresty-$OPENRESTY_VER.tar.gz
  tar zxf openresty-$OPENRESTY_VER.tar.gz

  cd openresty-$OPENRESTY_VER

  export PATH=$PATH:/sbin

  log "配置中 ..."
  ./configure \
    --with-openssl=../openssl-$OPENSSL_VER \
    --with-pcre=../pcre-$PCRE_VER \
    --with-zlib=../zlib-$ZLIB_VER \
    --with-http_v2_module \
    --with-http_ssl_module \
    --with-pcre-jit \
    --prefix=$NGX_DIR

  log "编译中 ..."
  make
  make install

  log "编译完成"
  rm -rf $TMP_DIR

  check_nginx
  install_jsproxy
}

install() {
  log "下载 nginx 程序 ..."
  curl -O $CDN/$OS/openresty-$OPENRESTY_VER.tar.gz
  tar zxf openresty-$OPENRESTY_VER.tar.gz
  rm -f openresty-$OPENRESTY_VER.tar.gz

  check_nginx
  install_jsproxy
}

update() {
  install_jsproxy
}

pack() {
  log "压缩 openresty ..."
  GZIP=-9
  tar cvzf openresty.tar.gz openresty
  log "done"
  ls -la
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

  src=$0
  dst=/home/jsproxy/i.sh
  warn "当前脚本移动到 $dst"

  mv -f $src $dst
  chmod +x $dst

  log "切换到 jsproxy 用户，执行安装脚本 ..."
  su - jsproxy -c "$dst install"
}


case "$1" in
"install") install
  exit;;
"compile") compile
  exit;;
"update") update
  exit;;
"pack") pack
  exit;;
*) main
  exit;;
esac