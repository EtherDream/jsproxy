HTTPS 证书申请脚本

# 依赖

安装 acme.sh：

```bash
curl https://get.acme.sh | sh
```

# 生成

在当前目录下新建 `dnsconf` 文件，格式为：

```text
DOMAIN=example.com
DNS_ID=dns_xx
export xx_id=xxx
export xx_key=xxxxxx
```

第一个为域名，后面三个参考 https://github.com/Neilpang/acme.sh/wiki/dnsapi

例如 CloudFlare 的 DNS 服务：

```text
DOMAIN=etherdream.com
DNS_ID=dns_cf
export CF_Key="123456789012345678901234567890"
export CF_Email="user@gmail.com"
```

> API Keys 可在 https://dash.cloudflare.com/ 查看。

执行 `./gen.sh` 开始申请，证书文件保存到 `~/server/cert/域名` 目录下。

重启服务生效：

```bash
~/server/run.sh reload
```