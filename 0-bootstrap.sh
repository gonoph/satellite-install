#!/bin/sh
# vim: sw=2 ai
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

# make sure if there is an error, we abort

##
# start of global include section.
##

# All scripts that need the common functions
# will include this file, and it will test to see it's being included or not,
# and exit appropriately.

set -e 

: ${BETA:=}
: ${BASEURL:=}
[ -n "$BETA" ] && echo -e "\e[1;31mBETA Mode on\e[0m"
[ -n "$BASEURL" ] && echo -e "\e[1;31mBASEURL is set\e[0m"

# Defining the ANSI variables
H=$(echo -e "\e[1m")
h=$(echo -e "\e[22m")
N=$(echo -e "\e[0m")
export H h N

##
# Defining the output functions
##

# Purpose: output information with ANSI without EOL
# Usage: ninfo $data1 $data2 ... $dataN
# Input: $dataN - data to output
# Output: information output
ninfo() {
  echo -ne "\e[0;34m#\e[32m" "$@" "$N" 1>&2
}

# Purpose: output information with ANSI
# Usage: info $data1 $data2 ... $dataN
# Input: $dataN - data to output
# Output: information output
info() {
  ninfo "$@"
  echo 1>&2
}

# Purpose: output warning with ANSI
# Usage: warn $data1 $data2 ... $dataN
# Input: $dataN - data to output
# Output: warning output
warn() {
  echo -e "\e[0;33m""$@""$N" 1>&2
}

# Purpose: output error with ANSI, then exit
# Usage: err $data1 $data2 ... $dataN
# Input: $dataN - data to output
# Output: error output, then exits
err() {
  echo -e "\e[1;31mERROR:$h" "$@" >&2
  exit 1
}

# Purpose: set the release of the RHEL system to 7Server
# Usage: set_release
# Input: None
# Output: regular output of subscription-manager
[ -r /tmp/.cache-release -a "$(cat /tmp/.cache-release)" = "Release: 7Server" ] || rm -fv /tmp/.cache-release
set_release() {
  [ -r /tmp/.cache-release -a "$(cat /tmp/.cache-release)" = "Release: 7Server" ] && return 0
  subscription-manager release --set=7Server
  subscription-manager release > /tmp/.cache-release
}

# Purpose: disable all the repos, unless already disabled
# Usage: disable_repos
# Input: None
# Output: number of repos disabled
disable_repos() {
  ninfo "Disabling repos: "
  if ! grep -q '^enabled = ' /etc/yum.repos.d/redhat.repo ||
    grep -q '^enabled = 1' /etc/yum.repos.d/redhat.repo ; then
    # need to run subscription-manager
    subscription-manager repos --disable "*" > /tmp/l 2>&1
  else
    grep '^enabled = ' /etc/yum.repos.d/redhat.repo > /tmp/l 2>&1
  fi
  cat /tmp/l | wc -l
}

