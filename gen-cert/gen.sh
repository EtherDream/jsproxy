ACME=~/.acme.sh/acme.sh

source ./dnsconf

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
	--key-file ../../server/cert/$DOMAIN/rsa.key \
	--fullchain-file ../../server/cert/$DOMAIN/rsa.cer

$ACME \
	--install-cert -d *.$DOMAIN --ecc \
	--key-file ../../server/cert/$DOMAIN/ecc.key \
	--fullchain-file ../../server/cert/$DOMAIN/ecc.cer

echo "
ssl_certificate       cert/$DOMAIN/rsa.cer;
ssl_certificate_key   cert/$DOMAIN/rsa.key;
ssl_certificate       cert/$DOMAIN/ecc.cer;
ssl_certificate_key   cert/$DOMAIN/ecc.key;
" > ../../server/cert/$DOMAIN/ngx.conf
