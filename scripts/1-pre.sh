#!/bin/sh

: ${BETA:=}

[ -n "$BETA" ] && echo -e "\e[1;31mBETA Mode on\e[0m"  || echo -e "\e[1;34mBETA MODE off\e[0m"
# make sure if there is an error, we abort
set -e 

# set the release
subscription-manager release --set=7Server

# only set the repos we need and perform any updates
subscription-manager repos --disable "*"
subscription-manager repos --enable rhel-7-server-rpms --enable rhel-7-server-rh-common-rpms
yum update -y

# add in the satellite repos
if [ -n "$BETA" ] ; then
  subscription-manager repos --enable rhel-server-rhscl-7-rpms --enable rhel-server-7-satellite-6-beta-rpms
else
  subscription-manager repos --enable rhel-server-rhscl-7-rpms --enable rhel-server-7-satellite-6.1-rpms
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
yum -y install katello

# make sure the permissions are set in case we mounted special directories
restorecon -Rv /var
