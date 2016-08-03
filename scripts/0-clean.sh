#!/bin/sh
# Satellite-install clean script used to (hopefully) restore a system to a clean state.
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


read -p "This has not been fully tested, and there is no roll back, are you sure? (yes/NO) " JUNK
[ "x${JUNK,,}" = "xyes" ] || exit 1

katello-service stop
systemctl stop postgresql mongod qpidd httpd puppet
systemctl stop postgresql mongod qpidd httpd puppet
sync
find /etc/pki/katello -type f | xargs rm -fv
find /etc/pki/katello-certs-tools/ -type f
find /etc/pki/katello-certs-tools/ -type f | xargs rm -rf
rm /var/lib/pgsql/data/* -rf
postgresql-setup initdb
rm /var/lib/mongodb/* -rfv
rm /var/lib/qpidd/.qpidd/ /var/lib/qpidd/* -rfv
rm /root/ssl-build/ -rfv
sync

yum -y autoremove \
	katello \
	foreman-discovery-image.noarch \
	rubygem-smart_proxy_discovery.noarch \
	rubygem-smart_proxy_discovery_image.noarch \
	tfm-rubygem-foreman_discovery.noarch \
	tfm-rubygem-hammer_cli_foreman_discovery.noarch \
	httpd \
	foreman \
	pulp-admin-client
rm /etc/candlepin/ /var/lib/foreman /var/lib/puppet -rfv /etc/httpd /etc/puppet /etc/foreman /etc/foreman-proxy
sync
