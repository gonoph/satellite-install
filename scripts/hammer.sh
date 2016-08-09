#!/bin/sh
# Satellite-install hammer script - to configure a satellite server for provisioning
# Copyright (C) 2016  Billy Holmes <billy@gonoph.net>
# 
# This file is part of Satellite-install.
# 
# Satellite-install is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
# 
# Satellite-install is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
# 
# You should have received a copy of the GNU General Public License along with
# Satellite-install.  If not, see <http://www.gnu.org/licenses/>.

BASEURL=
# load scripts
_BASE=$(dirname `realpath $BASH_SOURCE`)
source $_BASE/../0-bootstrap.sh

: ${BETA:=}
: ${ORG:=1}
: ${LOC:=2}

_ORG=$ORG
ORG="--organization-id=$ORG"

## RHEL Repos
PRODUCT='--product=Red Hat Enterprise Linux Server'
RELEASE="--releasever=7Server"
BASEARCH="--basearch=x86_64"

## Enable some repos
function hammer_enable() {
    local ORG="$1"
    local PRODUCT="$2"
    local BASEARCH="$3"
    local RELEASE="$4"
    local NAME="$5"
    local ARGS
    [ -n "$BASEARCH" ] && ARGS+=" $BASEARCH"
    [ -n "$RELEASE" ] && ARGS+=" $RELEASE"
    hammer repository-set enable "${ORG}" "${PRODUCT}" $ARGS --name="$NAME"
}

SECTION=$1
: ${SECTION:=-h}

case $SECTION in
    --help|-h)
        cat<<EOF
usage: $0 (manifest (FILE) | all | -h | --help | repos | satellite | repos-extra | sync | view | provisioning)
EOF
        exit 1 ;;
    manifest)
	source $_BASE/hammer/do_manifest.sh
	do_action
	exit 0 ;;
    repos)
	source $_BASE/hammer/do_repos.sh
	do_action
	exit 0 ;;
    satellite)
	source $_BASE/hammer/do_satellite.sh
	do_action
	exit 0 ;;
    repos-extra)
	source $_BASE/hammer/do_repos-extra.sh
	do_action
	exit 0 ;;
    sync)
	source $_BASE/hammer/do_sync.sh
	do_action
	exit 0 ;;
    view)
	source $_BASE/hammer/do_view.sh
	do_action
	exit 0 ;;
    provisioning)
	source $_BASE/hammer/do_provisioning.sh
	do_action
	exit 0 ;;
esac
