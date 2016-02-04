#!/bin/bash
#http://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=1006371
#expands centos LVM root volume to 260GB
# echo vagrant halt
vagrant up --no-provision
vagrant halt
VDISKDIR=$(dirname $(cat .vagrant/machines/stackinabox/vmware_workstation/id))
echo expanding $VDISKDIR/disk-cl1.vmdk to 261GB
vmware-vdiskmanager -x 261GB $VDISKDIR/disk-cl1.vmdk
vagrant up --no-provision
vagrant ssh -c  "sudo /vagrant/fdisk.sh" stackinabox
vagrant reload  --no-provision
vagrant ssh -c  "sudo /vagrant/extenddisk.sh" stackinabox
vagrant reload  --no-provision
