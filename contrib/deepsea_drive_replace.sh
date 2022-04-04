#!/bin/bash
#
# deepsea_drive_replace.sh
#
# The purpose of this script is to helping to reproduce certain SES5 and SES6 CI
# failures (i.e., those involving the drive replacement test).
#
# Notes on preparing to run the script:
#
# 1. use "sesdev scp" to upload the script to the Salt Master node
# 2. use "sesdev ssh" to SSH into the Salt Master node
# 3. find the script on the Salt Master node
#
# Notes on running the script:
#
# 1. required argument: the osd.id to be replaced
# 2. capture output in a file for subsequent analysis

set -ex

OSD_ID="$1"

# write "ceph osd tree" JSON to a file for later "before-after" comparison
ceph osd tree --format json | tee before.json

# assert that the OSD's systemd unit is active
if systemctl is-active "ceph-osd@$OSD_ID" ; then
    echo "OSD ${OSD_ID} systemd unit is active, as expected" > /dev/null 2>&1
else
    echo "OSD ${OSD_ID} is to be removed, yet its systemd unit is not active!" \
      > /dev/null 2>&1
    exit 1
fi

# get the device path of the OSD's underlying disk
OSD_PATH=$(salt \* cephdisks.find_by_osd_id "${OSD_ID}" --out json 2> \
  /dev/null | jq -j '.[][].path')

# run DeepSea's "osd.replace" runner
salt-run osd.replace "$OSD_ID" 2> /dev/null

# display OSD tree in log for visual confirmation that OSD is destroyed
ceph osd tree

# assert that the OSD's systemd unit is not active
if systemctl is-active "ceph-osd@$OSD_ID" ; then
    echo "OSD ${OSD_ID} systemd unit is still active, yet OSD was supposed to\
         \ have been removed!" > /dev/null 2>&1
    exit 1
else
    echo "OSD ${OSD_ID} systemd unit no longer active. Good." > /dev/null 2>&1
fi

# simulate physical disk removal
sgdisk -Z "$OSD_PATH"
sgdisk -p "$OSD_PATH"
lsblk
lsof "/var/lib/ceph/osd/ceph-$OSD_ID" || true
sync
mkfs.ext4 -F "$OSD_PATH"
mount "$OSD_PATH" /mnt

# logging for visual confirmation of sanity
ceph-volume inventory
salt-run disks.c_v_commands 2>/dev/null
