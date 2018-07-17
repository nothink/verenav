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
