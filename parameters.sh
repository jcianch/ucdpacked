#!/bin/bash
#Get the ip address of br-ex = eth0
export IPADDRESS=`/sbin/ifconfig br-ex | grep "inet " | awk -F\  '{print $2}' | awk '{print $1}'`

export BASE_DIR=/vagrant #root dir for scripts etc
export JAVA_HOME=/opt/IBM/java/jre/ #JAVA_HOME
export MEDIA_DIR=$BASE_DIR/media #base directory for all media
export MY_HOSTNAME=stackinabox #hostname to use
export MY_OS_PASSWORD=passw0rd #hOpenStack default password
export MY_RLKS_IP=${IPADDRESS} #License server IP address
export MY_UCD_HTTP_PORT=10080 #UCD server HTTP port
export MY_UCD_HTTPS_PORT=10443 #UCD server HTTPS port
export MY_UCD_PASSWORD=passw0rd #UCD admin Password
export MY_UCDP_HTTP_PORT=9080 #Design server HTTP port
export MY_UCDP_HTTPS_PORT=9443 #Design server HTTPS port
export UCDVERSION=6.2.1 #sub-directory in $MEDIA_DIR for ucd media
export OS_VERSION=kilo
#Network settings
export MY_DNS1=8.8.8.8
export MY_DNS2=172.19.21.2
export MY_BROADCAST=172.19.21.255
export MY_GATEWAY=172.19.21.2
export MY_SUBNET=172.19.21.0/24
export MY_IP_START=172.19.21.201
export MY_IP_END=172.19.21.220
