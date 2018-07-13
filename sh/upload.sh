#!/bin/sh

UA="Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1"
TMP='/tmpfile'
WORKDIR='/verenav/'
BUCKET='verenav'
ENDPOINT='https://s3.wasabisys.com'

PID=/var/tmp/upload.pid

# check PID file & create
if [ -f ${PID} ]; then
    echo "double check: " ${PID}
    exit
else
    echo $$ > ${PID}
fi

# remove tmp file if exists
if [ -e $TMP ]; then
    rm $TMP
fi

cd $WORKDIR

# stat100.log.*
for file in $(find ./ -name 'stat100.log.*')
do
    cat $file | while read line || [ -n "$line" ]
    do
        aws s3 ls s3://${BUCKET}/${line} --endpoint-url=${ENDPOINT}
        if [[ $? -eq 0 ]]; then
            : #echo 'skip: ' $line
        else
            : #echo ' dl: ' $line
            wget -q -O $TMP --user-agent="$UA" $line
            if [ $? -eq 0 ]; then
                aws s3 cp $TMP s3://${BUCKET}/${line} --acl public-read --endpoint-url=${ENDPOINT}
                rm $TMP
            fi
        fi
    done
    rm $file
done

cd $WORKDIR

# vcard.log.*
for file in $(find ./ -name 'vcard.log.*')
do
    cat $file | \
    grep -o -e 'c.stat100.ameba.jp/vcard/[-a-zA-Z0-9/._+]*\.[a-zA-Z0-9]\+\|stat100.ameba.jp/vcard/[-a-zA-Z0-9/._+]*.[a-z]*\.[a-zA-Z0-9]\+' | \
    sort | uniq | \
    while read line || [ -n "$line" ]
    do
        aws s3 ls s3://${BUCKET}/${line} --endpoint-url=${ENDPOINT}
        if [[ $? -eq 0 ]]; then
            : #echo 'skip: ' $line
        else
            : #echo ' dl: ' $line
            wget -q -O $TMP --user-agent="$UA" $line
            if [ $? -eq 0 ]; then
                aws s3 cp $TMP s3://${BUCKET}/${line} --acl public-read --endpoint-url=${ENDPOINT}
                rm $TMP
            fi
        fi
    done
    rm $file
done

# delete PID file
rm ${PID}

# reboot workers
[ ! -f /var/run/nginx.pid ] || kill -HUP `cat /usr/local/openresty/nginx/logs/nginx.pid`