#!/bin/sh

: ${BETA:=}
: ${ORG:=1}
: ${LOC:=2}

_ORG=$ORG
ORG="--organization-id=$ORG"

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
    hammer subscription delete-manifest $ORG
    hammer subscription upload --file "$FILE" $ORG
    hammer subscription list $ORG
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

if [ "$SECTION" = "all" -o "$SECTION" = "sync" ]; then
    info "Creating sync plan for daily syncs"
    hammer sync-plan create --interval=daily --name='Daily sync' ${ORG} --enabled=yes --sync-date=$(date +%Y-%m-%d)
    hammer sync-plan list ${ORG}

    info "Adding all repos to the sync plan"
    ## add stuff to the sync plan
    hammer --csv product list ${ORG} | tail -n +2 | while IFS=, read P_ID NAME J1 J2 REPOS J3 ; do
        if [ $REPOS -gt 0 ] ; then
            info "Adding: $NAME"
            hammer product set-sync-plan --sync-plan-id=1 ${ORG} --name="$NAME"
        fi
    done
    PRODUCT="Red Hat Enterprise Linux Server"
    info "Must synchronize kickstart before anything else for: \e[1m$PRODUCT"
    AVAIL=$(hammer --csv repository list ${ORG} --product="$PRODUCT" | tail -n +2 | grep -i kickstart)
    if [ -z "$AVAIL" ] ; then
        warn "Unable to find kickstart repository! Have you: \e[1mUploaded manifests or created repos?"
        exit 1
    fi
    IFS=, read ID NAME PROD TYPE URI <<< "$AVAIL"
    info "Synchronizing: \e[1m$NAME"
    hammer repository synchronize --product="$PROD" ${ORG} --id=$ID

    info "Synchronizing all the other repos for: \e[1m$PRODUCT"
    # the reason for this strange create-a-script is due to hammer trying to access the tty via stty, and spamming the console with stty errors
    >/tmp/l
    hammer --csv repository list ${ORG} --product="$PRODUCT" | tail -n +2 | grep -v -i kickstart | while IFS=, read ID NAME PROD TYPE URI ; do
        echo -n 'echo ' >> /tmp/l
        info "   Syncing: \e[1m$NAME" >> /tmp/l
        echo "hammer repository synchronize --product='$PROD' '${ORG}' --id=$ID" >> /tmp/l
    done
    if [ -s /tmp/l ] ; then
        chmod +x /tmp/l && /tmp/l
    else
        warn "Unable to find other repos to synchronize!"
    fi
fi

if [ "$SECTION" = "all" -o "$SECTION" = "view" ] ; then
    PRODUCT="--product=Red Hat Enterprise Linux Server"
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
    INTERFACE=$(ip route | grep ^default | sed 's/^.*dev \([[:alnum:]]*\) .*$/\1/')
    info "Copying subnet information from : $INTERFACE"
    T=$(nmcli c show $INTERFACE | grep ipv4\. | tr -s ' ' | sed -e 's/: \(.*\)$/="\1"/' -e 's/ipv4\./ipv4_/' -e 's/-/_/g' );
    if [ -z "$T" ] ; then
        echo "Unable to determine IP address information!"
        exit 1
    fi
    eval $T

    DNS1=$(cut -d , -f 1 <<< "$ipv4_dns")
    DNS2=$(cut -d , -f 2 <<< "$ipv4_dns")
    DNS="--dns-primary=$DNS1"
    if [ -n "$DNS2" ] ; then
        DNS+=" --dns-secondary=$DNS2"
    fi
    IP_MASK=$(tr -s ' ' <<< "${ipv4_addresses}" | cut -d ' ' -f 1 | cut -d , -f 1)
    T=$(./ip_mask.pl $IP_MASK)
    eval $T
    SUBNET_NAME=$(hostname -d)

    info "hammer subnet create --organization-ids=${_ORG} --boot-mode=Static $DNS --name=$SUBNET_NAME --network=$NETWORK --mask=$NETMASK --gateway=${ipv4_gateway}  --ipam=None --tftp-id=1"
    hammer subnet create --organization-ids=${_ORG} --boot-mode=Static $DNS --name=$SUBNET_NAME --network=$NETWORK --mask=$NETMASK --gateway=${ipv4_gateway}  --ipam=None --tftp-id=1

    info "Attaching subnet to Location"
    hammer location add-subnet --id=$LOC --subnet=$(hostname -d)

    info "Provisioning setting: activation-key"
    hammer activation-key create $ORG --name=RHEL7-BASE --content-view='Default Organization View' --lifecycle-environment=Library --unlimited-content-hosts

    info "Determining medium for kickstart"
    LABEL=$(hammer --output=yaml organization info --id=$_ORG | grep ^Label | cut -d ' ' -f 2)
    if [ -z "$LABEL" ] ; then
        warn "Unable to locate name for organization-id: \e[1m$_ORG"
        exit 1
    fi
    info "Looking for kickstart with patterns: \e[1mKickstart $LABEL"
    MEDIUM=$(hammer --csv medium list | grep Kickstart | grep $LABEL | cut -d , -f 1,2)
    if [ -z "$MEDIUM" ] ; then
        warn "Unable to locate medium for kickstart"
        exit 1
    fi
    IFS=, read ID NAME URL <<< "$MEDIUM"
    info "Found kickstart medium \e[1m[$ID] $NAME"

    info "Provisioning setting: hostgroup"
    hammer hostgroup create --organization-ids=${_ORG} --architecture=x86_64 --domain=$(hostname -d) --environment=production --medium-id=$ID --operatingsystem='RedHat 7.2' --partition-table='Kickstart default' --puppet-ca-proxy-id=1 --puppet-proxy-id=1 --subnet=$(hostname -d) --root-pass=redhat123

    info "Provisioning setting: adding subscriptions to activation key"
    SUBSCRIPTION_ID=$(hammer --output=csv subscription list ${ORG} | awk -F, '/^Employee/ {print $8}')
    hammer activation-key add-subscription ${ORG} --name=RHEL7-BASE --subscription-id=$SUBSCRIPTION_ID

    info "Provisioning setting: adding satellite and common repos to activation key"
    if [ -n "$BETA" ] ; then
        hammer activation-key content-override --name=RHEL7-BASE --value=1 ${ORG} --content-label=rhel-7-server-satellite-tools-6-beta-rpms
    else
        hammer activation-key content-override --name=RHEL7-BASE --value=1 ${ORG} --content-label=rhel-7-server-satellite-tools-6.1-rpms
    fi
    hammer activation-key content-override --name=RHEL7-BASE --value=1 ${ORG} --content-label=rhel-7-server-rh-common-rpms

    info "Provisioning setting: assigning activation key to hostgroup"
    hammer hostgroup set-parameter --hostgroup=RHEL7-Server --name=kt_activation_keys --value=RHEL7-BASE
fi
