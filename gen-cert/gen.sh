ACME=~/.acme.sh/acme.sh

source ./dnsconf

mkdir -p ../cert/$DOMAIN

# 使用 Service Worker 的基本是高版本浏览器和操作系统，
# 因此去除了 RSA，只用 ECC 算法。
$ACME \
  --issue \
  --dns $DNS_ID \
  -d *.$DOMAIN \
  --keylength ec-256

$ACME \
	--install-cert -d *.$DOMAIN --ecc \
	--key-file ../cert/$DOMAIN/ecc.key \
	--fullchain-file ../cert/$DOMAIN/ecc.cer
