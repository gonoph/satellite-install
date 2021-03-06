#!/bin/sh
# Satellite-install atomic provisioning script - to aid in the provisioning of kickstart hosts
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
  info "Creating Atomic kickstart VM: $NAME"
  cat<< EOF >/tmp/x
  <vm><name>${NAME}</name><template><name>Blank</name></template><cluster><name>${RHEVM_CLUSTER}</name></cluster><memory>2147483648</memory><cpu><topology sockets="2" cores="1" threads="1"/><architecture>X86_64</architecture></cpu><display><type>VNC</type></display><os type="rhel_7x64"><boot dev="hd"/><boot dev="network"/></os><type>server</type></vm>
EOF
  local VMS_ID=$(ovirt /vms -H "Content-type: application/xml" -d @/tmp/x | grep vm.href | grep id= | sed 's/^.* id="\(.*\)".*$/\1/')
  check_blank VMS_ID
  warn "VMS_ID=$VMS_ID"

  info "Creating disk: disk1 for vms=$VMS_ID"
  cat<< EOF >/tmp/x
  <disk><provisioned_size>10737418240</provisioned_size><name>disk1</name><interface>virtio_scsi</interface><format>cow</format><storage_domains><storage_domain><name>${RHEVM_STORAGE}</name></storage_domain></storage_domains><bootable>true</bootable></disk>
EOF
  local DISK_ID=$(ovirt /vms/$VMS_ID/disks -d @/tmp/x -H "Content-type: application/xml" | grep disk.href | grep id= | sed 's/^.* id="\(.*\)".*$/\1/')
  check_blank DISK_ID
  warn "Disk_ID=$DISK_ID"

  info "Creating NIC for vms=$VMS_ID"
  local VNIC_PROFILE_ID=$(ovirt /vnicprofiles | grep -e vnic_profile.href -e '<name>' | shtml | sed 's%<vnic_profile.* id="\(.*\)">%\1%' | cut -b 2- | paste - - -d' ' | grep " $RHEVM_INTERFACE$" | cut -d ' ' -f 1)
  check_blank VNIC_PROFILE_ID
  warn "VNIC_PROFILE_ID=$VNIC_PROFILE_ID"

  cat<<EOF > /tmp/x
  <nic><name>eth0</name><vnic_profile id="$VNIC_PROFILE_ID" /></nic>
EOF
  local MAC=$(ovirt /vms/$VMS_ID/nics -H "Content-type: application/xml" -d @/tmp/x | grep mac.address | tr -d ' ' | tr '<>"' ',' | cut -d , -f 3)
  check_blank MAC
  warn "Mac=$MAC"

  set +e +E
  info "Waiting for disk to come online..."
  I=10
  while [ $I -gt 0 ] ; do
	  ovirt /vms/$VMS_ID/disks/$DISK_ID | grep state | grep -q ok && break
	  I=$[ $I - 1 ]
	  sleep 3
	  info "$(date)"
  done

  if [ $I -eq 0 ] ; then
	  info "VM disk status isn't up!"
	  exit 1
  fi

  set -e

  info "Creating host in foreman: $HOST, mac=$MAC, ip=$IP, HG=$HG_ATOMIC, ORG=$ORG, LOC=$LOC"
  info "Root password defaulting to: \e[1m${NEW_HOST_ROOT}"
  cmd "hammer host create --name=${HOST} \
    --hostgroup=$HG_ATOMIC \
    --interface='primary=true, provision=true, mac=${MAC}, ip=$IP' \
    --organization="$ORG" \
    --location="$LOC" \
    --root-password=${NEW_HOST_ROOT}"
  # --ask-root-password=yes

  info "Starting VM to boot from network"
  cat <<EOF > /tmp/x
  <action/>
EOF
  cmd "ovirt /vms/$VMS_ID/start -H 'Content-type: application/xml' -d @/tmp/x | grep state | shtml"
}


