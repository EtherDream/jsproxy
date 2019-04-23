NGX_BIN=/home/jsproxy/openresty/nginx/sbin/nginx

# local test
if [ ! -f $NGX_BIN ]; then
    NGX_BIN=/usr/local/openresty/nginx/sbin/nginx
fi

CUR_DIR=$(cd `dirname $0` && pwd)

if [ $1 ]; then
    PARAM="-s $1"
fi

$NGX_BIN -c $CUR_DIR/nginx.conf -p $CUR_DIR/nginx $PARAM
