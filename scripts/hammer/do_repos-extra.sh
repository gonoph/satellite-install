#!/bin/sh

do_action() {
    info "Enabling extra forge repos"
    hammer product create ${ORG} --name='Forge'
    hammer repository create ${ORG} --name='Puppet Forge' --product='Forge' --content-type='puppet' --publish-via-http=true --url=https://forge.puppetlabs.com

    if [ -z "$BETA" ] ; then
        info "Enabling extra EPEL repos"
        hammer product create ${ORG} --name='EPEL'
        hammer repository create ${ORG} --name='EPEL 7 - x86_64' --product='EPEL' --content-type='yum' --publish-via-http=true --url=http://dl.fedoraproject.org/pub/epel/7/x86_64/

        info "Enabling extra Fedora 22,23 repos"
        hammer product create ${ORG} --name='Fedora'
        hammer repository create ${ORG} --name='Fedora 22 - x86_64' --product='Fedora' --content-type='yum' --publish-via-http=true --url=http://dl.fedoraproject.org/pub/fedora/linux/releases/22/Everything/x86_64/os/
        hammer repository create ${ORG} --name='Fedora 23 - x86_64' --product='Fedora' --content-type='yum' --publish-via-http=true --url=http://dl.fedoraproject.org/pub/fedora/linux/releases/23/Everything/x86_64/os/

        info "Enabling extra Fedora 22,23 update repos"
        hammer repository create ${ORG} --name='Fedora 22 Updates - x86_64' --product='Fedora' --content-type='yum' --publish-via-http=true --url=http://dl.fedoraproject.org/pub/fedora/linux/updates/22/x86_64/
        hammer repository create ${ORG} --name='Fedora 23 Updates - x86_64' --product='Fedora' --content-type='yum' --publish-via-http=true --url=http://dl.fedoraproject.org/pub/fedora/linux/updates/23/x86_64/
    fi
}
