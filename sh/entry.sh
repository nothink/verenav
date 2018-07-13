#!/bin/sh

# run crond
/usr/sbin/crond -b

# run openresty
/usr/local/openresty/bin/openresty -g "daemon off;"
