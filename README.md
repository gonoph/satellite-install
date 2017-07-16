# satellite-install
Collection of scripts that aid in installing Red Hat Satellite 6.2 GA

## OVERVIEW OF USAGE
by Billy Holmes <billy@gonoph.net>

These are scripts I wrote to help me install and configure a Satellite 6.2 GA server. There is a bootstrap script that aids in getting the server to the point where you can checkout the repo and start the make process.

The *Makefile* performs the actual package and install, but even after the server is configured, there are a lot of things left.

In the *scripts* directory is a collection of scripts used to help the pre-install, install, and post-install steps to get the Satellite server ready to provision and sync the repositories.

### The bootstrap

First, clone the repo to your workstation:

    git clone https://github.com/gonoph/satellite-install.git
    cd satellite-install

Now, copy the bootstrap script to your server:

    scp 0-bootstrap.sh sat-62:/tmp

Next, there are three ways to register the server:

1. Activiation Key
2. Use an existing system UUID in the Red Hat portal
3. Use an existing system, but let the script lookup the UUID from the Red Hat portal

To use either option, run the script, and it will tell you which environment settings to set.

The server's hostname is treated differently based on the above:

1. If you use the activation key, then the hostname will be the name that your server uses to register - don't keep it *localhost*.
2. If you use an existing system UUID, the script will automatically set the hostname to the name of the registered system that belongs to that UUID.
3. If you lookup the UUID, the script will use the current hostname and attempt to match it based on the systems in your account in the portal.

Therefore, the *ONLY* reason you would *NOT* set the hostname manually, would be if you use scenario (2) to register the server.

Environment variables steps:

#### REGISTER BY ACTIVATION KEY

1. Setup an activation key via: <https://access.redhat.com/management/activation_keys>
2. Set these ENV variables:

    export RHN_ACTIVATION_KEY
    # then
    export RHN_ORG_ID
    # _or_
    export RHN_USER RHN_PASS

3. If you're using the `RHN_USER`, a helper script will find the ORG
4. Run the script

#### REGISTER VIA UUID
1. Log into the portal: <https://access.redhat.com/management/consumers?type=system>
2. Find the old system, copy it's UUID (ex: ad88c818-7777-4370-8878-2f1315f7177a)
3. -or- create(register) a new system in the portal, attach the *Satellite Subscription*, and copy it's UUID.
4. Set these ENV variables:

    export RHN_USER RHN_PASS
    export RHN_OLD_SYSTEM=ad88c818-7777-4370-8878-2f1315f7177a`

5. Run the bootstrap

#### REGISTER VIA UUID BY LOOKING UP OLD UUID BY HOSTNAME
1. Ensure *hostname* of the system is the same as the previous registration
2. Set these ENV variables:

    export RHN_USER RHN_PASS

3. Run the script

### To configure the server after the reboot

After the reboot, you will need to run make to finish setting up the server. My Makefile assumes certain things, which you will need to update:

1. There is a blockdevice called */dev/mapper/rhel_sat--mongodb-mongodb* and it is mounted at */var/lib/mongodb*
2. You will use the default user/pass of *admin/redhat123*
3. You pulp alternative sources is located at *http://zfs1.virt/pulp/*

You can change these assumptions by editing these files to suit your needs:

1. `conf/cli_config.yml.sh`
2. `etc/mongod.service.d/blockdev.conf`
3. `alternative.conf`

### Using the hammer script

Ater the installation of the server, you will need to further configure it with your manifest, your repos, subnets, sync plans, and a bunch of other things that are outlined in the install guide. To configure a sample version of these things, you can run the *hammer.sh* command which has the following help:

    $ scripts/hammer.sh
    usage: ./scripts/hammer.sh (manifest (FILE) | all | -h | --help | repos | satellite | repos-extra | sync | view | publish | provisioning)

The 1st thing you will do, is install your manifest, repos, then satellite repos (if needed), extra repos, sync plans, content views, publish it, then set it up for provisioning. The script assumes these defaults:

    ORG=1
    LOC=2

Here is an example:

    scripts/hammer.sh manifest /tmp/manifest.zip
    scripts/hammer.sh repos
    scripts/hammer.sh sync
    scripts/hammer.sh view
    scripts/hammer.sh publish
    scripts/hammer.sh provisioning

### Provision a system

After all the steps have been ran, you should then be able to provision a system. If you are running RHEV, there is a sample script called *provision* that can help you do this. All it needs to some environment varibles set, or it will use its defaults:

    HOST=client1.virt.gonoph.net
    HG=RHEL7-Server
    IP=#from host lookup#
    ORG=1
    LOC=2
    RHEVM_USER=admin@internal
    RHEVM_PASS=redhat123

Once you setup the env variables to match your environment, just run the script:

    scripts/provision

When you are done with the system, or wish to start again, run it with clean:

    scripts/provision clean

The script will create a RHEVM virtual machine, grab the mac, create the satellite host, populate the mac, and tell RHEV to start the VM using PXE to have it kickstart a satellite install.
