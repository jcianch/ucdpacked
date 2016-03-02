#!/bin/bash
source /vagrant/parameters.sh
echo setting password to ${MY_OS_PASSWORD}
echo "${MY_OS_PASSWORD}" | passwd "vagrant" --stdin
echo "${MY_OS_PASSWORD}" | passwd "root" --stdin
yum install -y deltarpm
yum install -y https://repos.fedorapeople.org/repos/openstack/openstack-kilo/rdo-release-kilo-1.noarch.rpm
yum install -y openvswitch 

systemctl stop NetworkManager 
systemctl disable NetworkManager
yum remove -y NetworkManager

export IPADDRESS=`/sbin/ifconfig ens32 | grep "inet " | awk -F\  '{print $2}' | awk '{print $1}'`
echo ${IPADDRESS}
#TODO If getting IP address from different subnet change here as required
cat > /etc/sysconfig/network-scripts/ifcfg-br-ex <<EOF
DEVICE="br-ex"  
BOOTPROTO="none"  
IPADDR=$IPADDRESS  
NETMASK="255.255.255.0"  
DNS1=$MY_DNS1
DNS2=$MY_DNS2
BROADCAST=$MY_BROADCAST  
GATEWAY=$MY_GATEWAY
NM_CONTROLLED="no"  
DEFROUTE="yes"  
IPV4_FAILURE_FATAL="yes"  
IPV6INIT=no  
ONBOOT="yes"  
TYPE="OVSBridge"  
DEVICETYPE="ovs"
EOF
#TODO The Centos 7 vagrant image has ens32 as eth0. Change as needed
cat > /etc/sysconfig/network-scripts/ifcfg-ens32 <<'EOF'
DEVICE="ens32"  
ONBOOT="yes"  
TYPE="OVSPort"  
DEVICETYPE="ovs"  
OVS_BRIDGE=br-ex  
NM_CONTROLLED=no  
IPV6INIT=no 
EOF
#TODO If getting IP address from different subnet change here as required adn in openstack-config.sh
cat > /etc/resolv.conf <<'EOF'
search localdomain
nameserver $MY_DNS1
nameserver $MY_DNS2
EOF
#Centos 7 vagrant image has ens33 as eth1. Not required
rm -f /etc/sysconfig/network-scripts/ifcfg-ens33

# Update host configuration
hostname "${MY_HOSTNAME}"
echo "${MY_HOSTNAME}" > /etc/hostname
cat > /etc/hosts << EOF
127.0.1.1       ${MY_HOSTNAME}
127.0.0.1       localhost localdomain

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
EOF
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.rp_filter=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.rp_filter=0" >> /etc/sysctl.conf
sysctl -p

echo "\
ClientAliveInterval 5" | tee -a /etc/ssh/sshd_config
#TODO The Centos 7 vagrant image has ens32 as eth0. Change as needed
iptables -t nat -A POSTROUTING -o ens32 -j MASQUERADE
iptables -t nat -A POSTROUTING -o br-ex -j MASQUERADE
iptables -A POSTROUTING -t mangle -p udp --dport bootpc -j CHECKSUM --checksum-fill
