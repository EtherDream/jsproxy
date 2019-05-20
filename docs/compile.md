源码编译安装

默认的安装脚本是直接下载已编译的 nginx 程序，目前只提供 Linux x64 系统，其他系统暂未提供，需要从源码编译。

此外，对于没有 root 权限的 Linux 系统，也可通过源码编译，将 nginx 安装在任意位置。（nginx 的程序路径是在编译时指定的，移动文件会导致无法启动，所以只能重新编译）


# 安装依赖

 CentOS

```sh
yum install -y make clang
```