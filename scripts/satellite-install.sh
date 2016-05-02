#!/bin/sh

beta_install() {
  foreman-installer --scenario katello \
    --foreman-admin-username admin \
    --foreman-admin-password redhat123 \
    --capsule-puppet true \
    --foreman-proxy-tftp true \
    --foreman-admin-email biholmes@redhat.com \
    --foreman-admin-first-name Billy \
    --foreman-admin-last-name Holmes
    #--capsule-puppet-ca-proxy true \
}

release_install() {
  katello-installer \
    --foreman-admin-email=biholmes@redhat.com \
    --foreman-admin-first-name=Billy \
    --foreman-admin-last-name=Holmes \
    --foreman-admin-password=redhat123 \
    --foreman-admin-username=admin \
    --foreman-initial-location=Home \
    --foreman-initial-organization=Test62 \
    --capsule-tftp=true
}

beta_install
