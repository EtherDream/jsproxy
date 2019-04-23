ACME=~/.acme.sh/acme.sh

source ./dnsconf

mkdir -p ../cert/$DOMAIN

$ACME \
  --issue \
  --dns $DNS_ID \
  -d *.$DOMAIN

$ACME \
  --issue \
  --dns $DNS_ID \
  -d *.$DOMAIN \
  --keylength ec-256

$ACME \
	--install-cert -d *.$DOMAIN \
	--key-file ../cert/$DOMAIN/rsa.key \
	--fullchain-file ../cert/$DOMAIN/rsa.cer

$ACME \
	--install-cert -d *.$DOMAIN --ecc \
	--key-file ../cert/$DOMAIN/ecc.key \
	--fullchain-file ../cert/$DOMAIN/ecc.cer

echo "
ssl_certificate       cert/$DOMAIN/rsa.cer;
ssl_certificate_key   cert/$DOMAIN/rsa.key;
ssl_certificate       cert/$DOMAIN/ecc.cer;
ssl_certificate_key   cert/$DOMAIN/ecc.key;
" > ../cert/$DOMAIN/ngx.conf
