#!/bin/sh

do_action() {
    info "Uploading manifest info $H$(hostname)"
    local FILE=$2
    : ${FILE:=/tmp/manifest.zip}
    while [ ! -r $FILE ] ; do
        warn "Unable to read: $H$FILE"
        # if it's not interactive then exit
        [ -n "$2" ] && exit 1
        read -ep "Path to manifest: " -i "$FILE" FILE
        if [ "$(basename $FILE .zip)" = "$FILE" ] ; then
            warn "File doesn't have .zip extension: $H$FILE"
            FILE=$(rev <<< "$FILE" | cut -d . -f 2- | rev)
        fi
    done
    hammer subscription delete-manifest $ORG
    hammer subscription upload --file "$FILE" $ORG
    hammer subscription list $ORG
    exit
}
