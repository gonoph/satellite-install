#!/bin/sh
# vim: sw=2 ai

BASEURL=
BETA=
# load scripts
source $(dirname `realpath $BASH_SOURCE`)/../0-bootstrap.sh

: ${HOST:=client1.test.gonoph.net}
NAME=$(cut -d . -f 1 <<< "$HOST")
: ${HG:=RHEL7-Server}
MAC=
: ${IP:=$(host $HOST | sed -n 's/.*has address //p')}
[ -z "$IP" ] && { echo "$HOST does not have an ip address!" ; exit 1 ; }
: ${ORG:=1}
: ${LOC:=2}

: ${RHEVM_USER:=admin@internal}
: ${RHEVM_PASS:=redhat123}
: ${RHEVM_CLUSTER:=AMD-Cheap}
: ${RHEVM_STORAGE:=ZFS-data}
: ${RHEVM_INTERFACE:=rhevm}

: ${PXELESS_ISO:=auto-foreman-discovery-image.iso}
: ${RHEL_TEMPLATE:=rhel-demo}

PW="$RHEVM_USER:$RHEVM_PASS"
: ${URL:=https://rhevm/ovirt-engine/api}

: ${NEW_HOST_ROOT:=redhat123}

ovirt() {
  add_url="$1"
  shift
  rm -f /tmp/l
  curl -s --basic -k -u ${PW} -H "filter: true" ${URL}${add_url} "$@" | tee /tmp/l
  rm -f /tmp/x
}

ovirt_err() {
  echo -e "\e[0;31mERROR: \e[0;35m""$@""\e[0m"
  warn "--[ LOG ] --"
  cat /tmp/l
  warn "--[ END ] --"
  exit 1
}

check_blank() {
  local K=$1
  eval V='$'"$1"
  test -n "$V" || ovirt_err "\e[1m$K \e[22mis blank, which means something went wrong."
}

cmd() {
  info "Running:\e[1m" "$@"
  eval "$@" > /tmp/ll
  ret=$?
  info "$(cat /tmp/ll)"
  [ $ret -eq 0 ] || warn "Command didn't complete"
}

shtml() {
	sed 's%<[[:alnum:]/]*>%%g' | tr -s ' '
}

warn "HOST=$HOST"
warn "NAME=$NAME"
warn "IP=$IP"
warn "HG=$HG"
warn "ORG=$ORG"
warn "LOC=$LOC"
warn "NEW_HOST_ROOT=$NEW_HOST_ROOT"
warn "PXELESS_ISO=$PXELESS_ISO"
warn "RHEL_TEMPLATE=$RHEL_TEMPLATE"
warn "RHEVM_USER=$RHEVM_USER"
warn "RHEVM_INTERFACE=$RHEVM_INTERFACE"
warn "RHEVM_CLUSTER=$RHEVM_CLUSTER"
warn "RHEVM_STORAGE=$RHEVM_STORAGE"
