#!/bin/sh

do_action() {
    info "Making sure default location and org belong to one another"
    hammer location add-organization --id=$LOC $ORG

    info "Making sure default domain belongs to the default location and org"
    local ID=$(hammer --csv domain list --search=name=$(hostname -d) | tail -n +2 | cut -d, -f 1)
    if [ -z "$ID" ] ; then
        warn "Unable to locate default domain: $H$(hostname -d)" 
        exit 1
    fi
    hammer domain update --id=$ID --location-ids=$LOC --organization-ids=$_ORG

    local HOSTNAME=$(hostname)
    info "Provisioning: setting default location and org for host $H$HOSTNAME"
    local MY_ID=$(hammer --csv host list --search=name=$HOSTNAME | tail -n +2 | cut -d, -f 1)
    if [ -z "$MY_ID" ] ; then
        warn "Unable to locate host-id for $H$HOSTNAME"
        exit 1
    fi
    hammer host update --id=$MY_ID --location-id=$LOC $ORG

    info "Making sure the default puppet environment has the default location and org"
    local DEFAULT_PUPPET=$(hammer --csv environment info --id=1 | tail -n +2 | cut -d, -f 2)
    if [ -z "$DEFAULT_PUPPET" ] ; then
        warn "Unable to locate puppet environment with $H--id=1"
        exit 1
    fi
    info "Setting default location and org for Default puppet environment $H$DEFAULT_PUPPET"
    hammer environment update --location-ids=$LOC --organization-ids=$_ORG --id=1

    info "Provisioning setting: subnet"
    local INTERFACE=$(ip route | grep ^default | sed 's/^.*dev \([[:alnum:]]*\) .*$/\1/')
    info "Copying subnet information from : $INTERFACE"
    T=$(nmcli c show $INTERFACE | grep ipv4\. | tr -s ' ' | sed -e 's/: \(.*\)$/="\1"/' -e 's/ipv4\./ipv4_/' -e 's/-/_/g' );
    if [ -z "$T" ] ; then
        echo "Unable to determine IP address information!"
        exit 1
    fi
    eval $T

    local DNS1=$(cut -d , -f 1 <<< "$ipv4_dns")
    local DNS2=$(cut -d , -f 2 <<< "$ipv4_dns")
    local DNS="--dns-primary=$DNS1"
    if [ -n "$DNS2" ] ; then
        DNS+=" --dns-secondary=$DNS2"
    fi
    local IP_MASK=$(tr -s ' ' <<< "${ipv4_addresses}" | cut -d ' ' -f 1 | cut -d , -f 1)
    local T=$(./ip_mask.pl $IP_MASK)
    eval $T
    local SUBNET_NAME=$(hostname -d)
    [ "$ipv4_gateway" = "__" ] && ipv4_gateway=$IP

    info "hammer subnet create --organization-ids=${_ORG} --boot-mode=Static $DNS --name=$SUBNET_NAME --network=$NETWORK --mask=$NETMASK --gateway=${ipv4_gateway}  --ipam=None --tftp-id=1"
    hammer subnet create --organization-ids=${_ORG} --boot-mode=Static $DNS --name=$SUBNET_NAME --network=$NETWORK --mask=$NETMASK --gateway=${ipv4_gateway}  --ipam=None --tftp-id=1

    info "Attaching subnet to Location"
    hammer location add-subnet --id=$LOC --subnet=$(hostname -d)

    info "Provisioning setting: activation-key"
    hammer activation-key create $ORG --name=RHEL7-BASE --content-view='RHEL7-Packages' --lifecycle-environment=production --unlimited-hosts

    info "Determining medium for kickstart"
    local LABEL=$(hammer --output=yaml organization info --id=$_ORG | grep ^Label | cut -d ' ' -f 2)
    if [ -z "$LABEL" ] ; then
        warn "Unable to locate name for organization-id: $H$_ORG"
        exit 1
    fi
    info "Looking for kickstart with patterns: $HKickstart $LABEL"
    local MEDIUM=$(hammer --csv medium list | grep Kickstart | grep $LABEL | cut -d , -f 1,2)
    if [ -z "$MEDIUM" ] ; then
        warn "Unable to locate medium for kickstart"
        exit 1
    fi
    IFS=, read ID NAME URL <<< "$MEDIUM"
    info "Found kickstart medium $H[$ID] $NAME"

    info "Provisioning setting: hostgroup"
    # not setting environment nor content-view, as that should be in the activation key
    hammer hostgroup create --name=RHEL7-Server --organization-ids=${_ORG} --architecture=x86_64 --domain=$(hostname -d) --medium-id=$ID --operatingsystem='RedHat 7.2' --partition-table='Kickstart default' --puppet-ca-proxy-id=1 --puppet-proxy-id=1 --subnet=$(hostname -d) --root-pass=redhat123

    info "Provisioning setting: adding subscriptions to activation key"
    local SUBSCRIPTION_ID=$(hammer --output=csv subscription list --organization-id=1 | awk -F, '/,Employee SKU,/ {print $1}')
    hammer activation-key add-subscription ${ORG} --name=RHEL7-BASE --subscription-id=$SUBSCRIPTION_ID

    info "Provisioning setting: adding satellite and common repos to activation key"
    if [ -n "$BETA" ] ; then
        hammer activation-key content-override --name=RHEL7-BASE --value=1 ${ORG} --content-label=rhel-7-server-satellite-tools-6-beta-rpms
    else
        hammer activation-key content-override --name=RHEL7-BASE --value=1 ${ORG} --content-label=rhel-7-server-satellite-tools-6.2-rpms
    fi
    hammer activation-key content-override --name=RHEL7-BASE --value=1 ${ORG} --content-label=rhel-7-server-rh-common-rpms

    info "Provisioning setting: assigning activation key to hostgroup"
    hammer hostgroup set-parameter --hostgroup=RHEL7-Server --name=kt_activation_keys --value=RHEL7-BASE

    info "Remastering PXE-less discovery image"
    local ISO=$(rpm -ql foreman-discovery-image | grep iso$)
    if [ -r "$ISO" ] ; then
      local DN=$(dirname $ISO)
      local BN=$(basename $ISO)
      local DST="$DN/auto-$BN"
      if [ -r $DST ] ; then
        info "$DST already exists!"
      else
	discovery-remaster "$ISO" "proxy.url=https://$HOSTNAME:9090 proxy.type=proxy fdi.pxauto=1" "$DST" >/tmp/l 2>&1
	[ -r $DST ] && info "Stored in $H$DN/auto-$BN" || cat /tmp/l
      fi
    else
      warn "Unable to locate iso for foreman-discovery-image"
    fi
}
