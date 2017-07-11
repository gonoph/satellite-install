#!/bin/sh
# Satellite-install template based provisioning script - to aid in the provisioning of kickstart hosts
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

DNS_SERVERS=$(grep ^nameserver /etc/resolv.conf | cut -d ' ' -f 2 | head -n 1)
DNS_SEARCH=$(grep ^search /etc/resolv.conf | cut -d ' ' -f 2- | head -n 1)
GW=$(echo $(echo $IP | rev | cut -d. -f 2- | rev).1)

do_create() {
  info "Trying to determine Activation Key"
  AK=$(hammer --output=json hostgroup info --name="$HG" | python -c "import json,sys
s=json.load(sys.stdin)
m=filter(lambda a: a['name'] == 'kt_activation_keys', s['Parameters'])
print reduce(lambda x,y: y['value'], m, '')")
  check_blank AK
  warn "AK=$AK"
  info "Creating VM with cloud-init data"
cat<< EOF >/tmp/x
<vm>
    <name>${NAME}</name>
    <template>
	<name>${RHEL_TEMPLATE}</name>
    </template>
    <cluster>
	<name>${RHEVM_CLUSTER}</name>
    </cluster>
    <display>
	<type>VNC</type>
    </display>
    <os type="rhel_7x64">
	<boot dev="cdrom"/>
	<boot dev="hd"/>
    </os>
    <type>server</type>
    <disks clone="false" />
    <payloads>
	<payload type="cdrom">
	    <files>
		<file>
		    <name>user-data</name>
		    <content>#cloud-config &#10;
hostname: $HOST&#10;
manage_etc_hosts: true&#10;
ssh_pwauth: true &#10;
disable_root: 0 &#10;
output: &#10;
   all: '&gt;&gt; /var/log/cloud-init-output.log' &#10;
user: root &#10;
password: $NEW_HOST_ROOT &#10;
chpasswd: &#10;
   expire: false &#10;
&#10;
manage-resolv-conf: true &#10;
&#10;
resolv_conf: &#10;
   nameservers: [ '$DNS_SERVERS' ] &#10;
   searchdomains: &#10;
    - $(sed 's/ /\n    - /g' <<< "$DNS_SEARCH" | sed 's/$/ \&#10;/')
   domain: $( cut -d. -f 2- <<< "$HOST" ) &#10;
&#10;
runcmd:&#10;
 - nmcli c modify eth0 ipv4.dns $DNS_SERVERS &#10;
 - nmcli c modify eth0 ipv4.dns-search $( tr ' ' ',' <<< "$DNS_SEARCH" ) &#10;
 - ifdown eth0 &#10;
 - ifup eth0 &#10;
 - curl http://$(hostname)/pub/install.sh &gt; /tmp/install.sh &#10;
 - chmod +x /tmp/install.sh &#10;
 - ORG='$ORG' AK='$AK' /tmp/install.sh
 </content>
		</file>
	       <file>
		   <name>meta-data</name>
		   <content>#cloud-config &#10;
instance-id: iid-local01&#10;
network-interfaces: |&#10;
   auto eth0&#10;
   iface eth0 inet static&#10;
   address $IP&#10;
   netmask 255.255.255.0&#10;
   gateway $GW&#10;
   dns-nameservers $DNS_SERVERS&#10;
   dns-search $DNS_SEARCH&#10;
hostname: $HOST&#10;
name: $HOST&#10;
</content>
	       </file>
	    </files>
            <volume_id>cidata</volume_id>
	</payload>
    </payloads>
</vm>
EOF
VMS_ID=$(ovirt /vms -H "Content-type: application/xml" -d @/tmp/x | grep vm.href | grep id= | sed 's/^.* id="\(.*\)".*$/\1/')
check_blank VMS_ID
warn "VMS_ID=$VMS_ID"
/usr/bin/cp -f /tmp/l /tmp/1

set +e +E
info "Waiting for disk to come online..."
I=10
while [ $I -gt 0 ] ; do
  if !  ovirt /vms/$VMS_ID | grep -q '^        <state>image_locked</state>' ; then
    grep -q '        <state>down</state>' /tmp/l && break
  fi
  I=$[ $I - 1 ]
  sleep 5
  info "$(date)"
done

if [ $I -eq 0 ] ; then
  info "VM disk status isn't up!"
  exit 1
fi

set -e
}

do_start() {
  info "Starting VM"
# local CHECK=$( ovirt /vms/$VMS_ID -H "Content-type: application/xml" -d @/tmp/x -X PUT | grep initialization)
# check_blank CHECK
# info "Assigned cloud-init"

cat << EOF > /tmp/x
<action>
    <!--use_cloud_init>true</use_cloud_init -->
</action>
EOF
local STATE=$( ovirt /vms/$VMS_ID/start -H "Content-type: application/xml" -d @/tmp/x | grep '^        <state>complete</state>' | shtml )
  check_blank STATE
  info "Started"
  info "Waiting on host to register"
  I=20
  while [ $I -gt 0 ] ; do
    local TMP=$( hammer --csv host list --search name=$HOST | tail -n +2)
    [ -n "$TMP" ] && break
    I=$[ $I - 1 ]
    sleep 15
    info "$(date)"
  done

  if [ $I -eq 0 ] ; then
    warn "Timeout waiting for $HOST to register"
    info "When it does, run this command:"
    info "hammer host update --hostgroup=$HG --name $HOST --managed yes"
    exit 1
  fi
  info "Updating $HOST to Host Group: $H$HG"
  hammer host update --hostgroup="$HG" --name $HOST --managed yes
  if [ $? -ne 0 ] ; then
    warn "That's weird, shouldn't have given an error. Let's try that again."
    info "Updating $HOST to Host Group: $H$HG"
    hammer host update --hostgroup="$HG" --name $HOST --managed yes
  fi
}

do_action() {
  do_create
  do_start
}
