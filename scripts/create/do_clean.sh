#!/bin/sh
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

