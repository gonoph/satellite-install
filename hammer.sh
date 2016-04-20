#!/bin/sh

CDN="https://cdn.redhat.com"
# hammer subscription upload --file /root/manifest_2016-04-15.zip --organization-id 1

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

## RHEL Repos
PRODUCT='--product=Red Hat Enterprise Linux Server'
ORG="--organization-id=1"
RELEASE="--releasever=7Server"
BASEARCH="--basearch=x86_64"
hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Enterprise Linux 7 Server (RPMs)'
hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Enterprise Linux 7 Server - Optional (RPMs)'
hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE"
hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Enterprise Linux 7 Server (Kickstart)'
hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Enterprise Linux 7 Server - RH Common (RPMs)'
hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'RHN Tools for Red Hat Enterprise Linux 7 Server (RPMs)'
hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Enterprise Linux 7 Server - Supplementary (RPMs)'
hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Storage Native Client for RHEL 7 (RPMs)'
RELEASE=""
hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Enterprise Linux 7 Server - Extras (RPMs)'
hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Satellite Tools 6.1 (for RHEL 7 Server) (RPMs)'

## Add more repos and products
ORG="--organization-id=1"
hammer product create ${ORG} --name='Forge'
hammer repository create ${ORG} --name='Puppet Forge' --product='Forge' --content-type='puppet' --publish-via-http=true --url=https://forge.puppetlabs.com

hammer product create ${ORG} --name='EPEL'
hammer repository create ${ORG} --name='EPEL 7 - x86_64' --product='EPEL' --content-type='yum' --publish-via-http=true --url=http://dl.fedoraproject.org/pub/epel/7/x86_64/

## Add a sync plan
ORG="--organization-id=1"
hammer sync-plan create --interval=daily --name='Daily sync' ${ORG} --enabled=yes
hammer sync-plan list ${ORG}


## add stuff to the sync plan
ORG="--organization-id=1"
hammer product set-sync-plan --sync-plan-id=1 ${ORG} --name='Red Hat Enterprise Linux Server'
hammer product set-sync-plan --sync-plan-id=1 ${ORG} --name='Forge'
hammer product set-sync-plan --sync-plan-id=1 ${ORG} --name='EPEL'

# Create a content view for RHEL 7 server x86_64:
hammer content-view create --name='rhel-7-server-x86_64-cv' ${ORG}
for i in $(hammer --csv repository list ${ORG} | awk -F, {'print $1'} | grep -vi '^ID'); do
	hammer content-view add-repository --name='rhel-7-server-x86_64-cv' ${ORG} --repository-id=${i}
done
