使用 CloudFlare Worker 免费部署


# 简介

`CloudFlare Worker` 是 CloudFlare 的边缘计算服务。开发者可通过 JavaScript 对 CDN 进行编程，从而能灵活处理 HTTP 请求。这使得很多任务可在 CDN 上完成，无需自己的服务器参与。


# 部署

首页：https://workers.cloudflare.com

注册，登陆，`Start building`，取一个子域名，`Create a Worker`。

复制 [index.js](https://raw.githubusercontent.com/EtherDream/jsproxy/master/cf-worker/index.js) 到左侧代码框，`Save and deploy`。如果正常，右侧应显示首页。

收藏地址框中的 `https://xxxx.子域名.workers.dev`，以后可直接访问。


# 计费

后退到 `overview` 页面可参看使用情况。免费版每天有 10 万次免费请求，对于个人通常足够。

如果不够用，可注册多个 Worker，在 `conf.js` 中配置多线路负载均衡。或者升级到 $5 的高级版本，每月可用 1000 万次请求（超出部分 $0.5/百万次请求）。

如果远不够用，建议和服务器组合使用。因为 cfworker 是按请求次数计费的，所以小文件更适合通过服务器代理，大文件走 cfworker 才合算。可参考下面的 `加速功能`。


# 修改配置

默认情况下，静态资源从 `https://zjcqoo.github.io` 反向代理，可通过代码中 `ASSET_URL` 配置，从而可使用自定义的 `conf.js` 配置。


# 加速功能

如果你已有服务器，也可通过 CloudFlare Worker 分担大文件的代理。

前端修改：`conf.js` 的 `cfworker` 节点 `lines` 配置。

后端修改：`lua/http-enc-res-hdr.lua` 的 [114-116 行](https://github.com/EtherDream/jsproxy/blob/master/lua/http-enc-res-hdr.lua#L114-L116) 注释打开，重启服务生效。

可在 [84行](https://github.com/EtherDream/jsproxy/blob/master/lua/http-enc-res-hdr.lua#L84) 处修改大于多少字节的静态资源走加速。

该功能目前还在实验中，有问题或者更好的思路可交流。

（推荐下行流量免费且不限速的服务器，可节省大量费用）


# 存在问题

* WebSocket 代理尚未实现

* 外链限制尚未实现

* 未充分测试，以后再完善