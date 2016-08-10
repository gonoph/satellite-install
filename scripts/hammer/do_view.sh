#!/bin/sh
# vim: sw=2 ai

: ${CV_NAME:-RHEL7-Packages}
: ${MONTHS_AGO:-4}
: ${MONTHS_ADD:-1}
views() {
    local PRODUCT="--product=Red Hat Enterprise Linux Server"
    info "Creating content view for $H$PRODUCT$h called $H$CV_NAME"
    # Create a content view for RHEL 7 server x86_64:
    hammer content-view create --name="$CV_NAME" ${ORG}
    hammer --csv repository list ${ORG} "${PRODUCT}"  --search 'name !~ kickstart' | tail -n +2 | while IFS="," read ID NAME TMP ; do
      info " Attaching $H$NAME"
      hammer content-view add-repository --name="$CV_NAME" ${ORG} --repository-id=${ID}
    done
 }

environments() {
    local PRIOR=Library
    for i in "Development:Development Testing Team" "Testing:Quality Engineering Team" "Production:Product Releases" ; do
      _IFS=$IFS
      IFS=:
      set $i
      IFS=$_IFS
      local LABEL="$1 Environment for $2"
      info "Creating Environment: $H$LABEL"
      hammer lifecycle-environment create --name "$1" --description "$LABEL" --prior "$PRIOR" $ORG
      PRIOR=$1
    done
}

remove_filters() {
  info "Removing old filters"
  hammer --csv content-view filter list --content-view="$CV_NAME" $ORG | tail -n +2 | while IFS=, read ID NAME TMP ; do
    info "Removing $H$NAME$h; id=$H$ID"
    hammer content-view filter delete --id=$ID
  done
}

create_filter() {
  local INCLUSION=$1
  local TYPE=$2
  local PACKAGE=$3
  local TYPE_FLAG="--type=$TYPE"
  local CV_FLAG="--content-view=$CV_NAME"
  local INCLUSION_FLAG
  local NAME_FLAG
  [ $INCLUSION = "Includes" ] && INCLUSION_FLAG="--inclusion=true" || INCLUSION_FLAG="--inclusion=false"
  CVF="$INCLUSION of $TYPE"
  [ "$PACKAGE" = "" ] && CVF+=" by date" || CVF+=" by $PACKAGE"
  NAME_FLAG="--name=$CVF"

  info "Creating $H$CVF$h for content-view $H$CV_NAME$h"
  hammer content-view filter create "$CV_FLAG" $ORG "$NAME_FLAG" "$TYPE_FLAG" --description="$CVF" $INCLUSION_FLAG
}

create_filter_rule() {
  local PACKAGE=$1
  local NAME_FLAG
  local DATE_FLAG
  local TYPES_FLAG
  local CV_FLAG="--content-view=$CV_NAME"
  local CVF_FLAG="--content-view-filter=$CVF"
  set -- hammer content-view filter rule create "$CV_FLAG" $ORG "$CVF_FLAG"
  if [ "$PACKAGE" = "" ] ; then
    set -- "$@" --start-date=$DATE --types enhancement,bugfix,security
    info "++ Adding rule for $H$CVF$h using $H$DATE"
 else
   set -- "$@" --name="$PACKAGE*"
   info "++ Adding rule for $H$CVF$h"
  fi
  "$@"
}

create_all_filters() {
  remove_filters
  create_filter Excludes rpm docker
  create_filter_rule docker

  create_filter Excludes erratum
  create_filter_rule
}

update_filters() {
  info "Creating filters for $H$CV_NAME"
  create_all_filters
  info "Publishing view"
  hammer content-view publish --name="$CV_NAME" --description "Since $DATE" $ORG
}

promote_version() {
  info "Determing version"
  local VERSION=$( hammer --csv content-view version list $ORG --content-view="$CV_NAME" | tail -n +2 | sort -t , -k 3 -n | tail -n 1 | cut -d, -f 3 )
  [ -n "$VERSION" ] || err "Unable to determine content view version"
  warn VERSION=$VERSION
  info "Promoting version $H$VERSION$h to lifecycle environments: $H""$@"
  for i in $@ ; do
    info "Promoting to $i"
    hammer content-view version promote --content-view="$CV_NAME" --version $VERSION --to-lifecycle-environment "$i" $ORG
  done
}

errata() {
  DATE=$(date -d "$MONTHS_AGO months ago" +%Y-%m-01)
  update_filters $DATE
  promote_version Development Testing Production
  MONTHS_AGO=$[ $MONTHS_AGO - $MONTHS_ADD ]
  DATE=$(date -d "$MONTHS_AGO months ago" +%Y-%m-01)
  update_filters $DATE
  promote_version Development Testing
  MONTHS_AGO=$[ $MONTHS_AGO - $MONTHS_ADD ]
  DATE=$(date -d "$MONTHS_AGO months ago" +%Y-%m-01)
  update_filters $DATE
  promote_version Development
  MONTHS_AGO=$[ $MONTHS_AGO - $MONTHS_ADD ]
  DATE=$(date -d "$MONTHS_AGO months ago" +%Y-%m-01)
  update_filters $DATE
}

do_action() {
  views
  environments
  errata
}
