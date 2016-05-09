# satellite-install
Collection of scripts that aid in installing Red Hat Satellite 6.1 and 6.2 Beta

## OVERVIEW OF USAGE
by Billy Holmes <billy@gonoph.net>

These are scripts I wrote to help me install and configure a Satellite 6.1/6.2 Beta server. There is a bootstrap script that aids in getting the server to the point where you can checkout the repo and start the make process.

The *Makefile* performs the actual package and install, but even after the server is configured, there are a lot of things left.

In the *scripts* directory is a collection of scripts used to help the pre-install, install, and post-install steps to get the Satellite server ready to provision and sync the repositories.

### The bootstrap

First, clone the repo to your workstation:

    git clone https://github.com/gonoph/satellite-install.git
    cd satellite-install

Now, copy the bootstrap script to your server:

    scp 0-bootstrap.sh sat-62:/tmp

Next, there are two ways to register the server:

1) Activiation Key
2) Use an existing system

To use either option, run the script, and it will tell you which environment settings to set. As a bonus, if you set the hostname beforehand, the script will automatically set the correct IP address for you. This assumes you are using static IPs. If you are using DHCP, then after the ip address is set, the gateway and DNS will be blank.

Finally run the script:

    /tmp/0-bootstrap.sh

### To configure the server after the reboot

After the reboot, you will need to run make to finish setting up the server. My Makefile assumes certain things, which you will need to update:

1) There is a blockdevice called */dev/mapper/rhel_sat--mongodb-mongodb* and it is mounted at */var/lib/mongodb*
2) You will use the default user/pass of *admin/redhat123*
3) You pulp alternative sources is located at *http://zfs1.virt/pulp/*

You can change these assumptions by editing these files to suit your needs:

1) conf/cli_config.yml.sh
2) etc/mongod.service.d/blockdev.conf
3) alternative.conf

### Using the hammer script

Ater the installation of the server, you will need to further configure it with your manifest, your repos, subnets, sync plans, and a bunch of other things that are outlined in the install guide. To configure a sample version of these things, you can the *hammer.sh* command which has the following help:

    $ BETA=1 scripts/hammer.sh
    BETA Mode on
    usage: ./scripts/hammer.sh (manifest (FILE) | all | -h | --help | repos | satellite | repos-extra | sync | view | publish | provisioning)

The 1st thing you will do, is install your manifest, repos, then satellite repos (if needed), extra repos, sync plans, content views, publish it, then set it up for provisioning. Here is an example using the 6.2 BETA mode.

    export BETA=1
    scripts/hammer.sh manifest /tmp/manifest.zip
    scripts/hammer.sh repos
    scripts/hammer.sh repos-extra
    scripts/hammer.sh sync
    scripts/hammer.sh view
    scripts/hammer.sh publish
    scripts/hammer.sh provisioning

### Provision a system

After all the steps have been ran, you should then be able to provision a system. If you are running RHEV, there is a sample script called *create.sh* that can help you do this. All it needs to some environment varibles set, or it will use its defaults:

    HOST=sat-62.virt.gonoph.net
    HG=RHEL7-Server
    IP=#from host lookup#
    ORG=1
    LOC=2
    RHEVM_USER=admin@internal
    RHEVM_PASS=redhat123

Once you setup the env variables to match your environment, just run the script:

    scripts/create.sh

When you are done with the system, or wish to start again, run it with clean:

    scripts/create.sh clean

The script will create a RHEVM virtual machine, grab the mac, create the satellite host, populate the mac, and tell RHEV to start the VM using PXE to have it kickstart a satellite install.
