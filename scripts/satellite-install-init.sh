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
rm ssl-build/ -rfv
sync

yum erase candlepin  foreman puppet httpd foreman-proxy -y
rm /etc/candlepin/ /var/lib/foreman /var/lib/puppet -rfv /etc/httpd /etc/puppet /etc/foreman /etc/foreman-proxy
sync
