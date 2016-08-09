#!/bin/sh
# Satellite-install post-install script - to finalize the configuration
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


# load scripts
source $(dirname `realpath $BASH_SOURCE`)/../0-bootstrap.sh

info "perform firewall steps from install doc to secure the foreman ports"
firewall-cmd --direct --add-rule ipv4 filter OUTPUT 0 -o lo -p tcp -m tcp --dport 9200 -m owner --uid-owner foreman -j ACCEPT \
&& firewall-cmd --direct --add-rule ipv6 filter OUTPUT 0 -o lo -p tcp -m tcp --dport 9200 -m owner --uid-owner foreman -j ACCEPT \
&& firewall-cmd --direct --add-rule ipv4 filter OUTPUT 0 -o lo -p tcp -m tcp --dport 9200 -m owner --uid-owner root -j ACCEPT \
&& firewall-cmd --direct --add-rule ipv6 filter OUTPUT 0 -o lo -p tcp -m tcp --dport 9200 -m owner --uid-owner root -j ACCEPT \
&& firewall-cmd --direct --add-rule ipv4 filter OUTPUT 1 -o lo -p tcp -m tcp --dport 9200 -j DROP \
&& firewall-cmd --direct --add-rule ipv6 filter OUTPUT 1 -o lo -p tcp -m tcp --dport 9200 -j DROP \
&& firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 0 -o lo -p tcp -m tcp --dport 9200 -m owner --uid-owner foreman -j ACCEPT \
&& firewall-cmd --permanent --direct --add-rule ipv6 filter OUTPUT 0 -o lo -p tcp -m tcp --dport 9200 -m owner --uid-owner foreman -j ACCEPT \
&& firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 0 -o lo -p tcp -m tcp --dport 9200 -m owner --uid-owner root -j ACCEPT \
&& firewall-cmd --permanent --direct --add-rule ipv6 filter OUTPUT 0 -o lo -p tcp -m tcp --dport 9200 -m owner --uid-owner root -j ACCEPT \
&& firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 1 -o lo -p tcp -m tcp --dport 9200 -j DROP \
&& firewall-cmd --permanent --direct --add-rule ipv6 filter OUTPUT 1 -o lo -p tcp -m tcp --dport 9200 -j DROP

SOURCES=$(ls /etc/pulp/content/sources/conf.d/*.conf 2>/dev/null)
if [ -n "$SOURCES" ] ; then
  cat<<EOF
It looks like you have alternative sources.
Let's ask pulp to initialize that.

You can watch the progress in another window by:

  $H# journalctl SYSLOG_IDENTIFIER=pulp -f --since='1 minutes ago'$h

EOF
  pulp-admin  -u admin -p $(grep ^default_pass /etc/pulp/server.conf | cut -d ' ' -f 2) content sources refresh --bg
fi
