# 手动申请 HTTPS 证书

在线申请：https://www.sslforfree.com


## 方案 1 —- 通过 80 端口验证

前提条件：公网 IP 能访问 80 端口，设备需要 root 权限

1.输入 `服务器IP.xip.io`

2.`Manual Verification` -> `Manually Verify Domain` -> `Download File`

3.文件保存到服务器 `~/server/acme/.well-known/acme-challenge/` 目录

4.转发 80 端口到 8080 端口（需要 root 权限）

```bash
iptables -t nat -I PREROUTING 1 -p tcp --dport 80 -j REDIRECT --to-ports 
```

当然也可以使用其他 Web 服务，只要该文件能被外部访问就可以。

5.测试链接能否访问（Verify successful upload by visiting the following links in your browser）

6.Download SSL Certificate

7.保存证书

`Certificate` 保存到 `~/server/cert/xip.io/cert`

`Private Key` 保存到 `~/server/cert/xip.io/key`

编辑文件 `~/server/cert/cert.conf`

```conf
listen                8443 ssl http2;
ssl_certificate       cert/xip.io/cert;
ssl_certificate_key   cert/xip.io/key;
```

重启服务：`~/server/run.sh reload`

8.验证

访问 `https://服务器IP.xip.io:8443/`，没出现证书错误即成功。

9.关闭 80 端口转发

```bash
iptables -t nat -D PREROUTING 1
```


## 方案 2 —- 通过 DNS 验证

前提条件：拥有域名控制权（`xip.io` 不支持）

1.输入域名

2.Manual Verification (DNS) -> Manually Verify Domain

3.根据提示，创建一个 TXT 记录

4.Download SSL Certificate

5.保存证书（和上述相同）