#!/bin/bash

# CF 证书配置
echo "请输入CF域名";
read domain;
echo "请输入CF信箱";
read mail;
echo "请输入CF 密钥";
read token;

curl https://get.acme.sh | sh

cat > ./gen-cert/dnsconf <<EOF
DOMAIN=$domain
DNS_ID=dns_cf 
export CF_Key="$token"
export CF_Email="$mail"
EOF
cd ./gen-cert
bash gen.sh
cd ..
# 替换域名
sed -i "s/example.com/$domain/g" nginx.conf
# 添加服务器到白名单
echo "https://$domain    '$domaine';" >> allowed-sites.conf
echo "生成完毕 请使用Docker进行后续工作"