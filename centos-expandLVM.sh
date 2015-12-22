#!/bin/bash
#http://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=1006371
#expands centos LVM root volume to 260GB
VDISKDIR=$(dirname $(cat .vagrant/machines/stackinabox/vmware_workstation/id))
vmware-vdiskmanager -x 261GB $VDISKDIR/disk-cl1.vmdk
vagrant up --no-provision
vagrant ssh -- sudo /vagrant/fdisk.sh
vagrant reload
vagrant ssh -- sudo /vagrant/extenddisk.sh
vagrant halt
