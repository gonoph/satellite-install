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
  echo -ne "\e[0;34m#\e[32m" "$@""$N" 1>&2
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
  echo -e "\e[1;31mERROR:$h" "$@""$N" >&2
  exit 1
}

# Purpose: set the release of the RHEL system to 7Server
# Usage: set_release
# Input: None
# Output: regular output of subscription-manager
[ -r /tmp/.cache-release ] && [ "$(cat /tmp/.cache-release)" = "Release: 7Server" ] || rm -fv /tmp/.cache-release
set_release() {
  info "Ensuring the Release is ${H}7Server$h according to the install doc."
  [ -r /tmp/.cache-release ] && [ "$(cat /tmp/.cache-release)" = "Release: 7Server" ] && return 0
  subscription-manager release --set=7Server
  subscription-manager release > /tmp/.cache-release
}

# Purpose: disable all the repos, unless already disabled
# Usage: disable_repos
# Input: None
# Output: number of repos disabled
disable_repos() {
  info "Disabling all the Red Hat repos"
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
    sed -i -e "s%https://cdn.redhat.com/%$BASEURL/%" -e 's%-rpms]%-rpms-new]%' /tmp/redhat-new.repo
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
    info "Looking up ORG_ID using USER: $H$RHN_USER"
    curl -s -u $RHN_USER:$RHN_PASS -k https://subscription.rhn.redhat.com/subscription/users/$RHN_USER/owners | python -mjson.tool | grep '"key"' | cut -d '"' -f 4
}

# Purpose: pull a list of systems from the Red Hat Portal and attempt to match based on the current hostname
# Usage: rhn_helper
# Input: None
# Output: the UUID of the current host if found
rhn_helper() {
    RHN_ORG_ID=$(rhn_findorg)
    [ -z "$RHN_ORG_ID" ] && err "Unable to lookup owner ID and subscribed systems from RHN using login info for: $RHN_USER"
    info "RHN ORG id is: " $RHN_ORG_ID 1>&2
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
    info "Trying to register the system to the CDN"
    if [ "$(hostname --short)" = "localhost" ] ; then
        cat << EOF

It looks like you ${H}forgot$h to set a valid hostname for this server.

    $(hostname)

is not a good name for a satellite server. Please decide on a hostname and set it like this:

    hostnamectl set-hostname ${H}satellite.example.com$h

${H}PLEASE NOTE$h
1) The hostname you define must resolve to a valid IP address.
2) The resolvable IP address will become the IP address of this Satellite server.
3) It's best to use an external DNS server as that represents real life scenarios.
4) Or... you can use the ${H}/etc/hosts$h file to fake it, but remember to setup your Satellite server to act as a DNS server for the domain.

EOF
        err "Refusing to register a system named ${H}localhost$h. Did you ${H}forget$h to set a good hostname?"
    fi
    if [ -n "$RHN_ACTIVATION_KEY" ] ; then
        info "Using Activation key: $H$RHN_ACTIVATION_KEY"
        if [ -z "$RHN_ORG_ID" ] && [ -n "$RHN_USER" ] ; then
            RHN_ORG_ID=$(rhn_findorg)
        fi
        if [ -n "$RHN_ORG_ID" ] ; then
            info "Registering using ORG_ID: $H$RHN_ORG_ID"
            subscription-manager register --activationkey=${RHN_ACTIVATION_KEY} --org=${RHN_ORG_ID}
            return
        fi
    fi
    if [ -n "$RHN_USER" ] && [ -n "$RHN_PASS" ] ; then
        if [ -z "$RHN_OLD_SYSTEM" ] ; then
            RHN_OLD_SYSTEM=$(rhn_helper)
        fi
        if [ -z "$RHN_OLD_SYSTEM" ] ; then
            warn "Unable to find UUID for existing subscripbed host with this hostname."
        else
            subscription-manager register --consumerid=$RHN_OLD_SYSTEM --username=$RHN_USER --password=$RHN_PASS
            return
        fi
    fi
    cat<<EOF
${H}Needed environment variables not set!$h

To register the system, you can:

1) do it manually, then rerun this script.
2) set certain environment variables and rerun this script.

Environment variables steps:

$H== REGISTER VIA UUID ==$h
1) Log into the portal: https://access.redhat.com/management/consumers?type=system
2) Find the old system, copy it's UUID (ex: ad88c818-7777-4370-8878-2f1315f7177a)
3) -or- create(register) a new system in the portal, attach the ${H}Satellite Subscription$h, and copy it's UUID.
4) Set these ENV variables:

    export RHN_USER RHN_PASS
    export RHN_OLD_SYSTEM=ad88c818-7777-4370-8878-2f1315f7177a

5) Run this script

$H== REGISTER VIA UUID BY LOOKING UP OLD UUID BY HOSTNAME ==$h
1) Ensure hostname of the system is the same as the previous registration
2) Set these ENV variables:

    export RHN_USER RHN_PASS

3) Run this script

$H== REGISTER BY ACTIVATION KEY ==$h

