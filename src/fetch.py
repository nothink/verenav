import boto3
import requests
import os
import sys
from datetime import datetime

dump_root = '/home/shared/verenav/'
pid_path = '/var/tmp/fetch_fumio.pid'

user_agent = 'Mozilla/5.0 '
'(iPhone; CPU iPhone OS 12_0 like Mac OS X) '
'AppleWebKit/605.1.15 (KHTML, like Gecko) '
'Version/12.0 Mobile/15E148 Safari/604.1'


def main():

    s3 = boto3.resource('s3', endpoint_url='https://s3.wasabisys.com')
    humi = s3.Bucket('humi-bookmark')

    # check PID file
    if os.path.isfile(pid_path):
        sys.stdout.write('PID file exists. exit.\n')
        sys.stdout.flush()
        return
    else:
        with open(pid_path, 'w') as f:
            f.write(str(os.getpid()))

    try:
        session = requests.Session()
        session.headers.update(
            {'User-Agent': user_agent}
        )

        for summary in humi.objects.all():
            obj = s3.Object('humi-bookmark', summary.key)
            keys = obj.get()['Body'].read().decode('utf-8').splitlines()
            for key in keys:
                if 'mypage.build' in key:
                    continue
                elif 'text_nyuudankouka.png' in key:
                    continue
                # temporary fix
                key = key.replace('//', '/')
                key = key.split('?')[0]
                key = key.split('&')[0]
                # end temporary fix
                fpath = os.path.join(dump_root + key)
                if not os.path.isfile(fpath):
                    r = session.get('https://' + key)
                    if r.status_code == requests.codes.ok:
                        os.makedirs(os.path.dirname(fpath), exist_ok=True)
                        with open(fpath, 'wb') as f:
                            f.write(r.content)
                        tstr = datetime.now().strftime("[%Y/%m/%d %H:%M:%S] ")
                        sys.stdout.write(tstr + key + '\n')
                        sys.stdout.flush()
                    else:
                        sys.stdout.write("[FAILED] " + key + '\n')
                        sys.stdout.flush()
            obj.delete()
            sys.stdout.write("[remove] " + summary.key + '\n')
            sys.stdout.flush()
    finally:
        # remove PID file
        os.unlink(pid_path)


if __name__ == '__main__':
    main()
