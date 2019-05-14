NGX_BIN=$HOME/openresty/nginx/sbin/nginx
CUR_DIR=$(cd `dirname $0` && pwd)

if [ $1 ]; then
  PARAM="-s $1"
fi

$NGX_BIN -c $CUR_DIR/nginx.conf -p $CUR_DIR/nginx $PARAM
