#!/bin/sh

do_action() {
    info "Creating sync plan for daily syncs"
    hammer sync-plan create --interval=daily --name='Daily sync' ${ORG} --enabled=yes --sync-date=$(date +%Y-%m-%d)
    hammer sync-plan list ${ORG}

    info "Adding all repos to the sync plan"
    ## add stuff to the sync plan
    hammer --csv product list ${ORG} | tail -n +2 | while IFS=, read P_ID NAME J1 J2 REPOS J3 ; do
        if [ $REPOS -gt 0 ] ; then
            info "Adding: $NAME"
            hammer product set-sync-plan --sync-plan-id=1 ${ORG} --name="$NAME"
        fi
    done
    local PRODUCT="Red Hat Enterprise Linux Server"
    info "Must synchronize kickstart before anything else for: $H$PRODUCT"
    local AVAIL=$(hammer --csv repository list ${ORG} --product="$PRODUCT" | tail -n +2 | grep -i kickstart | tail -n 1) # there can be only one
    if [ -z "$AVAIL" ] ; then
        warn "Unable to find kickstart repository! Have you: $HUploaded manifests or created repos?"
        exit 1
    fi
    IFS=, read ID NAME PROD TYPE URI <<< "$AVAIL"
    info "Synchronizing: $H$NAME"
    hammer repository synchronize --product="$PROD" ${ORG} --id=$ID

    info "Synchronizing all the other repos for: $H$PRODUCT"
    # the reason for this strange create-a-script is due to hammer trying to access the tty via stty, and spamming the console with stty errors
    >/tmp/l
    hammer --csv repository list ${ORG} --product="$PRODUCT" | tail -n +2 | grep -v -i kickstart | while IFS=, read ID NAME PROD TYPE URI ; do
        echo 'cat<<EOF' >> /tmp/l
        info "   Syncing: $H$NAME" >> /tmp/l
        echo 'EOF' >> /tmp/l
        echo "hammer repository synchronize --product='$PROD' '${ORG}' --id=$ID" >> /tmp/l
    done
    if [ -s /tmp/l ] ; then
        chmod +x /tmp/l && /tmp/l
    else
        warn "Unable to find other repos to synchronize!"
    fi
}
