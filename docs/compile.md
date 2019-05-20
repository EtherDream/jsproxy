# 简介

默认的安装方式，是直接下载编译后的 nginx 程序。目前只提供 Linux x64 系统的文件，其他系统暂不支持，需要从源码编译。

此外，对于没有 root 权限的系统，也需通过源码编译，从而改变 nginx 的安装位置。（nginx 程序路径是在编译时通过 `--prefix` 参数指定的，安装后移动程序位置会导致某些链接库无法加载。如果有好的解决方案多指教~）


# 依赖

需要安装 make、gcc 等，参考 nginx 的编译。

无需安装 pcre、zlib、openssl 开发库，安装脚本会自动下载源码。


# 脚本

```bash
curl -O https://raw.githubusercontent.com/EtherDream/jsproxy/master/i.sh
bash i.sh compile
```

nginx 最终安装在 `$HOME/openresty` 目录下。代理服务安装在当前 `server` 目录下。


# 支持

目前测试过的系统：

* OSX