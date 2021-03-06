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

# make sure if there is an error, we abort
set -e 

# load scripts
source $(dirname `realpath $$BASH_SOURCE`)/../0-bootstrap.sh

# set the release
set_release

# only set the repos we need and perform any updates
disable_repos
enable_repos rhel-7-server-rpms rhel-7-server-rh-common-rpms

info "Updating system"
yum update -y

info "add in the satellite repos"
if [ -n "$BETA" ] ; then
  enable_repos rhel-7-server-rpms rhel-7-server-rh-common-rpms rhel-server-rhscl-7-rpms rhel-server-7-satellite-6-beta-rpms
else
  enable_repos rhel-7-server-rpms rhel-7-server-rh-common-rpms rhel-server-rhscl-7-rpms rhel-7-server-satellite-6.2-rpms
fi

info "setup the time"
yum erase -y ntp ntpdate
yum install chrony -y
systemctl enable chronyd
systemctl start chronyd

info "open up the firewall"
firewall-cmd --add-port="53/udp" --add-port="53/tcp" \
 --add-port="67/udp" --add-port="68/udp" \
 --add-port="69/udp" --add-port="80/tcp" \
 --add-port="443/tcp" --add-port="5647/tcp" \
 --add-port="8140/tcp" --add-port="9090/tcp"
firewall-cmd --permanent --add-port="53/udp" --add-port="53/tcp" \
 --add-port="67/udp" --add-port="68/udp" \
 --add-port="69/udp" --add-port="80/tcp" \
 --add-port="443/tcp" --add-port="5647/tcp" \
 --add-port="8140/tcp" --add-port="9090/tcp"

info "actually install katello / satellite"
yum -y install \
	satellite \
	bind-utils \
	pulp-admin-client \
	pulp-rpm-admin-extensions \
       	pulp-rpm-handlers

info "make sure the permissions are set in case we mounted special directories"
restorecon -Rv /var
