#!/bin/bash
source /vagrant/parameters.sh
yum install -y gcc gcc-c++ kernel-devel mysql-devel python-devel genisoimage
yum remove -y akonadi
cd $MEDIA_DIR/$UCDVERSION/ibm-ucd-patterns-install/engine-install/
./extend-existing-engine.sh -l -o kilo
echo Engine extended. Restarting services

systemctl restart openstack-heat-engine.service
systemctl restart openstack-heat-api.service
echo Restarted services