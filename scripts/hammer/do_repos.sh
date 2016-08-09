#!/bin/sh

do_action() {
    info "Enabling repos for $H$PRODUCT"
    hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Enterprise Linux 7 Server (RPMs)'
    hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Enterprise Linux 7 Server (Kickstart)'
    hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Enterprise Linux 7 Server - RH Common (RPMs)'
    info "Enabling extra repos"
    RELEASE=""
    hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Enterprise Linux 7 Server - Extras (RPMs)'
    if [ -n "$BETA" ] ; then
        info "Enabling satellite tools beta"
        hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Satellite Tools 6 Beta (for RHEL 7 Server) (RPMs)'
    else
        info "Enabling satellite tools 6.2"
        hammer_enable "$ORG" "$PRODUCT" "$BASEARCH" "$RELEASE" 'Red Hat Satellite Tools 6.2 (for RHEL 7 Server) (RPMs)'
    fi
    exit
}
