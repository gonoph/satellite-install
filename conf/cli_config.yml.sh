#!/bin/sh

cat<<EOF
:modules:
    - hammer_cli_foreman

:foreman:
    :host: 'https://$(hostname)'
    :username: 'admin'
    :password: 'redhat123'

:log_dir: '~/.foreman/log'
:log_level: 'error'

EOF
