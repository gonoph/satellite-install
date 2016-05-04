#!/bin/sh

: ${BETA:=}
ORG="--organization-id=1"

## Enable some repos

function hammer_enable() {
  local ORG="$1"
  local PRODUCT="$2"
  local BASEARCH="$3"
  local RELEASE="$4"
  local NAME="$5"
  local ARGS
  [ -n "$BASEARCH" ] && ARGS+=" $BASEARCH"
  [ -n "$RELEASE" ] && ARGS+=" $RELEASE"
  hammer repository-set enable "${ORG}" "${PRODUCT}" $ARGS --name="$NAME"
}

info() {
  echo -e "\e[0;34m*\e[32m" "$@" "\e[0m"
}

warn() {
  echo -e "\e[1;33mWarning:\e[0;32m" "$@" "\e[0m"
}

SECTION=$1
: ${SECTION:=-h}

[ -n "$BETA" ] && echo -e "\e[1;31mBETA Mode on\e[0m"  || echo -e "\e[1;34mBETA MODE off\e[0m"
case $SECTION in
  --help|-h)
    cat<<EOF
usage: $0 (manifest (FILE) | all | -h | --help | repos | satellite | repos-extra | sync | view | publish | provisioning)
EOF
  exit 1
  ;;
esac

if [ "$SECTION" = "manifest" ] ; then
  info "Uploading manifest info \e[1;33m$(hostname)"
  FILE=$2
  : ${FILE:=/tmp/manifest.zip}
  while [ ! -r $FILE ] ; do
    warn "Unable to read: \e[0;33m$FILE"
    # if it's not interactive then exit
    [ -n "$2" ] && exit 1
    read -ep "Path to manifest: " -i "$FILE" FILE
    if [ "$(basename $FILE .zip)" = "$FILE" ] ; then
      warn "File doesn't have .zip extension: \e[1;33m$FILE"
      FILE=$(rev <<< "$FILE" | cut -d . -f 2- | rev)
    fi
  done
  hammer subscription upload --file "$FILE" $ORG --async
  I=10
  while [ $I -gt 0 ] ; do
    hammer subscription list $ORG
    DONE=$(hammer --csv subscription list --organization-id=1 | tail -n +2)
    [ -n "$DONE" ] && break
    I=$[ I - 1 ]
    sleep 3
  done
  exit
fi

## RHEL Repos
PRODUCT='--product=Red Hat Enterprise Linux Server'
RELEASE="--releasever=7Server"
BASEARCH="--basearch=x86_64"

if [ "$SECTION" = "all" -o "$SECTION" = "repos" ] ; then
  info "Enabling repos for \e[1;33m$PRODUCT"
  hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Enterprise Linux 7 Server (RPMs)'
  hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Enterprise Linux 7 Server (Kickstart)'
  hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Enterprise Linux 7 Server - RH Common (RPMs)'
  if [ -z "$BETA" ] ; then
    info "Enabling non-beta repos"
    hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Enterprise Linux 7 Server - Optional (RPMs)'
    hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Enterprise Linux 7 Server - Supplementary (RPMs)'
    hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Storage Native Client for RHEL 7 (RPMs)'
    hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'RHN Tools for Red Hat Enterprise Linux 7 Server (RPMs)'
  fi
  info "Enabling extra repos"
  RELEASE=""
  hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Enterprise Linux 7 Server - Extras (RPMs)'
  if [ -n "$BETA" ] ; then
    info "Enabling satellite tools beta"
    hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Satellite Tools 6 Beta (for RHEL 7 Server) (RPMs)'
  else
    info "Enabling satellite tools 6.1"
    hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Satellite Tools 6.1 (for RHEL 7 Server) (RPMs)'
  fi
fi

if [ "$SECTION" = "all" -o "$SECTION" = "satellite" ] ; then
  RELEASE=""
  if [ -z "$BETA" ] ; then
    info "Enabling satellite repos for 6.1"
    PRODUCT='--product=Red Hat Satellite'
    hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Satellite 6.1 (for RHEL 7 Server) (RPMs)'
  else
    info "Enabling satellite beta repos"
    PRODUCT='--product=Red Hat Satellite 6 Beta'
    hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Satellite 6 Beta (for RHEL 7 Server) (RPMs)'
  fi
fi

## Add more repos and products
ORG="--organization-id=1"

