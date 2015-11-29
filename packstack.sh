#!/bin/bash
source /vagrant/parameters.sh

yum install -y openstack-packstack  qemu-kvm qemu-img virt-manager libvirt libvirt-python libvirt-client crudini

modprobe vhost_net
echo  vhost_net > /etc/modules-load.d/vhost_net.conf
##Nov 29 2015: This is required as packstack appears broken: 
##See https://ask.openstack.org/en/question/85014/error-could-not-find-data-item-config_use_subnets-in-any-hiera-data-file/
packstack --allinone -y
rpm -e puppet 
rpm -e hiera
rpm -ivh https://yum.puppetlabs.com/el/7/products/x86_64/hiera-1.3.4-1.el7.noarch.rpm
crudini --set /etc/yum.repos.d/epel.repo epel exclude hiera* || true
yum install -y puppet-3.6.2-3.el7.noarch 
rm -f /etc/puppet/hiera.yaml
##End fix for broken packstack
packstack --default-password=${MY_OS_PASSWORD} --allinone \
--mariadb-install=y \
--os-glance-install=y \
--os-cinder-install=y \
--os-manila-install=n \
--os-nova-install=y \
--os-neutron-install=y \
--os-horizon-install=y \
--os-swift-install=y \
--os-ceilometer-install=y \
--os-heat-install=y \
--os-sahara-install=n \
--os-trove-install=n \
--os-ironic-install=n \
--os-client-install=y \
--nagios-install=n \
--novanetwork-pubif=ens32 \
--os-neutron-l3-ext-bridge=br-ex \
--os-neutron-lbaas-install=y \
--os-neutron-ovs-bridge-mappings=ens32:br-ex \
--os-neutron-ovs-bridge-interfaces=br-ex:ens32 \
--os-horizon-ssl=n \
--os-heat-cloudwatch-install=y \
--os-heat-cfn-install=y \
--provision-demo=y \
--provision-image-name=cirros \
--provision-image-url=http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img \
--provision-image-format=qcow2 \
--provision-image-ssh-user=cirros \
--provision-all-in-one-ovs-bridge=y 

#Nova mods
crudini --set /etc/nova/nova.conf DEFAULT my_ip ${IPADDRESS} || true
crudini --set /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address ${IPADDRESS} || true
crudini --set /etc/nova/nova.conf DEFAULT force_config_drive always || true
crudini --set /etc/nova/nova.conf DEFAULT mkisofs_cmd genisoimage || true

crudini --set /etc/nova/nova.conf libvirt virt_type kvm || true
crudini --set /etc/nova/nova.conf libvirt cpu_mode host-passthrough || true


#modify Neutron setup
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata True || true
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT enable_metadata_network True || true

#Modify Celimoeter to lower interval to 60 seconds
sed -i -e 's/interval: 600/interval: 60/g' /etc/ceilometer/pipeline.yaml
#Modify Nova for telemetry
crudini --set /etc/nova/nova.conf DEFAULT notification_driver messagingv2 || true

