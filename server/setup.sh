# nodejs
curl -sL https://rpm.nodesource.com/setup_10.x | sudo bash -

yum install -y \
	gcc gcc-c++ clang \
	zlib zlib-devel unzip \
	git bc sed tree \
	make autoconf automake libtool \
	nodejs

npm i -g webpack webpack-cli
npm i -g html-minifier


# install openresty
mkdir -p install
cd install

curl -O https://ftp.pcre.org/pub/pcre/pcre-8.42.zip
unzip pcre-*

curl -O https://www.openssl.org/source/openssl-1.0.2p.tar.gz
tar zxvf openssl-*

git clone --recurse-submodules --depth 1 https://github.com/google/ngx_brotli.git

curl -O https://openresty.org/download/openresty-1.13.6.2.tar.gz
tar zxvf openresty-*
cd openresty-*

export NGX_BROTLI_STATIC_MODULE_ONLY=1
./configure \
	--add-module=../ngx_brotli \
	--with-http_ssl_module \
	--with-openssl=../openssl-1.0.2p \
	--with-pcre=../pcre-8.42 \
	--with-pcre-jit

make
make install


# install brotli
# https://www.howtoforge.com/how-to-compile-brotli-from-source-on-centos-7/
git clone --depth 1 https://github.com/google/brotli.git
cd ./brotli
cp docs/brotli.1 /usr/share/man/man1 && gzip /usr/share/man/man1/brotli.1
./bootstrap
./configure --prefix=/usr \
            --bindir=/usr/bin \
            --sbindir=/usr/sbin \
            --libexecdir=/usr/lib64/brotli \
            --libdir=/usr/lib64/brotli \
            --datarootdir=/usr/share \
            --mandir=/usr/share/man/man1 \
            --docdir=/usr/share/doc
make
make install


# install acme.sh
curl https://get.acme.sh | sh
