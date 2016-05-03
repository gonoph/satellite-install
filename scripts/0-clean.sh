#!/bin/sh

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

yum autoremove katello -y
rm /etc/candlepin/ /var/lib/foreman /var/lib/puppet -rfv /etc/httpd /etc/puppet /etc/foreman /etc/foreman-proxy
sync
