#!/bin/sh

set -e 

register_system() {
  if [ -n "$RH_OLD_SYSTEM" ] && [ -n "$RH_USER" ] ; then
    subscription-manager register --consumerid=$RH_OLD_SYSTEM --username=$RH_USER
    return
  fi
  if [ -n "$RH_ACTIVATION_KEY" ] && [ -n $RH_ORG_ID ] ; then
    subscription-manager register --activationkey=${RH_ACTIVATION_KEY} --org=${RH_ORG_ID}
    return
  fi
  cat<<EOF
Needed environment variables not set!

If you want to reuse an existing system:

1) Log into the portal: https://access.redhat.com/management/consumers?type=system
2) Find the old system, copy it's UUID (ex: ad88c818-7777-4370-8878-2f1315f7177a)
3) Set these ENV variables:

	export RH_OLD_SYSTEM=ad88c818-7777-4370-8878-2f1315f7177a
	export RH_USER=biholmes

However, if you want to use an activation key, you need to do this:

1) On an exsting system, find your Red Hat Organization Id:
2) Log in and run: subscription-manager identity
3) Setup an activation key via: https://access.redhat.com/management/activation_keys
4) Set these ENV variables:

	export RH_ACTIVATION_KEY=MY_COOL_KEY
	export RH_ORG_ID=31337

EOF
  exit 1
}

fix_hostname() {
  HOST=$(subscription-manager identity | grep ^name: | cut -d ' ' -f 2)
  if [ "$(hostname)" = "$HOST" ] ; then
    return
  fi

  echo "Current hostname and old hostname don't match."
  echo "Setting current hostname to: $HOST"
  hostnamectl set-hostname $HOST
}

fix_ip() {
  echo "Determining old ip from hostname: $HOST"
  OLDIP=$(ping -w 1 -c 1 $HOST 2>/dev/null | grep ^PING | tr '()' ',' | cut -d , -f 2)
  if [ -z "$OLDIP" ] ; then
    echo "Unable to determine old ipaddress"
    return
  fi
  IP_MASK=$(nmcli c show eth0 | grep ipv4.addresses | tr -s ' ' | cut -d ' ' -f 2)
  MASK=$(cut -d / -f 2 <<< "$IP_MASK")
  IP=$(cut -d / -f 1 <<< "$IP_MASK")
  if [ "$IP" = "$OLDIP" ] ; then
    echo "Old ip and current ip are the same."
    return
  fi
  INTERFACE=$(ip route | grep ^default | sed 's/^.*dev \([[:alnum:]]*\) .*$/\1/')
  if [ -z "$INTERFACE" ] ; then
    echo "Unable to find primary ethernet device!"
    exit 1
  fi
  echo "Old ip and current ip don't match, setting ip to old ip: $OLDIP/$MASK"
  nmcli c modify $INTERFACE ipv4.addresses "$OLDIP/$MASK"
}

subscription-manager identity || register_system
fix_hostname
fix_ip
subscription-manager release --set=7Server
subscription-manager repos --disable "*"
subscription-manager repos --enable rhel-7-server-rpms --enable rhel-7-server-rh-common-rpms
yum install -y screen git vim

[ -r satellite-install/.git ] || git clone http://git/git/satellite-install.git

(
  cd satellite-install
  git pull
)

if fgrep -q nfs /etc/fstab ; then
  echo "You have NFS mounts, you should probably make sure they're good."
  grep nfs /etc/fstab
  read -p "Edit now? " YN
  case $YN in
    y|Y|[yY][eE][sS])
      vim /etc/fstab
      ;;
  esac
fi

if [ -n "$INTERFACE" ] ; then
  echo "IP address changed! You should reboot!"
  read -p "Reboot now? " YN
  case $YN in
    y|Y|[yY][eE][sS])
      systemctl reboot;;
  esac
  echo
  echo "Ok, but you need to reboot soon!"
fi
