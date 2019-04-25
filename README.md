# 在线预览

https://zjcqoo.github.io/-----https://www.google.com

（目前仍在更新中，最好使用隐身模式访问，避免缓存导致的问题）

[之前版本](https://github.com/EtherDream/jsproxy/tree/first-ver)已不再更新，但[演示服务](https://jsproxy.tk/)仍保留一段时间。


# 安装

新建一个名为 `jsproxy` 用户，在其主目录安装 nginx：

```bash
useradd jsproxy -g nobody
su jsproxy

cd ~
git clone --depth=1 https://github.com/EtherDream/jsproxy.git server

cd server
./setup-nginx.sh
```

安装过程若有依赖缺失，可尝试（CentOS 为例）：

```bash
yum install -y \
	gcc gcc-c++ \
	pcre pcre-devel \
	openssl openssl-devel \
	zlib zlib-devel
```

## 测试

启动服务：

```bash
~/server/run.sh
```

访问：https://etherdream.github.io/jsproxy-localtest/-----https://github.com/

![](https://raw.githubusercontent.com/EtherDream/jsproxy-localtest/temp/preview.png)

注意，**当前项目只提供接口服务**，浏览器端脚本和页面不在本项目。这样做是为了让接口和界面分离，意义参见后续。


# 部署

参考 `gen-cert` 目录，为自己的域名申请证书。（不申请证书也可以，例如通过 CloudFlare）

修改 `nginx.conf` 中域名相关的配置（默认被注释），以及 DNS 地址（默认是 114.114.114.114）。

浏览器端项目位于：https://github.com/EtherDream/jsproxy-browser

参考备注，修改线路服务器地址，之后将 www 目录发布到 Web 空间即可。

在 `allowed-sites.txt` 中添加 Web 空间的地址，重启服务生效。该文件授权哪些网站可以调用该接口，防止被滥用。

（目前还不完善，之后将实现动态配置，无需修改 JS 代码）


# 安全策略

如果不希望代理访问内网，可执行 `setup-ipset.sh`，避免 SSRF 风险。

该脚本可禁止 `jsporxy` 用户访问内网（针对 TCP）。nginx 之外的程序也生效，但不影响其他用户。


# 服务管理

重启服务：`./run.sh reload`

关闭服务：`./run.sh quit`

参数和 nginx -s 相同。


# CHANGELOG

## v0.0.1

虽然目前仍为概念演示状态，但相比[最初版本](https://github.com/EtherDream/jsproxy/tree/first-ver)，有了很大变化：

### 不再使用子域名

使用子域名编码目标域名（例如 gg.jsproxy.tk），存在太多缺陷。例如 HTTPS 证书问题，DNS 性能和安全问题等。因此目前不再使用子域名，只用固定的域名，目标 URL 放在路径里。例如：

https://zjcqoo.github.io/-----https://www.google.com

当然这也会产生很多新问题，例如无法支持 Cookie、页面之间没有同源策略限制等。

对于 Cookie，目前通过 JS 来维护，而不用浏览器原生（当然还有不少细节没实现）。这样的好处是前后端可以分离，前端页面可以放在第三方 Web 服务器上（例如 CDN、GitHub Pages），我们的服务器只提供代理接口。

这样一个页面可使用多个服务器的代理接口，并能实现线路切换、负载均衡等效果。

同源策略方面的限制目前暂未实现，因此不要进行登陆等操作，避免隐私泄露。


### 服务端优化

安全改进：由于 Web 页面托管在第三方站点上，自己的服务器无需开启 443 端口，因此也无需 root 运行。同时支持 IP 黑名单功能，防止 SSRF 攻击。

代码改进：接口代理使用固定的 URL（参见 `api.conf`），不再使用任意路径，代码干净了很多。


## 支持更多浏览器

相比之前版本只支持 Chrome，现在还支持最新的 Safari 和 FireFox。

注意：FireFox 隐身模式下不支持 Service Worker，只能普通模式访问。


### 提供一个首页

虽然依旧简陋，但比之前好。提供了线路切换、预加载的功能。

# License

MIT