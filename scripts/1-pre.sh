#!/bin/sh

set -e 

subscription-manager register --activationkey=GONOPH-NET-SAT --org=7258761
subscription-manager release --set=7Server
subscription-manager repos --disable "*"
subscription-manager repos --enable rhel-7-server-rpms --enable rhel-7-server-rh-common-rpms
yum update -y
subscription-manager repos --enable rhel-server-rhscl-7-rpms --enable rhel-7-server-satellite-6.1-rpms
yum erase -y ntp ntpdate
yum install chrony -y
systemctl enable chronyd
systemctl start chronyd
firewall-cmd --add-port="53/udp" --add-port="53/tcp" \
 --add-port="67/udp" --add-port="68/udp" \
 --add-port="69/udp" --add-port="80/tcp" \
 --add-port="443/tcp" --add-port="5647/tcp" \
 --add-port="8140/tcp" \
firewall-cmd --permanent --add-port="53/udp" --add-port="53/tcp" \
 --add-port="67/udp" --add-port="68/udp" \
 --add-port="69/udp" --add-port="80/tcp" \
 --add-port="443/tcp" --add-port="5647/tcp" \
 --add-port="8140/tcp"

yum -y install katello
