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




# FROM ubuntu:trusty
#
# WORKDIR /verenav
#
# RUN apt-get update && \
#     apt-get install -y git wget && \
#     apt-get autoclean && apt-get autoremove
#
# RUN apt-get install -y gcc make libpcre3 zlib1g libpcre3-dev zlib1g-dev logrotate
#
# RUN cd /verenav && \
#     wget http://luajit.org/download/LuaJIT-2.1.0-beta3.tar.gz && \
#     tar zxf LuaJIT-2.1.0-beta3.tar.gz && \
#     cd LuaJIT-2.1.0-beta3 && make && make install && \
#     cd ../ && rm -rf LuaJIT-2.1.0-beta3 && rm -f LuaJIT-2.1.0-beta3.tar.gz
#
# RUN cd /verenav && \
#     wget https://github.com/openresty/lua-nginx-module/archive/v0.10.13.tar.gz && \
#     tar zxf v0.10.13.tar.gz && \
#     rm -f v0.10.13.tar.gz && \
#     wget https://github.com/simplresty/ngx_devel_kit/archive/v0.3.0.tar.gz && \
#     tar zxf v0.3.0.tar.gz && \
#     rm -f v0.3.0.tar.gz
#
# RUN cd /verenav && \
#     wget http://nginx.org/download/nginx-1.13.6.tar.gz && \
#     tar zxf nginx-1.13.6.tar.gz && \
#     rm -f nginx-1.13.6.tar.gz
#
# #    git clone https://github.com/chobits/ngx_http_proxy_connect_module && \
# #    patch -p1 < ../ngx_http_proxy_connect_module/patch/proxy_connect_rewrite_1015.patch && \
#
#
# RUN cd /verenav/nginx-1.13.6 && \
# #    ./configure --add-module=/verenav/ngx_http_proxy_connect_module --add-module=/verenav/lua-nginx-module && \
#     export LUAJIT_LIB=/usr/local/lib && \
#     export LUAJIT_INC=/usr/local/include/luajit-2.1 && \
#     ./configure --prefix=/opt/nginx \
#         --with-ld-opt="-Wl,-rpath,/usr/local/lib" \
#         --add-module=/verenav/ngx_devel_kit-0.3.0 \
#         --add-module=/verenav/lua-nginx-module-0.10.13
#
# # RUN make && make install
