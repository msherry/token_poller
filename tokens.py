#!/usr/bin/env python

from datetime import datetime
import pygeoip
import re
import redis
import sys

TIME_FMT = '%Y-%m-%dT%H:%M:%S.%f'

r = redis.StrictRedis(host='localhost', port=6379, db=0)
geoip = pygeoip.GeoIP('/usr/share/GeoIP/GeoLiteCity.dat')


def main(namespace):
    buckets = {}
    longest_key_len = 0

    redis_keys = r.keys('{}:*'.format(namespace))
    for redis_key in redis_keys:
        key = redis_key.replace('{}:'.format(namespace), '')
        bucket = r.hgetall(redis_key)
        buckets[key] = bucket

        if len(key) > longest_key_len:
            longest_key_len = len(key)

    total_spacing = (8 + longest_key_len) / 8 * 8

    now = datetime.utcnow()
    for key, bucket in buckets.iteritems():
        if not bucket:
            # Might have expired while we were polling
            buckets.pop(key)
        updated_at = datetime.strptime(bucket['updated_at'],
                                       TIME_FMT)

        now_toks = (float(bucket['tokens']) +
                    (now - updated_at).seconds * float(bucket['fill_rate']))
        bucket['now_toks'] = now_toks

        country = None

        if re.match(r'[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+',
                    key):
            record = geoip.record_by_addr(key) or {}
            country = record.get('country_name', 'UNKNOWN')
        bucket['country'] = country

    for key, bucket in sorted(buckets.iteritems(),
                              key=lambda x: x[1]['now_toks'], reverse=True):
        nt = '%.04f' % bucket['now_toks']
        country = bucket['country']

        num_tabs = 1 + (total_spacing - len(key) - 1) / 8
        tabs = num_tabs * '\t'
        print '{}{}{}\t{}'.format(key, tabs, nt, country if country else '')


if __name__ == '__main__':
    namespace = 'token_buckets'
    if len(sys.argv) > 1 and sys.argv[1] == 'cards':
        namespace = 'card_token_buckets'
    main(namespace)
