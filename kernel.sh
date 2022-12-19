#!/bin/bash
#
set -x

DEPLOYMENT=${DEPLOYMENT:-"foo-bar-ses6"}
MI=${MI:-"$(echo "$DEPLOYMENT" | cut -d '-' -f 1)"}
RR=${RR:-"$(echo "$DEPLOYMENT" | cut -d '-' -f 2)"}
SESVERSION=${SESVERSION:-"$(echo "$DEPLOYMENT" | cut -d '-' -f 3)"}
NODE_NAMES=(
  "master"
  "node1"
  "node2"
  "node3"
  "node4"
  "node5"
  )

sshcmd() {
  node="$1"
  shift
  # shellcheck disable=SC2068
  sesdev ssh "${DEPLOYMENT}" "$node" -- $@
}

addrepo() {
  local _node="$1"
  local _url="$2"
  local _alias="$3"

  curl \
    --silent \
    --fail \
    "$_url" \
  && sshcmd \
    "$_node" \
    zypper -n \
      ar \
      --priority 50 \
      "$_url" "$_alias"
}

pkgupdate() {
  local _node="$1"
  sshcmd "$_node" zypper -n ref
  sshcmd "$_node" zypper -n update
  sshcmd "$_node" reboot
  while ! sshcmd "$n" true ; do sleep 10 ; done
}

# shellcheck disable=SC2068
for n in ${NODE_NAMES[@]} ; do
  if sshcmd "$n" true ; then
    echo "Preparing $n..."
    pkgupdate "$n"

  else
    echo "Skipping $n"
  fi
done

# shellcheck disable=SC2068
for n in ${NODE_NAMES[@]} ; do
  if sshcmd "$n" true ; then
    echo "Updating $n..."

    if [ "${SESVERSION}" = "ses6" ] ; then
      addrepo "$n" "https://download.suse.de/ibs/SUSE:/Maintenance:/${MI}/SUSE_SLE-15-SP1_Update/" "${MI}-update"
      addrepo "$n" "https://download.suse.de/ibs/SUSE:/Maintenance:/${MI}/SUSE_SLE-15-SP1_Update_Products_SES6_Update/" "${MI}-product-update"
      addrepo "$n" "https://download.suse.de/ibs/SUSE:/Maintenance:/${MI}/SUSE_Updates_Storage_6_x86_64/" "${MI}-storage-update"
    fi

    if [ "${SESVERSION}" = "ses7" ] ; then
      addrepo "$n" "https://download.suse.de/ibs/SUSE:/Maintenance:/${MI}/SUSE_SLE-15-SP2_Update/" "${MI}-update"
      addrepo "$n" "https://download.suse.de/ibs/SUSE:/Maintenance:/${MI}/SUSE_SLE-15-SP2_Update_Products_SES7_Update/" "${MI}-product-update"
      addrepo "$n" "https://download.suse.de/ibs/SUSE:/Maintenance:/${MI}/SUSE_Updates_Storage_7_x86_64/" "${MI}-storage-update"
    fi

    if [ "${SESVERSION}" = "ses7p" ] ; then
      addrepo "$n" "https://download.suse.de/ibs/SUSE:/Maintenance:/${MI}/SUSE_SLE-15-SP3_Update/" "${MI}-update"
      addrepo "$n" "https://download.suse.de/ibs/SUSE:/Maintenance:/${MI}/SUSE_SLE-15-SP3_Update_Products_SES7_Update/" "${MI}-product-update"
      addrepo "$n" "https://download.suse.de/ibs/SUSE:/Maintenance:/${MI}/SUSE_Updates_Storage_7.1_x86_64/" "${MI}-storage-update"
    fi

    pkgupdate "$n"
  else
    echo "Skipping $n"
  fi
done
