#!/bin/bash
source /vagrant/parameters.sh
yum install -y redhat-lsb-core.i686
echo "install RLKS"
$MEDIA_DIR/rlks814/InstallerImage_linux_gtk_x86_64/installc -acceptLicense input $MEDIA_DIR/rlks814/RLKSinstall.rsp -log /tmp/rlks.log
cat $MEDIA_DIR/rlks814/server_license.lic >> /opt/IBM/RationalRLKS/config/server_license.lic
sed -i '/xterm/c\echo\ \$text' /opt/IBM/RationalRLKS/config/server_start_stop.sh

cp $BASE_DIR/scripts/rlks.service /etc/systemd/system/rlks.service
systemctl enable rlks.service
systemctl start rlks.service

sleep 5s
/opt/IBM/RationalRLKS/bin/lmutil lmstat -a
