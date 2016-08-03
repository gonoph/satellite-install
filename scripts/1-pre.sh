#!/bin/sh
# Satellite-install pre-install script
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


: ${BETA:=}
: ${BASEURL:=}

[ -n "$BETA" ] && echo -e "\e[1;31mBETA Mode on\e[0m"  || echo -e "\e[1;34mBETA MODE off\e[0m"
[ -n "$BASEURL" ] && echo -e "\e[1;31mBASEURL is set\e[0m"
# make sure if there is an error, we abort
set -e 

# set the release
subscription-manager release --set=7Server

# only set the repos we need and perform any updates
rm -f /etc/yum.repos.d/redhat-new.repo
echo -n "Disabling repos: "
subscription-manager repos --disable "*" > /tmp/l 2>&1
cat /tmp/l | wc -l
subscription-manager repos --enable rhel-7-server-rpms --enable rhel-7-server-rh-common-rpms

if [ -n "$BASEURL" ] ; then
  /usr/bin/cp -f /etc/yum.repos.d/redhat.repo /tmp/redhat-new.repo
  sed -i -e "s%https://cdn.redhat.com/content/%$BASEURL%" -e 's%-rpms]%-rpms-new]%' /tmp/redhat-new.repo
  yum clean all
  echo -n "Disabling repos: "
  subscription-manager repos --disable "*" > /tmp/l 2>&1
  cat /tmp/l | wc -l
  mv -f /tmp/redhat-new.repo /etc/yum.repos.d/redhat-new.repo
fi

yum update -y

# add in the satellite repos
rm -f /etc/yum.repos.d/redhat-new.repo
if [ -n "$BETA" ] ; then
  subscription-manager repos --enable rhel-7-server-rpms --enable rhel-7-server-rh-common-rpms --enable rhel-server-rhscl-7-rpms --enable rhel-server-7-satellite-6-beta-rpms
else
  subscription-manager repos --enable rhel-7-server-rpms --enable rhel-7-server-rh-common-rpms --enable rhel-server-rhscl-7-rpms --enable rhel-7-server-satellite-6.2-rpms
fi

if [ -n "$BASEURL" ] ; then
  /usr/bin/cp -f /etc/yum.repos.d/redhat.repo /tmp/redhat-new.repo
  sed -i -e "s%https://cdn.redhat.com/content/%$BASEURL%" -e 's%-rpms]%-rpms-new]%' /tmp/redhat-new.repo
  yum clean all
  echo -n "Disabling repos: "
  subscription-manager repos --disable "*" > /tmp/l 2>&1
  cat /tmp/l | wc -l
  mv -f /tmp/redhat-new.repo /etc/yum.repos.d/redhat-new.repo
fi

# setup the time
yum erase -y ntp ntpdate
yum install chrony -y
systemctl enable chronyd
systemctl start chronyd

# open up the firewall
firewall-cmd --add-port="53/udp" --add-port="53/tcp" \
 --add-port="67/udp" --add-port="68/udp" \
 --add-port="69/udp" --add-port="80/tcp" \
 --add-port="443/tcp" --add-port="5647/tcp" \
 --add-port="8140/tcp"
firewall-cmd --permanent --add-port="53/udp" --add-port="53/tcp" \
 --add-port="67/udp" --add-port="68/udp" \
 --add-port="69/udp" --add-port="80/tcp" \
 --add-port="443/tcp" --add-port="5647/tcp" \
 --add-port="8140/tcp"

# actually install katello / satellite
yum -y install \
	katello \
	bind-utils \
	foreman-discovery-image.noarch \
	rubygem-smart_proxy_discovery.noarch \
	rubygem-smart_proxy_discovery_image.noarch \
	tfm-rubygem-foreman_discovery.noarch \
	tfm-rubygem-hammer_cli_foreman_discovery.noarch \
	pulp-admin-client

# make sure the permissions are set in case we mounted special directories
restorecon -Rv /var