if [ "$SECTION" = "all" -o "$SECTION" = "repos-extra" ] ; then
  info "Enabling extra forge repos"
  hammer product create ${ORG} --name='Forge'
  hammer repository create ${ORG} --name='Puppet Forge' --product='Forge' --content-type='puppet' --publish-via-http=true --url=https://forge.puppetlabs.com

  if [ -z "$BETA" ] ; then
    info "Enabling extra EPEL repos"
    hammer product create ${ORG} --name='EPEL'
    hammer repository create ${ORG} --name='EPEL 7 - x86_64' --product='EPEL' --content-type='yum' --publish-via-http=true --url=http://dl.fedoraproject.org/pub/epel/7/x86_64/

    info "Enabling extra Fedora 22,23 repos"
    hammer product create ${ORG} --name='Fedora'
    hammer repository create ${ORG} --name='Fedora 22 - x86_64' --product='Fedora' --content-type='yum' --publish-via-http=true --url=http://dl.fedoraproject.org/pub/fedora/linux/releases/22/Everything/x86_64/os/
    hammer repository create ${ORG} --name='Fedora 23 - x86_64' --product='Fedora' --content-type='yum' --publish-via-http=true --url=http://dl.fedoraproject.org/pub/fedora/linux/releases/23/Everything/x86_64/os/

    info "Enabling extra Fedora 22,23 update repos"
    hammer repository create ${ORG} --name='Fedora 22 Updates - x86_64' --product='Fedora' --content-type='yum' --publish-via-http=true --url=http://dl.fedoraproject.org/pub/fedora/linux/updates/22/x86_64/
    hammer repository create ${ORG} --name='Fedora 23 Updates - x86_64' --product='Fedora' --content-type='yum' --publish-via-http=true --url=http://dl.fedoraproject.org/pub/fedora/linux/updates/23/x86_64/
  fi

fi

## Add a sync plan
ORG="--organization-id=1"

if [ "$SECTION" = "all" -o "$SECTION" = "sync" ]; then
  info "Creating sync plan for daily syncs"
  hammer sync-plan create --interval=daily --name='Daily sync' ${ORG} --enabled=yes --sync-date=$(date +%Y-%m-%d)
  hammer sync-plan list ${ORG}

  info "Adding all repos to the sync plan"
  ## add stuff to the sync plan
  hammer product set-sync-plan --sync-plan-id=1 ${ORG} --name='Red Hat Enterprise Linux Server'
  hammer product set-sync-plan --sync-plan-id=1 ${ORG} --name='Forge'
  if [ -z "$BETA" ] ; then
    hammer product set-sync-plan --sync-plan-id=1 ${ORG} --name='EPEL'
    hammer product set-sync-plan --sync-plan-id=1 ${ORG} --name='Fedora'
    hammer product set-sync-plan --sync-plan-id=1 ${ORG} --name='Red Hat Satellite'
  else
    hammer product set-sync-plan --sync-plan-id=1 ${ORG} --name='Red Hat Satellite 6 Beta'
  fi
fi

if [ "$SECTION" = "all" -o "$SECTION" = "view" ] ; then
  PRODUCT="=--product='Red Hat Enterprise Linux Server"
  info "Creating content view for \e[1;33m$PRODUCT"
  # Create a content view for RHEL 7 server x86_64:
  hammer content-view create --name='rhel-7-server-x86_64-cv' ${ORG}
  hammer --csv repository list ${ORG} "${PRODUCT}" | tail -n +2 | while IFS="," read I N P C U ; do
    info " Attaching \e[1;33m$N"
    hammer content-view add-repository --name='rhel-7-server-x86_64-cv' ${ORG} --repository-id=${I}
  done
fi

if [ "$SECTION" = "all" -o "$SECTION" = "publish" ] ; then
  info "publishing rhel7 content view"
  hammer content-view publish --name="rhel-7-server-x86_64-cv" ${ORG} --async
fi

if [ "$SECTION" = "all" -o "$SECTION" = "provisioning" ] ; then
  info "Provisioning setting: subnet"
  DNS=
  hammer subnet create --organization-ids=1 --boot-mode=Static --dns-primary=192.168.26.82 --dns-secondary=192.168.25.10 --name=$(hostname -d) --network=192.168.26.0 --mask=255.255.255.0 --gateway=192.168.26.10 --ipam=None --tftp-id=1

  info "Provisioning setting: activation-key"
  hammer activation-key create --organization-id=1 --name=RHEL7-BASE --content-view='Default Organization View' --lifecycle-environment=Library --unlimited-content-hosts

  info "Provisioning setting: hostgroup"
  hostgroup create --organization-ids=1 --architecture=x86_64 --domain=$(hostname -d) --environment=production --medium=Test62/Library/Red_Hat_Server/Red_Hat_Enterprise_Linux_7_Server_Kickstart_x86_64_7Server --name=RHEL7-Server --operatingsystem='RedHat 7.2' --partition-table='Kickstart default' --puppet-ca-proxy-id=1 --puppet-proxy-id=1 --subnet=$(hostname -d) --root-pass=redhat123

  info "Provisioning setting: adding subscriptions to activation key"
  SUBSCRIPTION_ID=$(hammer --output=csv subscription list --organization-id=1 | awk -F, '/^Employee/ {print $8}')
  hammer activation-key add-subscription --organization-id=1 --name=RHEL7-BASE --subscription-id=$(SUBSCRIPTION_ID)

  info "Provisioning setting: adding satellite and common repos to activation key"
  hammer activation-key content-override --name=RHEL7-BASE --value=1 --organization-id=1 --content-label=rhel-7-server-satellite-tools-6-beta-rpms
  hammer activation-key content-override --name=RHEL7-BASE --value=1 --organization-id=1 --content-label=rhel-7-server-rh-common-rpms
  # hammer activation-key content-override --name=RHEL7-BASE --value=1 --organization-id=1 --content-label=rhel-7-server-rpms

  info "Provisioning setting: assigning activation key to hostgroup"
  hammer hostgroup set-parameter --hostgroup=RHEL7-Server --name=kt_activation_keys --value=RHEL7-BASE
fi
