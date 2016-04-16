#!/bin/sh

yum -y install katello-installer

katello-installer \
  --foreman-admin-email=biholmes@redhat.com \
  --foreman-admin-first-name=Billy \
  --foreman-admin-last-name=Holmes \
  --foreman-admin-password=redhat123 \
  --foreman-admin-username=admin \
  --foreman-initial-location=Home \
  --foreman-initial-organization=Gonoph.Net \
  --capsule-tftp=true
