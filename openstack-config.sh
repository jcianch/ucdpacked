#!/bin/bash
source /vagrant/parameters.sh
source /root/keystonerc_admin
nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0  
nova secgroup-add-rule default tcp 22 22 0.0.0.0/0  

#delete Packstack created network/router and recreate
neutron router-interface-delete router1 private_subnet
neutron router-gateway-clear router1
neutron router-delete router1
neutron subnet-delete public_subnet
neutron net-delete public
sleep 30s
neutron net-create public --router:external
neutron subnet-create public 172.16.235.0/24 --name public_subnet --enable_dhcp=False --allocation_pool start=172.16.235.201,end=172.16.235.220 --gateway 172.16.235.2
neutron router-create router1
neutron router-gateway-set router1 public
neutron router-interface-add router1 private_subnet

#Update DNS for private subnet
neutron subnet-update  --dns-nameserver 8.8.8.8 private_subnet

#The Demo provision from Packstack should already have setup the Cirros image
cirrosid=`nova image-list | grep cirros | awk '{ print $2}'`
nova image-meta $cirrosid set hw_qemu_guest_agent=yes
#add a centos 6 image
glance image-create --name centos6x64 --disk-format qcow2 --container-format bare --file $MEDIA_DIR/osimages/CentOS-6-x86_64-GenericCloud.qcow2 --is-public True --progress --human-readable
imageid=`nova image-list | grep centos6x64 | awk '{ print $2}'`
nova image-meta $imageid set hw_qemu_guest_agent=yes
#add a Ubuntu 14 04 image
glance image-create --name ubuntu1404x64 --disk-format qcow2 --container-format bare --file $MEDIA_DIR/osimages/trusty-server-cloudimg-amd64-disk1.img --is-public True --progress --human-readable
imageid=`nova image-list | grep ubuntu1404x64 | awk '{ print $2}'`
nova image-meta $imageid set hw_qemu_guest_agent=yes

nova keypair-add admin_key > $BASE_DIR/admin_key.priv
cp $BASE_DIR/admin_key.priv /home/vagrant/admin_key.priv
# remove default flavors
nova flavor-delete m1.tiny
nova flavor-delete m1.small
nova flavor-delete m1.medium
nova flavor-delete m1.large
nova flavor-delete m1.xlarge

# Add new Flavor that can run in a VM environment
echo "Creating new flavors that can be used on this vm"
nova flavor-create m1.tiny auto 768 5 1
nova flavor-create m1.small auto 1024 5 1
nova flavor-create m1.medium auto 1024 10 1
nova flavor-create m1.large auto 1536 10 2
nova flavor-create m1.xlarge auto 2048 10 2


