#!/bin/bash
# shutdown VM so we can export it
vagrant halt
timestamp=$(date +"%d%m%Y_%H%M")

rm -rf build/ovf/vmware/${OS_VERSION}UCD${UCDVERSION}${timestamp}
mkdir -p build/ovf/vmware/${OS_VERSION}UCD${UCDVERSION}${timestamp}

#   --allowAllExtraConfig \
#get ovftool path and vagrant machine id
if [[ "$OSTYPE" == "linux-gnu" ]]; then
   OVFTOOL=/usr/bin/ovftool
   IDCAT=`cat .vagrant/machines/stackinabox/vmware_workstation/id`
   VDISKDIR=$(dirname $(cat .vagrant/machines/stackinabox/vmware_workstation/id))
   vmware-vdiskmanager -d $VDISKDIR/disk-cl1.vmdk
   vmware-vdiskmanager -k $VDISKDIR/disk-cl1.vmdk
fi
