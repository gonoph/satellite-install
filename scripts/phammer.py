#!/usr/bin/env python2.7
# Satellite-install python version of hammer script - not finshed version of the hammer script in python
# Copyright (C) 2016  Billy Holmes <billy@gonoph.net>
# 
# This file is part of Satellite-install.
# 
# Satellite-install is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
# 
# Satellite-install is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
# 
# You should have received a copy of the GNU General Public License along with
# Satellite-install.  If not, see <http://www.gnu.org/licenses/>.


from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
import requests
import socket
import json
import sys
import logging

def getLogger():
  logger = logging.getLogger(__name__)
  logger.setLevel(logging.INFO)
  ch = logging.StreamHandler()
  ch.setLevel(logging.DEBUG)
  formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
  ch.setFormatter(formatter)
  logger.addHandler(ch)
  return logger

log = getLogger()

class NotImplemented(Exception):
    def __init__(self, methodName):
	Exception.__init__(self, 'Method Not Implemented: ' + methodName)

class Section(object):
    def do(self, args):
	raise NotImplemented('section')

class Manifest(Section):
    def __init__(self, parser):
	p = parser.add_parser('manifest', help='Import the subscription manifest')
	p.add_argument('manifest_zip', metavar='manifest.zip', help='the subscription manifest to import', default='manifest.zip', type=file)
	p.add_argument('--force', help='Force the import by deleting the old manifest', action='store_true')
	p.set_defaults(section=self)
    def do(self, args):
	if not '.'.join(args.manifest_zip.name[::-1].split('.')[0:1:])[::-1]=='zip':
	    log.error('Manifest file does not end in zip, Satellite will be angry: %s', args.manifest_zip.name)
	    raise Exception("Manifest Extension is not zip")
	if not args.manifest_zip.read(2) == 'PK':
	    log.error('Manifest file does not appear to be a zip file: %s', args.manifest_zip.name)
	    raise Exception("Manifest is not a zip file!")

	myAuth=requests.auth.HTTPBasicAuth(args.user, args.password)
	s = requests.Session()
	args.manifest_zip.seek(0)
	# r = s.post('https://'+args.satellite+'/katello/api/organizations/1/subscriptions/delete_manifest', auth=myAuth, stream=False, headers={'Content-type': 'application/json'})
	#print(r.text)
	r = s.post('https://'+args.satellite+'/katello/api/organizations/1/subscriptions/upload', files={'content': args.manifest_zip}, auth=myAuth, stream=False)
	print(r.text)
	r = s.get('https://'+args.satellite+'/katello/api/organizations/1/subscriptions', auth=myAuth, stream=False)
	print(r.text)

class Repos(Section):
    def __init__(self, parser):
	p = parser.add_parser('repos', help='Create the initial repos')
	p.add_argument('--extras', help='Include extras and tools', action='store_true', default=True)
	p.add_argument('--satellite', help='Include satellite repos', action='store_true')
	p.set_defaults(section=self)

class SatelliteInit(object):
    def __init__(self):
        p = ArgumentParser(description='Initialize Satellite 6.2.', formatter_class=ArgumentDefaultsHelpFormatter)
	p.add_argument('-u', '--user', help='Satellite admin user', default='admin')
	p.add_argument('-p', '--password', help='Satellite admin password', default='redhat123')
	p.add_argument('-s', '--satellite', help='hostname of Satellite server', default=socket.gethostname())
	p.add_argument('-o', '--organization-id', help='the organzation-id to use', default=1, type=int)
	p.add_argument('-l', '--location-id', help='the location-id to use', default=2, type=int)
	p.add_argument('--beta', help='Set Beta mode!', action='store_true')
	s = p.add_subparsers(title='Sections', description='Section to invoke as part of the initialization')
	Manifest(s)
	Repos(s)
	self.parser = p
    def args(self):
	return self.parser.parse_args()

init = SatelliteInit()
args = init.args()
args.section.do(args)
