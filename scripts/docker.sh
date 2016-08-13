#!/bin/sh
# vim: sw=2 ai

# load scripts
_BASE=$(dirname `realpath $BASH_SOURCE`)
source $_BASE/../0-bootstrap.sh

set -e

: ${BETA:=}
: ${ORG:=1}
: ${LOC:=2}

_ORG=$ORG
ORG="--organization-id=$ORG"

## RHEL Repos
PRODUCT='--product=Red Hat Enterprise Linux Server'
RELEASE="--releasever=7Server"
BASEARCH="--basearch=x86_64"

CV_NAME=Docker
MONTHS_AGO=12
MONTHS_ADD=4

source $_BASE/hammer/do_view.sh

do_action() {
  views
  errata
}

create_all_filters() {
  remove_filters
  create_filter Includes rpm docker
  create_filter_rule docker
  create_filter_rule katello-agent

  create_filter Excludes erratum
  create_filter_rule
  hammer content-view filter remove-repository $ORG --content-view=$CV_NAME --name='Excludes of erratum by date' --repository='Red Hat Satellite Tools 6.2 for RHEL 7 Server RPMs x86_64' "$PRODUCT"
}

do_action
