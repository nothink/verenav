FROM openresty/openresty:alpine

# create cache dir
RUN mkdir /var/cache/nginx && \
    mkdir /var/cache/nginx/tmp && \
    mkdir /verenav

# install lua, lzlib, logrotate,
RUN apk --update --no-cache add lua lua-lzlib logrotate procps bc jq python py-pip && \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir awscli

# copy setting files
COPY nginx/conf.d/* /etc/nginx/conf.d/
COPY nginx/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY logrotate/* /etc/logrotate.d/
# copy the entry script
COPY sh/* /
RUN chmod 755 /entry.sh /upload.sh
# expose ports
EXPOSE 21494

VOLUME /root/.aws
VOLUME /verenav
WORKDIR /verenav

# move crontab for root user
RUN mv /crontab  /var/spool/cron/crontabs/root

CMD ["/entry.sh"]

# FROM ubuntu:cosmic
#
# WORKDIR /verenav
#
# RUN apt-get update && \
#     apt-get install -y git wget && \
#     apt-get autoclean && apt-get autoremove
#
# RUN apt-get install -y gcc make libpcre3 zlib1g libpcre3-dev zlib1g-dev lua5.1 lua5.1-dev lua-zlib logrotate
#
# RUN cd /verenav && \
#     wget http://nginx.org/download/nginx-1.15.2.tar.gz && \
#     tar zxf nginx-1.15.2.tar.gz && \
#     git clone https://github.com/chobits/ngx_http_proxy_connect_module && \
#     git clone https://github.com/openresty/lua-nginx-module && \
#     cd /verenav/nginx-1.15.2 && \
#     patch -p1 < ../ngx_http_proxy_connect_module/patch/proxy_connect_rewrite_1015.patch && \
#     ./configure --add-module=/verenav/ngx_http_proxy_connect_module --add-module=/verenav/lua-nginx-module && \
#     make && make install
