#!/bin/sh

UA="Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1"
TMP='/tmpfile'
EXISTS_LIST='/verenav/files'
EXISTS_LIST_TMP='/tmp/files'
WORKDIR='/verenav/'
BUCKET='verenav'
ENDPOINT='https://s3.wasabisys.com'

PID=/var/tmp/upload.pid

# check PID file & create
if [ -f ${PID} ]; then
    : # echo "double check: " ${PID}
    exit
else
    echo $$ > ${PID}
fi
# remove tmp file if exists
if [ -f ${TMP} ]; then
    rm ${TMP}
fi
# generate files list if not exists
if [ ! -f ${EXISTS_LIST} ]; then
    : # echo '[init] generating file list...'
    aws s3api list-objects --bucket ${BUCKET} --endpoint-url=${ENDPOINT} | \
    jq ".Contents[].Key" | \
    sed "s/\"//g" | sed "/^\/verenav\/files$/d" > ${EXISTS_LIST}
fi

# ------------------------------------------------------------------------------
# stat100.log.*
stat100s=$(find ${WORKDIR} -name 'stat100.log.*')

if [ -n "${stat100s}" ]; then
    cat ${stat100s} | \
    grep -v '^$' | sort | uniq | \
    while read line || [ -n "${line}" ]
    do
        if grep ${line} ${EXISTS_LIST} >/dev/null; then
            : # echo '[stat100] skip: ' ${line}
        else
            : # echo '[stat100] dl  : ' ${line}
            wget -q -O ${TMP} -U "${UA}" ${line}
            if [ $? -eq 0 ]; then
                : # echo '[stat100] upload... '
                aws s3 cp ${TMP} s3://${BUCKET}/${line} --acl public-read --endpoint-url=${ENDPOINT}
                rm ${TMP}
            fi
        fi
    done
    rm ${stat100s}
fi
# ------------------------------------------------------------------------------
# vcard.log.*
vcards=$(find ${WORKDIR} -name 'vcard.log.*')

if [ -n "${vcards}" ]; then
    cat ${vcards} | \
    sed -e s/\\\\\\//\\//g | \
    grep -o -e 'c.stat100.ameba.jp/vcard/[-a-zA-Z0-9/._+]*\.[a-zA-Z0-9]\+\|stat100.ameba.jp/vcard/[-a-zA-Z0-9/._+]*.[a-z]*\.[a-zA-Z0-9]\+' | \
    grep -v '^$' | sort | uniq | \
    while read line || [ -n "${line}" ]
    do
        if grep ${line} ${EXISTS_LIST} >/dev/null; then
            : # echo '[vcard] skip: ' ${line}
        else
            : # echo '[vcard] dl  : ' ${line}
            wget -q -O ${TMP} --user-agent="${UA}" ${line}
            if [ $? -eq 0 ]; then
                : # echo '[vcard] upload... '
                aws s3 cp ${TMP} s3://${BUCKET}/${line} --acl public-read --endpoint-url=${ENDPOINT}
                rm ${TMP}
            fi
        fi
    done
    rm ${vcards}
fi
# ------------------------------------------------------------------------------
: # echo 'updating file list...'
aws s3api list-objects --bucket ${BUCKET} --endpoint-url=${ENDPOINT} | \
jq ".Contents[].Key" | \
sed "s/\"//g" | sed "/^\/verenav\/files$/d" > ${EXISTS_LIST_TMP}

diff ${EXISTS_LIST_TMP} ${EXISTS_LIST} > /dev/null 2>&1
if [ $? -eq 1 ]; then
    cp -f ${EXISTS_LIST_TMP} ${EXISTS_LIST}
    aws s3 cp ${EXISTS_LIST} s3://${BUCKET}/files --acl public-read --endpoint-url=${ENDPOINT}
fi

rm -f ${EXISTS_LIST_TMP}

# delete PID file
rm ${PID}

# send HUP to reboot nginx workers
[ ! -f /var/run/nginx.pid ] || kill -HUP `cat /usr/local/openresty/nginx/logs/nginx.pid`
