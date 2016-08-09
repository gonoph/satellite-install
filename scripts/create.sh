#!/bin/sh
# Satellite-install create provisioning script - to aid in the provisioning of kickstart hosts
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
_BASE=$(dirname `realpath $BASH_SOURCE`)
source $_BASE/create-funcs.sh

set -e  -E

do_help() {
  info "Usage: \e[1m$0 (ks | pxeless | template)"
  info "Current Default Host: $H$HOST"
  info "$H  ks       $h- create PXE kickstart VM"
  info "$H  pxeless  $h- create PXEless discovery VM with ISO ($H$PXELESS_ISO$h)"
  info "$H  template $h- create unregistered system from RHEL template ($H$RHEL_TEMPLATE$h)"
  info "$H  clean    $h- clean the current host from satellite and RHEVM"
  exit 1
}
case $1 in
  clean) 
    source $_BASE/create/do_clean.sh
    do_action
    exit 0 ;;
  ks)
    source $_BASE/create/do_ks.sh
    do_action
    exit 0 ;;
  pxeless)
    source $_BASE/create/do_pxeless.sh
    do_action
    exit 0 ;;
  template)
    source $_BASE/create/template.sh
    do_action
    exit 0 ;;
  *)
    do_help ;;
esac

# vim: sw=2 ai
