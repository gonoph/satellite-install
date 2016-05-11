#!/bin/sh
# Satellite-install bootstrap script
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

rhn_findorg() {
    curl -s -u $RHN_USER:$RHN_PASS -k https://subscription.rhn.redhat.com/subscription/users/$RHN_USER/owners | python -mjson.tool | grep '"key"' | cut -d '"' -f 4
}

# this will pull a list of systems from the Red Hat Portal and attempt to match based on the current hostname
rhn_helper() {
    RHN_ORG_ID=$(rhn_findorg)
    if [ -z "$RHN_ORG_ID" ] ; then
        echo "Unable to lookup owner ID and subscribed systems from RHN using login info for: $RHN_USER" >&2
        exit 1
    fi
    echo "# RHN ORG id is: " $HREF 1>&2
    local MYHN=$(hostname)
    echo "# Trying to match to: $MYHN" 1>&2
    # cycle through the systems and find a match
    curl -s -u $RHN_USER:$RHN_PASS -k https://subscription.rhn.redhat.com/subscription/owners/$RHN_ORG_ID/consumers | python -mjson.tool | egrep '^        "(name|uuid)"' | awk '!(NR%2){print$0p}{p=$0}' | cut -d '"' -f 4,8 | tr '"' ' ' | while read UUID HN ; do
        if [ "$HN" = $MYHN ] ; then
            echo "# Found matching host ($HN) with uuid: $UUID" 1>&2
            echo $UUID
            export UUID=$UUID
            return
        fi
    done
}

register_system() {
    if [ -n "$RHN_ACTIVATION_KEY" ] ; then
        if [ -z "$RHN_ORG_ID" ] && [ -n "$RHN_USER" ] ; then
            RHN_ORG_ID=$(rhn_findorg)
        fi
        if [ -n "$RHN_ORG_ID" ] ; then
            subscription-manager register --activationkey=${RHN_ACTIVATION_KEY} --org=${RHN_ORG_ID}
            return
        fi
    fi
    if [ -n "$RHN_USER" ] && [ -n "$RHN_PASS" ] ; then
        RHN_OLD_SYSTEM=$(rhn_helper)
        if [ -z "$RHN_OLD_SYSTEM" ] ; then
            echo "### Unable to find UUID for existing subscripbed host with this hostname." >&2
        fi
    fi
    if [ -n "$RHN_OLD_SYSTEM" ] && [ -n "$RHN_USER" ] ; then
        subscription-manager register --consumerid=$RHN_OLD_SYSTEM --username=$RHN_USER
        return
    fi
    cat<<EOF
Needed environment variables not set!

If you want to reuse an existing system:

1) Log into the portal: https://access.redhat.com/management/consumers?type=system
2) Find the old system, copy it's UUID (ex: ad88c818-7777-4370-8878-2f1315f7177a)
3) Set these ENV variables:

    export RHN_OLD_SYSTEM=ad88c818-7777-4370-8878-2f1315f7177a
    export RHN_USER=biholmes

4) Or set these environment varibles, and a helper script will do that for you

    export RHN_USER RHN_PASS

However, if you want to use an activation key, you need to do this:

1) Setup an activation key via: https://access.redhat.com/management/activation_keys
2) Set these ENV variables:

    export RHN_ACTIVATION_KEY=MY_COOL_KEY
    # _either_
    export RHN_ORG_ID=31337
    # _or_
    export RHN_USER=biholmes

3) If you're using the RHN_USER, a helper script will find the ORG

EOF
    exit 1
}

fix_hostname() {
    HOST=$(subscription-manager identity | grep ^name: | cut -d ' ' -f 2)
    if [ "$(hostname)" = "$HOST" ] ; then
	echo "Just making sure hostname matches what's in hostnamectl"
	hostnamectl set-hostname $HOST
        return
    fi

    echo "Current hostname and old hostname don't match."
    echo "Setting current hostname to: $HOST"
    hostnamectl set-hostname $HOST
}

fix_ip() {
    echo "Determining old ip from hostname: $HOST"
    OLDIP=$(ping -w 1 -c 1 $HOST 2>/dev/null | grep ^PING | tr '()' ',' | cut -d , -f 2)
    if [ -z "$OLDIP" ] ; then
        echo "Unable to determine old ipaddress"
        return
    fi
    INTERFACE=$(ip route | grep ^default | sed 's/^.*dev \([[:alnum:]]*\) .*$/\1/')
    if [ -z "$INTERFACE" ] ; then
        echo "Unable to find primary ethernet device!"
        exit 1
    fi
    T=$(nmcli c show $INTERFACE | grep ipv4\. | tr -s ' ' | sed -e 's/: \(.*\)$/="\1"/' -e 's/ipv4\./local ipv4_/' -e 's/-/_/g' );
    if [ -z "$T" ] ; then
        echo "Unable to determine IP address information!"
        exit 1
    fi
    eval $T

    IP_MASK=$(nmcli c show $INTERFACE | grep ipv4.addresses | tr -s ' ' | cut -d ' ' -f 2 | cut -d , -f 1)
    MASK=$(cut -d / -f 2 <<< "$IP_MASK")
    IP=$(cut -d / -f 1 <<< "$IP_MASK")
    if [ "$IP" = "$OLDIP" ] ; then
        echo "Old ip and current ip are the same."
        unset INTERFACE
        return
    fi
    echo "Old ip and current ip don't match, setting ip to old ip: $OLDIP/$MASK"
    nmcli c modify $INTERFACE ipv4.method manual
    nmcli c modify $INTERFACE +ipv4.addresses "$OLDIP/$MASK" -ipv4.addresses "$IP/$MASK"
    nmcli c modify $INTERFACE ipv4.dns "$ipv4_dns"
    nmcli c modify $INTERFACE ipv4.dns-search "$ipv4_dns_search"
    nmcli c modify $INTERFACE ipv4.gateway "$ipv4_gateway"
}

subscription-manager identity || register_system
fix_hostname
fix_ip
subscription-manager release --set=7Server
echo -n "Disabling repos: "
subscription-manager repos --disable "*" > /tmp/l 2>&1
cat /tmp/l | wc -l
echo -n "Enabling repos: "
subscription-manager repos --enable rhel-7-server-rpms --enable rhel-7-server-rh-common-rpms > /tmp/l 2>&1
cat /tmp/l | wc -l
yum install -y screen git vim bind-utils

[ -r satellite-install/.git ] || git clone https://github.com/gonoph/satellite-install.git

(
  cd satellite-install
  git pull
)

if fgrep -q nfs /etc/fstab ; then
  echo "You have NFS mounts, you should probably make sure they're good."
  grep nfs /etc/fstab
  read -p "Edit now? " YN
  case $YN in
    y|Y|[yY][eE][sS])
      vim /etc/fstab
      ;;
  esac
fi

if [ -n "$INTERFACE" ] ; then
  echo "IP address changed! You should reboot!"
  read -p "Reboot now? " YN
  case $YN in
    y|Y|[yY][eE][sS])
      systemctl reboot;;
  esac
  echo
  echo "Ok, but you need to reboot soon!"
fi
