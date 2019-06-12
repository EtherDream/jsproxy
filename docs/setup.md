# 手动安装

## 创建用户

新建一个名为 `jsproxy` 用户（`nobody` 组），并切换：

```bash
groupadd nobody
useradd jsproxy -g nobody --create-home

su - jsproxy
```

非 Linux 系统，或者无 root 权限的设备，可忽略。

> 为什么要创建用户？因为使用低权限运行服务可减少风险。另外在防 SSRF 脚本 `setup-ipset.sh` 中，是通过 iptalbes 的 `uid-owner` 策略阻止 `jsprxoy` 这个特定用户访问内网的。


## 安装 nginx

本项目使用 [OpenResty](https://openresty.org/en/)。编译前需确保 make、gcc 等工具存在。

```bash
cd $(mktemp -d)

curl -O https://www.openssl.org/source/openssl-1.1.1b.tar.gz
tar zxf openssl-*

curl -O https://ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz
tar zxf pcre-*

curl -O https://zlib.net/zlib-1.2.11.tar.gz
tar zxf zlib-*

curl -O https://openresty.org/download/openresty-1.15.8.1.tar.gz
tar zxf openresty-*
cd openresty-*

export PATH=$PATH:/sbin

./configure \
  --with-openssl=../openssl-1.1.1b \
  --with-pcre=../pcre-8.43 \
  --with-zlib=../zlib-1.2.11 \
  --with-http_v2_module \
  --with-http_ssl_module \
  --with-pcre-jit \
  --prefix=$HOME/openresty

make
make install
```

其中 `configure` 的参数 `--prefix` 指定 nginx 安装路径，这里为方便设为用户主目录。

> 注意编译后的 nginx 程序不能改变位置，否则会启动失败

测试能否执行：

```bash
~/openresty/nginx/sbin/nginx -h
```


## 安装代理程序

下载本项目，其本质就是一堆 nginx 配置。推荐放在 `jsproxy` 用户的主目录：

```bash
cd ~
git clone --depth=1 https://github.com/EtherDream/jsproxy.git server
```

下载静态资源文件到 `www` 目录：

```bash
cd server
rm -rf www
git clone -b gh-pages --depth=1 https://github.com/EtherDream/jsproxy.git www
```

开启服务：

```bash
./run.sh
```

更新使用 git 即可。


## 申请域名

* 免费申请：https://www.freenom.com

* 临时测试：`服务器IP.xip.io`

类似的还有 `nip.io`、`sslip.io`，自动安装脚本默认使用 `xip.io`。


## 申请证书

可通过 Let's Encrypt 申请免费的 HTTPS 证书。

* [手动申请](cert-manual.md)

* [自动申请](cert-auto.md)

也可以不申请证书，使用免费的 HTTPS 反向代理，例如 [CloudFlare](https://www.cloudflare.com/)：

```text
[浏览器] --- https ---> [CloudFlare] --- http ---> [服务器]
```

这种方案不仅能节省系统资源，还能减少流量开销（静态资源可被 CloudFlare 缓存）。当然延时可能较高，并且安全性略低。

> 为什么一定要用 HTTPS？因为本项目使用了浏览器 Service Worker 技术，该 API 只能在安全环境使用，除了 localhost、127.0.0.0/8 站点可以使用 HTTP，其他必须 HTTPS。


## 支持系统

目前测试了 OSX 系统，其他还在测试中。。。
