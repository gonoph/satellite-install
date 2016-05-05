#!/bin/sh

set -e 

register_system() {
  if [ -n "$RH_OLD_SYSTEM" ] && [ -n "$RH_USER" ] ; then
    subscription-manager register --consumerid=$RH_OLD_SYSTEM --username=$RH_USER
    return
  fi
  if [ -n "$RH_ACTIVATION_KEY" ] && [ -n $RH_ORG_ID ] ; then
    subscription-manager register --activationkey=${RH_ACTIVATION_KEY} --org=${RH_ORG_ID}
    return
  fi
  cat<<EOF
Needed environment variables not set!

If you want to reuse an existing system:

1) Log into the portal: https://access.redhat.com/management/consumers?type=system
2) Find the old system, copy it's UUID (ex: ad88c818-7777-4370-8878-2f1315f7177a)
3) Set these ENV variables:

	RH_OLD_SYSTEM=ad88c818-7777-4370-8878-2f1315f7177a
	RH_USER=biholmes

However, if you want to use an activation key, you need to do this:

1) On an exsting system, find your Red Hat Organization Id:
2) Log in and run: subscription-manager identity
3) Setup an activation key via: https://access.redhat.com/management/activation_keys
4) Set these ENV variables:

	RH_ACTIVATION_KEY=MY_COOL_KEY
	RH_ORG_ID=31337

EOF
  exit 1
}

subscription-manager identity || register_system
subscription-manager release --set=7Server
subscription-manager repos --disable "*"
subscription-manager repos --enable rhel-7-server-rpms --enable rhel-7-server-rh-common-rpms
yum install -y screen git vim

git clone http://git/git/satellite-install.git
