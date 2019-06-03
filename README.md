# 演示

https://jsproxy.tk/-----https://www.google.com

（目前仍在更新中，如有问题尝试用隐身模式访问）


# 更新

* 2019-05-30 更新 cfworker，对 ytb 视频进行了优化（推荐选 1080p+，不会增加服务器压力）

* 2019-05-29 nginx 增加静态资源服务，可同时支持代理接口和首页访问

* 2019-05-27 增加 nio.io、sslip.io 后备域名，减少申请失败的几率

* 2019-05-26 安装时自动申请证书（使用 xip.io 域名），安装后即可预览

[查看更多](changelogs)


# 安装

```bash
curl https://raw.githubusercontent.com/EtherDream/jsproxy/master/i.sh | bash
```

* 自动安装目前只支持 Linux x64，并且需要 root 权限

* 安装过程中 80 端口能被外网访问（申请 HTTPS 证书）

无法满足上述条件，或想了解安装细节，可尝试[手动安装](docs/setup.md)。

测试: `https://服务器IP.xip.io:8443`（具体参考脚本输出）


# 部署

Fork 本项目，进入 `gh-pages` 分支，编辑 `conf.js` 文件：

* 节点列表（`node_map` 字段，包括节点 id 和节点主机）

* 默认节点（`node_default` 字段，指定节点 id）

访问 `https://用户名.github.io/jsproxy` 预览。

GitHub 支持[自定义域名](https://help.github.com/en/articles/using-a-custom-domain-with-github-pages)。也可以将文件发布到自己的 Web 服务器上。


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
