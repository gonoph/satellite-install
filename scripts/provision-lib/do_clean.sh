#!/bin/sh
# Satellite-install clean up provisioning script - to aid in the provisioning of kickstart hosts
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
# vim: sw=2 ai

do_action() {
  info "Cleaning up run for $HOST"
  hammer --csv host list --search name=${HOST} | tail -n +2 | cut -d , -f 1,2 | tr ',' ' ' > /tmp/x
  cat /tmp/x | while read HID H ; do
    info "Deleting $H with --id=$HID"
    cmd "hammer host delete --id=$HID"
  done
  [ -s /tmp/x ] || info "Didn't find any satellite hosts named $HOST"

  local VMS_ID=$(ovirt /vms/?search=name=$NAME | grep vm.href.*id= | sed 's/^.*id="\(.*\)".*$/\1/' )
  for id in $VMS_ID ; do
    info "Deleting $HOST with id=$id"
    info "Stopping host"
    cat<< EOF > /tmp/x
<action><async>false</async></action>
EOF
    local STATE=$( ovirt /vms/$VMS_ID/stop -H 'Content-type: application/xml' -d @/tmp/x | grep state | shtml | tr -d ' ' | grep complete )
    check_blank STATE
    warn "STATE=$STATE"
    info "Deleting host"
    local I=10
    set +e
    while [ $I -gt 0 ] ; do
      ovirt /vms/$VMS_ID -X DELETE | grep state | shtml | tr -d ' ' | grep complete > /tmp/xx
      [ -s /tmp/xx ] && break
      I=$[ $I - 1 ]
      grep detail /tmp/l
      sleep 5
      info "$(date)"
    done
    STATE=$(cat /tmp/xx ; rm -f /tmp/xx)
    check_blank STATE
    warn "STATE=$STATE"
  done
  [ -z "$VMS_ID" ] && info "Didn't find any RHEVM VMs named $NAME"
  exit 0
}

