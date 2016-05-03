#!/bin/sh

set -e 

register_system() {

  if [ -z "$RH_ACTIVATION_KEY" ] || [ -z "$RH_ORG_ID" ] ; then
    echo "Needed environment variables not set!"
    echo
    echo "RH_ACTIVATION_KEY - Red Hat Portal Activiation Key"
    echo "You can create an Activiation Key via https://access.redhat.com/management/activation_keys"
    echo
    echo "RH_ORG_ID - Your Red Hat Organization Id"
    echo "You can find this by running the following on a portal registered system: "
    echo "	subscription-manager identity"
    exit 1
  fi

  subscription-manager register --activationkey=${RH_ACTIVATION_KEY} --org=${RH_ORG_ID}
}

subscription-manager identity || register_system
subscription-manager release --set=7Server
subscription-manager repos --disable "*"
subscription-manager repos --enable rhel-7-server-rpms --enable rhel-7-server-rh-common-rpms
yum install -y screen git vim

git clone http://git/git/satellite-install.git
