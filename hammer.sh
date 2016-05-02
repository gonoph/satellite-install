#!/bin/sh

CDN="https://cdn.redhat.com"
ORG="--organization-id=1"
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

case $1 in
	--help|-h)
		cat<<EOF
usage: $0 (all | -h | --help | repos | satellite | repos-extra | sync | view | publish)
EOF
	exit 1
	;;
esac

SECTION=$1
: ${SECTION:=all}

## RHEL Repos
PRODUCT='--product=Red Hat Enterprise Linux Server'
RELEASE="--releasever=7Server"
BASEARCH="--basearch=x86_64"

if [ "$SECTION" = "all" -o "$SECTION" = "repos" ] ; then
hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Enterprise Linux 7 Server (Kickstart)'
hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Enterprise Linux 7 Server (RPMs)'
hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Enterprise Linux 7 Server - Optional (RPMs)'
hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Enterprise Linux 7 Server - RH Common (RPMs)'
hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Enterprise Linux 7 Server - Supplementary (RPMs)'
hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Storage Native Client for RHEL 7 (RPMs)'
hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'RHN Tools for Red Hat Enterprise Linux 7 Server (RPMs)'
RELEASE=""
hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Enterprise Linux 7 Server - Extras (RPMs)'
hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Satellite Tools 6.1 (for RHEL 7 Server) (RPMs)'
fi

if [ "$SECTION" = "all" -o "$SECTION" = "satellite" ] ; then
RELEASE=""
PRODUCT='--product=Red Hat Satellite'
hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Satellite 6.1 (for RHEL 7 Server) (RPMs)'
PRODUCT='--product=Red Hat Satellite 6 Beta'
hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Satellite 6 Beta (for RHEL 7 Server) (RPMs)'
fi

## Add more repos and products
ORG="--organization-id=1"

if [ "$SECTION" = "all" -o "$SECTION" = "repos-extra" ] ; then
hammer product create ${ORG} --name='Forge'
hammer repository create ${ORG} --name='Puppet Forge' --product='Forge' --content-type='puppet' --publish-via-http=true --url=https://forge.puppetlabs.com

hammer product create ${ORG} --name='EPEL'
hammer repository create ${ORG} --name='EPEL 7 - x86_64' --product='EPEL' --content-type='yum' --publish-via-http=true --url=http://dl.fedoraproject.org/pub/epel/7/x86_64/

hammer product create ${ORG} --name='Fedora'
hammer repository create ${ORG} --name='Fedora 22 - x86_64' --product='Fedora' --content-type='yum' --publish-via-http=true --url=http://dl.fedoraproject.org/pub/fedora/linux/releases/22/Everything/x86_64/os/
hammer repository create ${ORG} --name='Fedora 23 - x86_64' --product='Fedora' --content-type='yum' --publish-via-http=true --url=http://dl.fedoraproject.org/pub/fedora/linux/releases/23/Everything/x86_64/os/

hammer repository create ${ORG} --name='Fedora 22 Updates - x86_64' --product='Fedora' --content-type='yum' --publish-via-http=true --url=http://dl.fedoraproject.org/pub/fedora/linux/updates/22/x86_64/
hammer repository create ${ORG} --name='Fedora 23 Updates - x86_64' --product='Fedora' --content-type='yum' --publish-via-http=true --url=http://dl.fedoraproject.org/pub/fedora/linux/updates/23/x86_64/

fi

## Add a sync plan
ORG="--organization-id=1"

if [ "$SECTION" = "all" -o "$SECTION" = "sync" ]; then
hammer sync-plan create --interval=daily --name='Daily sync' ${ORG} --enabled=yes
hammer sync-plan list ${ORG}

## add stuff to the sync plan
hammer product set-sync-plan --sync-plan-id=1 ${ORG} --name='Red Hat Enterprise Linux Server'
hammer product set-sync-plan --sync-plan-id=1 ${ORG} --name='Forge'
hammer product set-sync-plan --sync-plan-id=1 ${ORG} --name='EPEL'
hammer product set-sync-plan --sync-plan-id=1 ${ORG} --name='Fedora'
hammer product set-sync-plan --sync-plan-id=1 ${ORG} --name='Red Hat Satellite'
hammer product set-sync-plan --sync-plan-id=1 ${ORG} --name='Red Hat Satellite 6 Beta'
fi

if [ "$SECTION" = "all" -o "$SECTION" = "view" ] ; then
# Create a content view for RHEL 7 server x86_64:
hammer content-view create --name='rhel-7-server-x86_64-cv' ${ORG}
for i in $(hammer --csv repository list ${ORG} | awk -F, {'print $1'} | grep -vi '^ID'); do
	hammer content-view add-repository --name='rhel-7-server-x86_64-cv' ${ORG} --repository-id=${i}
done
fi
if [ "$SECTION" = "all" -o "$SECTION" = "publish" ] ; then
hammer content-view publish --name="rhel-7-server-x86_64-cv" ${ORG} --async
fi
