#!/bin/bash
# Satellite-install install script
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

set -e 

# load scripts
source $(dirname `realpath $0`)/../0-bootstrap.sh

: ${SAT_USER:=admin}
: ${SAT_PASS:=redhat123}
: ${LOCATION:=Home}
: ${ORGANIZATION:=Test62}

# this is the 6.2+ form of the install command

#    --foreman-proxy-tftp true \
#    --foreman-proxy-puppetca true \
#    --enable-foreman-plugin-discovery \
#    --enable-foreman-plugin-remote-execution \
#    --enable-foreman-proxy-plugin-remote-execution-ssh
  satellite-installer --scenario satellite -v --force \
    --foreman-initial-location $LOCATION \
    --foreman-initial-organization $ORGANIZATION \
    --foreman-admin-username $SAT_USER \
    --foreman-admin-password $SAT_PASS \
    --foreman-proxy-tftp true \
    --foreman-plugin-discovery-install-images true \
    --capsule-puppet true \
    --foreman-proxy-puppetca true \
    --enable-foreman-plugin-discovery
