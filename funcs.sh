#!/bin/sh

: ${BETA:=}
: ${BASEURL:=}

[ -n "$BETA" ] && echo -e "\e[1;31mBETA Mode on\e[0m"  || echo -e "\e[1;34mBETA MODE off\e[0m"
[ -n "$BASEURL" ] && echo -e "\e[1;31mBASEURL is set\e[0m"

[ -r /tmp/.cache-release -a "$(cat /tmp/.cache-release)" = "Release: 7Server" ] || rm -fv /tmp/.cache-release

err() {
  echo -e "\e[1;31mERROR:\e[0m" "$@"
  exit 1
}

set_release() {
  [ -r /tmp/.cache-release -a "$(cat /tmp/.cache-release)" = "Release: 7Server" ] && return 0
  subscription-manager release --set=7Server
  subscription-manager release > /tmp/.cache-release
}

disable_repos() {
  echo -n "Disabling repos: "
  if !  grep -q '^enabled = ' /etc/yum.repos.d/redhat.repo ; then
    # need to run subscription-manager
    subscription-manager repos --disable "*" > /tmp/l 2>&1
  else
    grep '^enabled = ' /etc/yum.repos.d/redhat.repo > /tmp/l 2>&1
    sed -i -e 's%enabled = 1%enabled = 0%' /etc/yum.repos.d/redhat.repo
  fi
  cat /tmp/l | wc -l
}

enable_repos() {
  [ $# -eq 0 ] && err "Must give repos to enable"
  local args=""
  while [ $# -gt 0 ] ; do
    args+="--enable=$1 "
    shift 1
  done

  [ -n "$BASEURL" ] && rm -f /etc/yum.repos.d/redhat-new.repo
  echo subscription-manager repos $args
  subscription-manager repos $args

  if [ -n "$BASEURL" ] ; then
    echo -e "\e[1;31mEnabling $BASEURL for repos.\e[0m"
    /usr/bin/cp -f /etc/yum.repos.d/redhat.repo /tmp/redhat-new.repo
    sed -i -e "s%https://cdn.redhat.com/content/%$BASEURL%" -e 's%-rpms]%-rpms-new]%' /tmp/redhat-new.repo
    yum clean all
    disable_repos
    mv -f /tmp/redhat-new.repo /etc/yum.repos.d/redhat-new.repo
  fi
}
