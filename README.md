
# 更新

* 2019-07-24 [v0.1.0](https://github.com/EtherDream/jsproxy/blob/master/changelogs/v0.1.0.md) 发布，主要修复了缓存失效的问题。网络接口和之前版本不兼容，请及时更新服务端和 cfworker。

* 2019-06-22 [cfworker 无服务器版](cf-worker) 发布，长期使用演示服务的请使用该版本。

[查看更多](changelogs)


# 安装

```bash
curl https://raw.githubusercontent.com/EtherDream/jsproxy/0.1.0/i.sh | bash
```

* 自动安装目前只支持 Linux x64，并且需要 root 权限

* 安装过程中 80 端口能被外网访问（申请 HTTPS 证书）

无法满足上述条件，或想了解安装细节，可尝试[手动安装](docs/setup.md)。

测试: `https://服务器IP.xip.io:8443`（具体参考脚本输出）


### 自定义域名

将域名 `example.com` 解析到服务器 IP，然后执行：

```bash
curl https://raw.githubusercontent.com/EtherDream/jsproxy/master/i.sh | bash -s example.com
```

访问: `https://example.com:8443`


### 自定义端口

默认端口为 8443 (HTTPS) 和 8080 (HTTP) ，如需改成 443 和 80，推荐使用端口转发：

```bash
iptables -A PREROUTING -t nat -p tcp --dport 443 -j REDIRECT --to-ports 8443
iptables -A PREROUTING -t nat -p tcp --dport 80 -j REDIRECT --to-ports 8080
```

同时修改 `www.conf` 中的 `:8443` 为 `:443`。


### 使用 GitHub Pages 前端

本项目支持前后端分离，前端部分（`www` 目录下的文件）可部署在第三方 Web 服务器上。

例如演示站点的前端部署于 GitHub Pages 服务，从而可使用个性域名（*.github.io），还能减少一定的流量开销。

Fork 本项目，进入 `gh-pages` 分支（该分支内容和 `www` 目录相同），编辑 `conf.js` 文件：

* 节点列表（`node_map` 字段，包括节点 id 和节点主机）

* 默认节点（`node_default` 字段，指定节点 id）

访问 `https://用户名.github.io/jsproxy` 预览。


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


# 禁止外链

默认情况下，代理接口允许所有 `github.io` 子站点调用，这可能导致不必要的流量消耗。

如果希望只给自己网站使用，可编辑 `allowed-sites.conf`。（重启服务生效）


# 安全策略

如果不希望代理访问内网（避免 SSRF 风险），可执行 `setup-ipset.sh`：

```bash
/home/jsproxy/server/setup-ipset.sh
```

> 需要 root 权限，依赖 `ipset` 命令

该脚本可禁止 `jsporxy` 用户访问保留 IP 段（针对 TCP）。nginx 之外的程序也生效，但不影响其他用户。


# 相关文章

* [基于 JS Hook 技术，打造最先进的在线代理](https://github.com/EtherDream/jsproxy/blob/master/docs/blogs/js-hook.md)


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
