FROM centos:latest

# 安装依赖
RUN yum install -y \
	gcc gcc-c++ \
	pcre pcre-devel \
	openssl openssl-devel \
	zlib zlib-devel git corntabs

# 添加用户
RUN useradd jsproxy -g nobody && su jsproxy

# 添加文件夹
ADD . /home/jsproxy/server

# 安装服务器
RUN bash /home/jsproxy/server/setup-nginx.sh

EXPOSE 8080 8443

# 启动服务
CMD ["/home/jsproxy/openresty/nginx/sbin/nginx","-c","/home/jsproxy/server/nginx.conf","-p","/home/jsproxy/server/nginx","-g","daemon off;"]