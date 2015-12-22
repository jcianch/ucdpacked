#!/bin/bash
source /vagrant/parameters.sh
bold=$(tput bold)
normal=$(tput sgr0)
echo ""
echo "##########################################################################################"
echo "OpenStack ${bold}$OS_VERSION
${normal}UCD ${bold}$UCDVERSION
OpenStack Horizon : http://$IPADDRESS/ admin/$MY_OS_PASSWORD
UrbanCode Deploy  : http://$IPADDRESS:$MY_UCD_HTTP_PORT admin/$MY_UCD_PASSWORD
UrbanCode Deploy Designer : http://$IPADDRESS:$MY_UCDP_HTTP_PORT/landscaper ucdpadmin/ucdpadmin
"
printf "ssh root@%s password is $MY_OS_PASSWORD" "$IPADDRESS"

echo "${normal}##########################################################################################"

