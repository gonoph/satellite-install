#!/bin/sh

set -e 

subscription-manager list || subscription-manager register --activationkey=GONOPH-NET-SAT --org=7258761
subscription-manager release --set=7Server
subscription-manager repos --disable "*"
subscription-manager repos --enable rhel-7-server-rpms --enable rhel-7-server-rh-common-rpms
yum install -y screen git vim

git clone http://git/git/satellite-install.git
