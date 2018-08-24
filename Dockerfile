FROM alpine:3.8

EXPOSE 21494
VOLUME /root/.aws
VOLUME /verenav
WORKDIR /verenav

# install lua, lzlib, logrotate, awscli, nginx
RUN apk --update --no-cache add \
        lua5.1-libs lua5.1-lzlib pcre zlib \
        build-base gcc make lua5.1-dev pcre-dev zlib-dev git \
        logrotate procps bc jq python py-pip && \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir awscli && \
    cd /tmp && \
    wget https://github.com/openresty/lua-nginx-module/archive/v0.10.13.tar.gz && \
    tar zxf v0.10.13.tar.gz && \
    rm -f v0.10.13.tar.gz && \
    cd /tmp && \
    wget https://github.com/simplresty/ngx_devel_kit/archive/v0.3.0.tar.gz && \
    tar zxf v0.3.0.tar.gz && \
    rm -f v0.3.0.tar.gz && \
    cd /tmp && \
    wget http://nginx.org/download/nginx-1.13.6.tar.gz && \
    tar zxf nginx-1.13.6.tar.gz && \
    rm -f nginx-1.13.6.tar.gz && \
    cd /tmp && \
    git clone https://github.com/chobits/ngx_http_proxy_connect_module && \
    cd /tmp/nginx-1.13.6 && \
    patch -p1 < ../ngx_http_proxy_connect_module/patch/proxy_connect_rewrite_1014.patch && \
    cd /tmp/nginx-1.13.6 && \
    export LUA_LIB=/usr/lib && \
    export LUA_INC=/usr/include && \
    ./configure --prefix=/opt/nginx \
        --with-ld-opt="-Wl,-rpath,/usr/lib" \
        --add-module=/tmp/ngx_http_proxy_connect_module \
        --add-module=/tmp/ngx_devel_kit-0.3.0 \
        --add-module=/tmp/lua-nginx-module-0.10.13 && \
    make && make install && \
    rm -r /tmp/* && \
    apk del --purge build-base gcc make lua5.1-dev pcre-dev zlib-dev git

# nginx
COPY nginx/nginx.conf /opt/nginx/conf/
COPY nginx/conf.d /opt/nginx/conf/conf.d
# logrotate
COPY logrotate/* /etc/logrotate.d/

# copy the entry script
COPY sh/* /
RUN chmod 755 /entry.sh /upload.sh

CMD ["/entry.sh"]
