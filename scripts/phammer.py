#!/usr/bin/env python2.7

import requests,socket,time,json

url='https://%s' % socket.gethostname()
myAuth=requests.auth.HTTPBasicAuth('admin', 'redhat123')

s = requests.Session()
# s = requests

def get(r):
    if r.status_code != 200:
	raise Exception('Status Code: %d' % r.status_code)

    try:
	o = r.json()
    except Exception:
	o = r.text
    return o

def api(url, session, _auth):
    return session.get(url, auth=_auth, stream=False)

#for x in range(1,10):
if True:
    resp = api('%s/%s' % (url, '/katello/api/organizations'), s, myAuth)
    o = get(resp)
    for r in o['results']:
    	print '%d:%s' % (r['id'], r['name'])

    resp = api('%s/%s' % (url, '/api/v2/locations'), s, myAuth)
    o = get(resp)
    for r in o['results']:
	print '%d:%s' % (r['id'], r['name'])

    resp = api('%s/%s' % (url, '/api/v2/location'), s, myAuth)
    o = get(resp)
    for r in o['results']:
	print '%d:%s' % (r['id'], r['name'])
