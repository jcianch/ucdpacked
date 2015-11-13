#!/bin/bash
source /vagrant/parameters.sh
yum install -y gcc gcc-c++ kernel-devel mysql-devel python-devel genisoimage
yum remove -y akonadi
cd $MEDIA_DIR/ibm-ucd-patterns-install/engine-install/
./extend-existing-engine.sh -l -o kilo
echo Engine extended. Restarting services
##TODO REMOVE when patch released for 
mv /usr/lib/heat/ibm-sw-orch/heat/ucd/stack_util.py ~/
cp $BASE_DIR/stack_util.py /usr/lib/heat/ibm-sw-orch/heat/ucd/
##TODO REMOVE when patch released

systemctl restart openstack-heat-engine.service
systemctl restart openstack-heat-api.service
echo Restarted services