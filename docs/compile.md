# 手动安装

## 创建用户

新建一个名为 `jsproxy` 用户（`nobody` 组），并切换：

```bash
groupadd nobody
useradd jsproxy -g nobody --create-home

su - jsproxy
```

非 Linux 系统，或者无 root 权限的设备，可忽略。

> 为什么要创建用户？因为本服务无需 root，所以使用低权限减少风险。另外在防 SSRF 脚本 `setup-ipset.sh` 中，是通过 iptalbes 的 `uid-owner` 策略阻止 `jsprxoy` 这个特定用户访问内网的。


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
$HOME/openresty/nginx/sbin/nginx -h
```


## 安装代理程序

下载本项目。其本质就是一堆 nginx 配置：

```bash
git clone --depth=1 https://github.com/EtherDream/jsproxy.git server
```

开启代理服务：

```bash
cd server
./run.sh
```

更新使用 git 即可。


## 支持系统

目前测试了 OSX 系统，其他还在测试中。。。