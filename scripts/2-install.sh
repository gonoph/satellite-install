#!/bin/sh

# this is the beta form of the install command
beta_install() {
  foreman-installer --scenario katello \
    --foreman-admin-username admin \
    --foreman-admin-password redhat123 \
    --capsule-puppet true \
    --foreman-proxy-puppetca true \
    --foreman-proxy-tftp true \
    --enable-foreman-plugin-discovery \
    --foreman-initial-location Home \
    --foreman-initial-organization Test62
}

# this is the actual release version
release_install() {
  katello-installer \
    --foreman-admin-password=redhat123 \
    --foreman-admin-username=admin \
    --foreman-initial-location=Home \
    --foreman-initial-organization=Test62 \
    --capsule-tftp=true
}

beta_install
