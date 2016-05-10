#!/bin/bash

: ${BETA:=}
: ${SAT_USER:=admin}
: ${SAT_PASS:=redhat123}
: ${LOCATION:=Home}
: ${ORGANIZATION:=Test62}

[ -n "$BETA" ] && echo -e "\e[1;31mBETA Mode on\e[0m"  || echo -e "\e[1;34mBETA MODE off\e[0m"
# this is the beta form of the install command
beta_install() {
  foreman-installer --scenario katello \
    --foreman-admin-username $SAT_USER \
    --foreman-admin-password $SAT_PASS \
    --capsule-puppet true \
    --foreman-proxy-puppetca true \
    --foreman-proxy-tftp true \
    --enable-foreman-plugin-discovery \
    --foreman-initial-location $LOCATION \
    --foreman-initial-organization $ORGANIZATION
}

# this is the actual release version
release_install() {
  katello-installer \
    --foreman-admin-password=$SAT_PASS \
    --foreman-admin-username=$SAT_USER \
    --foreman-initial-location=$LOCATION \
    --foreman-initial-organization=$ORGANIZATION \
    --capsule-tftp=true
}

if [ -n "$BETA" ] ; then
  beta_install
else
  release_install
fi
