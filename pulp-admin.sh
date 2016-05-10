#!/bin/sh

LOGIN=$(grep ^default_login /etc/pulp/server.conf  | cut -d ' ' -f 2)
PASS=$(grep ^default_pass /etc/pulp/server.conf  | cut -d ' ' -f 2)

exec pulp-admin -u "$LOGIN" -p "$PASS" "$@"