1) Setup an activation key via: https://access.redhat.com/management/activation_keys
2) Set these ENV variables:

    export RHN_ORG_ID
    # _or_
    export RHN_USER RHN_PASS
    export RHN_ACTIVATION_KEY

3) If you're using the RHN_USER, a helper script will find the ORG

EOF
    exit 1
}

# Purpose: make sure the hostname of the registered system matches that of the real hostname
# Usage: fix_hostname
# Input: None
# Output: informational screens
fix_hostname() {
    info "Checking current hostname($H$(hostname)$h) matches the registered host."
    HOST=$(subscription-manager identity | awk '/^name: / { print $2 }')
    info "Registered host: $H$HOST"
    if [ "$(hostname)" = "$HOST" ] ; then
    info "Looks good, just making sure hostname matches what's in hostnamectl"
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
    local OLDIP=$(python -c "import socket as s;print s.gethostbyname('$HOST')")
    if [ -z "$OLDIP" ] ; then
        warn "Unable to determine old ipaddress"
        return 0
    fi
    info "OLDIP=$H$OLDIP"
    if [ $OLDIP = "127.0.0.1" ] ; then
        err "${H}OLDIP$h was localhost (${H}127.0.0.1$h). Did you add an invalid entry for the hostname in ${H}/etc/hosts$h ?"
    fi

    info "Determining interface to access OLDIP: ${H}$OLDIP"
    INTERFACE=$( ip route get $OLDIP | tr -s ' ' | head -n 1 )
    set $INTERFACE

    [ "$1" = "$OLDIP" ] || err "ip route didn't return the IP we gave it: $1"
    [ "$2" = "dev" -o "$4" = "src" ] || err "ip route didn't return the correct fields [\$ip dev \$intf src \$current_ip"

    INTERFACE=$3
    [ -z "$INTERFACE" ] && err "Unable to find primary ethernet device!"
    info "INTERFACE=$H$INTERFACE"

    IP=$5
    [ -z "$IP" ] && err "Unable to determine current IP!"
    info "CURRENTIP=$H$IP"

    if [ "$IP" = "$OLDIP" ] ; then
        info "Old ip and current ip are the same."
        unset INTERFACE
        return
    fi

    local NM_UUID=$(nmcli -t --fields DEVICE,UUID c | grep "^$INTERFACE:" | cut -d: -f 2)
    [ -z "$NM_UUID" ] && err "Unable to find primary NetworkManager connection!"
    info "NM_UUID=$H$NM_UUID"

    local IP_MASK=$(nmcli -t c show $NM_UUID | grep IP4 | cut -d: -f 2 | grep "^$IP/" )
    [ -z "$IP_MASK" ] && err "Unable to determine IP address information!"

    MASK=$(cut -d / -f 2 <<< "$IP_MASK")
    IP=$(cut -d / -f 1 <<< "$IP_MASK")

    if [ "$IP" = "127.0.0.1" ] ; then
        err "Current ip address is localhost, this really shouldn't happen! You'll need to register the system yourself."
    fi

    warn "Old ip and current ip don't match, setting ip to old ip: [$H$OLDIP/$MASK$h]"
    local ipv4_method=$(nmcli -t c show $NM_UUID | grep ipv4.method | cut -d: -f 2 )
    if [ "$ipv4_method" = "auto" ] ; then
        local DNS=$(nmcli -t c show $NM_UUID | grep ':domain_name_servers' | cut -d= -f 2 | cut -d' ' -f 2- | tr ' ' ,)
        local SEARCH=$( awk '/^search / {print $2}' /etc/resolv.conf)
        local GW=$( nmcli -t c show $NM_UUID | grep ':routers' | cut -d= -f 2 | tr -d ' ')
        nmcli c modify $NM_UUID ipv4.method manual +ipv4.addresses "$OLDIP/$MASK" ipv4.dns "$DNS" ipv4.dns-search "$SEARCH" ipv4.gateway "$GW"
    else
        nmcli c modify $NM_UUID +ipv4.addresses "$OLDIP/$MASK"
    fi
}

main() {
  if [ -n "$BASEURL" ] ; then
    warn "BASEURL is set, ensuring it's valid: $H$BASEURL"
    local T=$(mktemp)
    local basearch=$(uname -i)
    if ! curl "$BASEURL"/content/dist/rhel/server/7/7Server/$basearch/os/repodata/repomd.xml -o /dev/null -sSf 2>$T ; then
      T=$(cat $T)
      rm -f $T
      err "BASEURL isn't a valid CDN mirror: $H$T"
    fi
    rm -f $T
    info "BASEURL looks good"
  fi
  info "Checking if the system is already registered"
  subscription-manager identity || register_system
  fix_hostname
  fix_ip

  set_release
  disable_repos
  enable_repos rhel-7-server-rpms rhel-7-server-rh-common-rpms

  info yum install -y screen git vim bind-utils
  yum install -y screen git vim bind-utils

  info "Cloning satellite-install from github"
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
  info "Bootstrap complete!"
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
  info "When you're done, just cd to $H`pwd`/satellite-install$h and type make"
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
