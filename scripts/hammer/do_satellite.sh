#!/bin/sh

do_action() {
    RELEASE=""
    if [ -z "$BETA" ] ; then
        info "Enabling satellite repos for 6.2"
        PRODUCT='--product=Red Hat Satellite'
        hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Satellite 6.2 (for RHEL 7 Server) (RPMs)'
    else
        info "Enabling satellite beta repos"
        PRODUCT='--product=Red Hat Satellite 6 Beta'
        hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Satellite 6 Beta (for RHEL 7 Server) (RPMs)'
    fi
}