# Purpose: enable list of repos
# Usage: enable_repos $repo1 $repo2 ... $repoN
# Input: $repoN - list of repos to enable
# Output: number of repos enabled
enable_repos() {
  [ $# -eq 0 ] && err "Must give repos to enable"
  local args=""
  while [ $# -gt 0 ] ; do
    args+="--enable=$1 "
    shift 1
  done

  [ -n "$BASEURL" ] && rm -f /etc/yum.repos.d/redhat-new.repo
  info subscription-manager repos $args
  subscription-manager repos $args

  if [ -n "$BASEURL" ] ; then
    warn "Enabling $BASEURL for repos"
    /usr/bin/cp -f /etc/yum.repos.d/redhat.repo /tmp/redhat-new.repo
    sed -i -e "s%https://cdn.redhat.com/content/%$BASEURL%" -e 's%-rpms]%-rpms-new]%' /tmp/redhat-new.repo
    yum clean all
    disable_repos
    mv -f /tmp/redhat-new.repo /etc/yum.repos.d/redhat-new.repo
  fi
}

[ $0 = $BASH_SOURCE ] && METHOD=main || METHOD=called

##
# end of global include section.
##

# Purpose: find the organzation for the subscription using the login/pass
# Usage: rhn_findorg
# Input: None
# Output: the ORG_ID
rhn_findorg() {
    curl -s -u $RHN_USER:$RHN_PASS -k https://subscription.rhn.redhat.com/subscription/users/$RHN_USER/owners | python -mjson.tool | grep '"key"' | cut -d '"' -f 4
}

# Purpose: pull a list of systems from the Red Hat Portal and attempt to match based on the current hostname
# Usage: rhn_helper
# Input: None
# Output: the UUID of the current host if found
rhn_helper() {
    RHN_ORG_ID=$(rhn_findorg)
    [ -z "$RHN_ORG_ID" ] && err "Unable to lookup owner ID and subscribed systems from RHN using login info for: $RHN_USER"
    info "RHN ORG id is: " $HREF 1>&2
    local MYHN=$(hostname)
    info "Trying to match to: $MYHN" 1>&2
    # cycle through the systems and find a match
    curl -s -u $RHN_USER:$RHN_PASS -k https://subscription.rhn.redhat.com/subscription/owners/$RHN_ORG_ID/consumers | python -mjson.tool | egrep '^        "(name|uuid)"' | awk '!(NR%2){print$0p}{p=$0}' | cut -d '"' -f 4,8 | tr '"' ' ' | while read UUID HN ; do
        if [ "$HN" = $MYHN ] ; then
            info "Found matching host ($HN) with uuid: $UUID" 1>&2
            echo $UUID
            export UUID=$UUID
            return
        fi
    done
}

# Purpose: register system using Activation Key and org, OR using login/pass
#          register a new system or attach to existing system
# Usage: register_system
# Input: None
# Output: help screen if not successful, or normal output from subscription-manager
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
            warn "Unable to find UUID for existing subscripbed host with this hostname."
        fi
    fi
    if [ -n "$RHN_OLD_SYSTEM" ] && [ -n "$RHN_USER" ] ; then
        local PASS=""
        [ -n "$RHN_PASS" ] && PASS="--password=$RHN_PASS"
        subscription-manager register --consumerid=$RHN_OLD_SYSTEM --username=$RHN_USER $PASS
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

# Purpose: make sure the hostname of the registered system matches that of the real hostname
# Usage: fix_hostname
# Input: None
# Output: informational screens
fix_hostname() {
    HOST=$(subscription-manager identity | awk '/^name: / { print $2 }')
    if [ "$(hostname)" = "$HOST" ] ; then
	info "Just making sure hostname matches what's in hostnamectl"
	hostnamectl set-hostname $HOST
        return
    fi

    warn "Current hostname and old hostname don't match."
    warn "Setting current hostname to: $HOST"
    hostnamectl set-hostname $HOST
}

# Purpose: make sure the ip address matches the old ip address of the hostname
# Usage: fix_ip
# Input: None
# Output: informational output, or exit on error
fix_ip() {
    info "Determining old ip from hostname: $HOST"
    local OLDIP=$(ping -w 1 -c 1 $HOST 2>/dev/null | grep ^PING | tr '()' ',' | cut -d , -f 2)
    if [ -z "$OLDIP" ] ; then
        warn "Unable to determine old ipaddress"
        return 0
    fi
    INTERFACE=$(ip route | grep ^default | sed 's/^.*dev \([[:alnum:]]*\) .*$/\1/')

    [ -z "$INTERFACE" ] && err "Unable to find primary ethernet device!"

    local T=$(nmcli c show $INTERFACE | grep ipv4\. | tr -s ' ' | sed -e 's/: \(.*\)$/="\1"/' -e 's/ipv4\./local ipv4_/' -e 's/-/_/g' );
    [ -z "$T" ] && err "Unable to determine IP address information!"

    eval $T

    IP_MASK=$( ip addr show $INTERFACE | grep 'inet ' | tr -s ' ' | cut -d ' ' -f 3)
    MASK=$(cut -d / -f 2 <<< "$IP_MASK")
    IP=$(cut -d / -f 1 <<< "$IP_MASK")
    if [ "$IP" = "$OLDIP" ] ; then
        info "Old ip and current ip are the same."
        unset INTERFACE
        return
    fi
    warn "Old ip and current ip don't match, setting ip to old ip: [$H$OLDIP/$MASK$H]"
    if [ "$ipv4_method" = "auto" ] ; then
	local DNS=$(nmcli c show $INTERFACE | grep ' domain_name_servers' | cut -d = -f 2 | cut -d ' ' -f 2-)
	local SEARCH=$( awk '/^search / {print $2}' /etc/resolv.conf)
	local GW=$( nmcli c show $INTERFACE | grep ' routers' | cut -d = -f 2 | tr -d ' ')
        nmcli c modify $INTERFACE ipv4.method manual +ipv4.addresses "$OLDIP/$MASK" ipv4.dns "$DNS" ipv4.dns-search "$SEARCH" ipv4.gateway "$GW"
    else
        nmcli c modify $INTERFACE ipv4.method manual +ipv4.addresses "$OLDIP/$MASK" -ipv4.addresses "$IP/$MASK" ipv4.dns "$ipv4_dns" ipv4.dns-search "$ipv4_dns_search" ipv4.gateway "$ipv4_gateway"
    fi
}

main() {
  subscription-manager identity || register_system
  fix_hostname
  fix_ip

  set_release
  disable_repos
  enable_repos rhel-7-server-rpms rhel-7-server-rh-common-rpms

  yum install -y screen git vim bind-utils

  [ -r satellite-install/.git ] || git clone https://github.com/gonoph/satellite-install.git

  (
    cd satellite-install
    git pull
  )

  if fgrep -q nfs /etc/fstab ; then
    warn "You have NFS mounts, you should probably make sure they're good."
    grep nfs /etc/fstab
    read -p "Edit now? " YN
    case $YN in
      y|Y|[yY][eE][sS])
	vim /etc/fstab
	;;
    esac
    echo
  fi

  CONSUMERID=$(subscription-manager identity | awk -n '/^system identity: / {print $3}')
  cat << EOF
There is a special trick you can do before and after the pre-install script. If
you have a local CDN copy of the repos, you can register your system using your
copy as the ${H}baseurl${h}, then reregister back to the same system resetting
the CDN back to Red Hat defaults.

	subscription-manager clean
	subscription-manager register --consumerid=${H}$CONSUMERID${h} --baseurl=${H}\$MYURL${h}
	make install

Then after the satellite install, you can go back

	subscription-manager clean
	subscription-manager register --consumerid=${H}$CONSUMERID${h} --baseurl=${H}https://cdn.redhat.com${h}
	make pre-install-only

EOF
  if [ -n "$INTERFACE" ] ; then
    warn "IP address changed! You should reboot!"
    read -p "Reboot now? " YN
    case $YN in
      y|Y|[yY][eE][sS])
	systemctl reboot;;
    esac
    echo
    warn "Ok, but you need to reboot soon!"
  fi
}

[ "$METHOD" = "main" ] && main "$@" || info "loaded core functions"
