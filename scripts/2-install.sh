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


: ${BETA:=}
: ${SAT_USER:=admin}
: ${SAT_PASS:=redhat123}
: ${LOCATION:=Home}
: ${ORGANIZATION:=Test62}

[ -n "$BETA" ] && echo -e "\e[1;31mBETA Mode on\e[0m"  || echo -e "\e[1;34mBETA MODE off\e[0m"
# this is the beta form of the install command

  foreman-installer --scenario katello \
    --foreman-admin-username $SAT_USER \
    --foreman-admin-password $SAT_PASS \
    --capsule-puppet true \
    --foreman-proxy-puppetca true \
    --foreman-proxy-tftp true \
    --enable-foreman-plugin-discovery \
    --foreman-initial-location $LOCATION \
    --foreman-initial-organization $ORGANIZATION
