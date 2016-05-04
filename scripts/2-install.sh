#!/bin/bash

: ${BETA:=}
: ${UN:=admin}
: ${PW:=redhat123}
: ${L:=Home}
: ${O:=Test62}

[ -n "$BETA" ] && echo -e "\e[1;31mBETA Mode on\e[0m"  || echo -e "\e[1;34mBETA MODE off\e[0m"
# this is the beta form of the install command
beta_install() {
  foreman-installer --scenario katello \
    --foreman-admin-username $UN \
    --foreman-admin-password $PW \
    --capsule-puppet true \
    --foreman-proxy-puppetca true \
    --foreman-proxy-tftp true \
    --enable-foreman-plugin-discovery \
    --foreman-initial-location $L \
    --foreman-initial-organization $O
}

# this is the actual release version
release_install() {
  katello-installer \
    --foreman-admin-password=$PW \
    --foreman-admin-username=$UN \
    --foreman-initial-location=$L \
    --foreman-initial-organization=$O \
    --capsule-tftp=true
}

if [ -n "$BETA" ] ; then
  beta_install
else
  release_install
fi
