#!/bin/sh

# generate error.log
mkdir /verenav
touch /verenav/error.log && chown nobody:nobody /verenav/error.log

# add crontab
mv /crontab /var/spool/cron/crontabs/root

# run crond
/usr/sbin/crond -b

# run openresty
/opt/nginx/sbin/nginx -g "daemon off;"
