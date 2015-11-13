#!/bin/bash
#Get the ip address of br-ex = eth0
export IPADDRESS=`/sbin/ifconfig br-ex | grep "inet " | awk -F\  '{print $2}' | awk '{print $1}'`

export JAVA_HOME=/opt/IBM/java/jre/ #JAVA_HOME
export MY_HOSTNAME=stackinabox #hostname to use
export MY_OS_PASSWORD=My_passw0rd #hostname to use
export MY_RLKS_IP=${IPADDRESS} #Design server HTTPS port
export MY_UCD_HTTP_PORT=10080 #UCD server HTTP port
export MY_UCD_HTTPS_PORT=10443 #UCD server HTTPS port
export MY_UCD_PASSWORD=My_passw0rd #UCD admin Password
export MY_UCDP_HTTP_PORT=9080 #Design server HTTP port
export MY_UCDP_HTTPS_PORT=9443 #Design server HTTPS port
