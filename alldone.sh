#!/bin/bash
source /vagrant/parameters.sh

echo ""
echo ""
echo "##########################################################################################"
echo "## ALL Done!                                                                            ##"
echo "## OpenStack Horizon : http://$IPADDRESS/ admin/$MY_OS_PASSWORD                         ##"
echo "## UrbanCode Deploy  : http://$IPADDRESS:$MY_UCD_HTTP_PORT admin/$MY_UCD_PASSWORD       ##"
echo "## UrbanCode Deploy Designer : http://$IPADDRESS:$MY_UCDP_HTTP_PORT/landscaper ucdpadmin/ucdpadmin ##"
echo ""
echo "## ssh vagrant@$ipaddress password is $MY_OS_PASSWORD"
echo ""
echo "##########################################################################################"
echo ""
echo ""
