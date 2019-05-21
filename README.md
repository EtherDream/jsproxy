# 在线预览

https://zjcqoo.github.io/-----https://www.google.com

（目前仍在更新中，如有问题尝试用隐身模式访问）


# 最近更新

* 2019-05-21 首页静态资源从 CDN 加载

* 2019-05-20 安装脚本更新

* 2019-05-17 常用网站静态资源从 CDN 加载

[查看更多](changelogs)


# 安装

```bash
curl -O https://raw.githubusercontent.com/EtherDream/jsproxy/master/i.sh && bash i.sh
```

如果安装失败，尝试[源码编译安装](docs/compile.md)。


# 测试

可通过如下命令，验证代理是否生效：

```bash
curl http://服务器IP:8080/http \
  -H '--url: https://raw.githubusercontent.com/EtherDream/jsproxy/master/test/works.txt' \
  -H 'Origin: http://localhost'
```

正常情况下，显示 `ok`。如果无法连接，检查 8080/8443 端口是否添加到防火墙。

其他错误，可尝试查看错误日志：

```bash
cat /home/jsproxy/server/nginx/logs/error.log
```


# 维护

```sh
# 切换到 jsproxy 用户
su - jsproxy

# 重启服务
./run.sh reload

# 关闭服务（参数和 nginx -s 相同）
./run.sh quit

# 启动服务
./run.sh

# 查看代理日志
tail server/nginx/logs/proxy.log
```

目前暂未实现开机自启动。


# 部署

## 客户端

浏览器端项目位于：https://github.com/EtherDream/jsproxy-browser

准备一个域名（例如 `example.com`），参考备注，将其添加到线路地址。

> 注意：端口是 8443，不是 8080。因为 Service Worker 只有本地测试可用 HTTP 协议，其他场合必须 HTTPS。

编译脚本，将 `www` 目录发布到 Web 空间（例如 `https://myhost.github.io`）

（目前还不完善，之后将实现动态配置，无需修改 JS 代码）


## 服务端

解析 `example.com` 到自己的服务器。给该域名申请证书，保存到 `cert/example.com/` 目录下。（可参考 `gen-cert` 目录，使用脚本自动生成）

修改 `nginx.conf` 中域名相关的配置（默认被注释）。

在 `allowed-sites.conf` 中添加一行 Web 空间的地址，例如：

```
https://myhost.github.io     'my';
```

重启服务。访问 `https://myhost.github.io` 预览。


# 安全策略

如果不希望代理访问内网，可执行 `setup-ipset.sh` 避免 SSRF 风险：

```bash
/home/jsproxy/setup-ipset.sh
```

> 需要 root 权限，依赖 `ipset` 命令

该脚本可禁止 `jsporxy` 用户访问内网（针对 TCP）。nginx 之外的程序也生效，但不影响其他用户。


# 项目特点

相比传统在线代理，本项目具有以下特点：

## 服务端开销低

传统在线代理几乎都是在服务端替换 HTML/JS/CSS 等资源中的 URL。这不仅需要对内容做大量的分析和处理，还需对流量进行解压和再压缩，消耗大量 CPU 资源。并且由于逻辑较复杂，通常使用 Python/PHP 等编程语言自己实现。

为降低服务端开销，本项目使用浏览器的一个黑科技 —— Service Worker。它能让 JS 拦截网页产生的请求，并能自定义返回内容，相当于在浏览器内部实现一个反向代理。这使得绝大部分的内容处理都可以在浏览器上完成，服务器只需纯粹的转发流量。

因此本项目服务端直接使用 nginx，并且转发过程不修改内容（只修改 HTTP 头），避免了内容处理产生的巨大开销。同时得益于 nginx 丰富的功能，很多常用需求无需重新造轮子，通过简单配置即可实现。并且无论性能还是稳定性，都远高于自己实现。

## API 虚拟化

传统在线代理大多只针对静态 URL 的替换，忽视了动态 URL 以及和 URL 相关的网页 API。例如 a.com 反向代理 google.com，但页面中 JS 读取 `document.domain` 得到的仍是 a.com。这可能导致某些业务逻辑出现问题。

为缓解这个问题，本代理在页面头部注入一个 JS，用以重写绝大部分和 URL 相关的 API，使得页面中的 JS 获取到的仍是原始 URL：

![](https://raw.githubusercontent.com/EtherDream/jsproxy-localtest/temp/hook.png)

对于有些无法重写的 API，例如 `location`，本代理会将代码中字面出现的 `location` 替换成 `__location`，从而将操作转移到自定义对象上。当然对于非字面的情况（例如 `this['lo' + 'cation']`），目前还无法处理。


# 类似项目

目前找到的都是传统后端替换 URL 的方案。当然后端替换也有不少优点，例如浏览器兼容性高，甚至低版本的 IE 都可以使用。

## zmirror

GitHub: https://github.com/aploium/zmirror

## php-proxy

GitHub: https://github.com/jenssegers/php-proxy


# 项目意义

本项目主要用于以下技术的研究：

* 网站镜像 / 沙盒化

* 钓鱼网站检测技术

* 前端资源访问加速

当然请勿将本项目用于非法用途，否则后果自负。

Demo 页面文明使用，不要进行登陆等涉及隐私的操作。


# License

MIT