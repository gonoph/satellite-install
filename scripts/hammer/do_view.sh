#!/bin/sh
# vim: sw=2 ai

views() {
    local PRODUCT="--product=Red Hat Enterprise Linux Server"
    info "Creating content view for $H$PRODUCT"
    # Create a content view for RHEL 7 server x86_64:
    hammer content-view create --name='RHEL7-Packages' ${ORG}
    hammer --csv repository list ${ORG} "${PRODUCT}"  --search 'name !~ kickstart' | tail -n +2 | while IFS="," read ID NAME TMP ; do
      info " Attaching $H$NAME"
      hammer content-view add-repository --name='RHEL7-Packages' ${ORG} --repository-id=${ID}
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
  hammer --csv content-view filter list --content-view RHEL7-Packages $ORG | tail -n +2 | while IFS=, read ID NAME TMP ; do
    info "Removing $H$NAME$h; id=$H$ID"
    hammer content-view filter delete --id=$ID
  done
}

create_filters() {
  info "Creating filter for errata"
  remove_filters
  local CV="--content-view=RHEL7-Packages"

  info "#### Adding$H exclude$h filter"
  info "- Exclude$H docker errata"
  local CVF="Exclude Kernel errata"
  hammer content-view filter create $CV $ORG --name "$CVF" --type rpm --description "Exclude all docker errata" --inclusion false
  local CVF="--content-view-filter=$CVF"
  info "--- Adding filter rule$H by rpm$h for package$H docker*"
  hammer content-view filter rule create $CV $ORG "$CVF" --name "docker*"
  info "- Exclude$H errata$h since last month"
  local CVF="Exclude errata since"
  hammer content-view filter create $CV $ORG --name "$CVF" --type erratum --description "Exclude errata up till date" --inclusion false
  info "--- Adding filter rule$H by date$h for errata since"
  local CVF="--content-view-filter=$CVF"
  hammer content-view filter rule create $CV $ORG "$CVF" --start-date "$DATE" --types enhancement,bugfix,security

  info "Publishing view"
  hammer content-view publish --name "RHEL7-Packages" --description "Since $DATE" $ORG
}

promote_version() {
  info "Determing version"
  local VERSION=$( hammer --csv content-view version list $ORG --content-view=RHEL7-Packages | tail -n +2 | sort -t , -k 3 -n | tail -n 1 | cut -d, -f 3 )
  [ -n "$VERSION" ] || err "Unable to determine content view version"
  warn VERSION=$VERSION
  info "Promoting version $H$VERSION$h to lifecycle environments: $H""$@"
  for i in $@ ; do
    info "Promoting to $i"
    hammer content-view version promote --content-view "RHEL7-Packages" --version $VERSION --to-lifecycle-environment "$i" $ORG
  done
}

errata() {
  DATE=$(date -d "4 months ago" +%Y-%m-01)
  create_filters $DATE
  promote_version Development Testing Production
  DATE=$(date -d "3 months ago" +%Y-%m-01)
  create_filters $DATE
  promote_version Development Testing
  DATE=$(date -d "2 months ago" +%Y-%m-01)
  create_filters $DATE
  promote_version Development
  DATE=$(date -d "1 months ago" +%Y-%m-01)
  create_filters $DATE
}

do_action() {
  views
  environments
  errata
}
