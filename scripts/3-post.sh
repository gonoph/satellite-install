#!/bin/sh

# this is from the install doc to secure the foreman ports
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

  # journalctl SYSLOG_IDENTIFIER=pulp -f --since='1 minutes ago'

EOF
  pulp-admin  -u admin -p $(grep ^default_pass /etc/pulp/server.conf | cut -d ' ' -f 2) content sources refresh --bg
fi
