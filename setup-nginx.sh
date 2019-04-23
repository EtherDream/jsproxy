# 
curl -O https://openresty.org/download/openresty-1.15.8.1rc1.tar.gz
tar zxvf openresty-*
cd openresty-*

./configure \
	--with-http_v2_module \
	--with-http_ssl_module \
	--with-pcre-jit \
	--prefix=/home/jsproxy/openresty

make
make install

cd ..
rm -rf openresty-*