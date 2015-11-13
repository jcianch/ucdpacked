#!/bin/bash
source /vagrant/parameters.sh
yum install -y redhat-lsb-core.i686
echo "install RLKS"
$MEDIA_DIR/rlks814/InstallerImage_linux_gtk_x86_64/installc -acceptLicense input $MEDIA_DIR/rlks814/RLKSinstall.rsp -log /tmp/rlks.log
cat $MEDIA_DIR/rlks814/server_license.lic >> /opt/IBM/RationalRLKS/config/server_license.lic
sed -i '/xterm/c\echo\ \$text' /opt/IBM/RationalRLKS/config/server_start_stop.sh
/opt/IBM/RationalRLKS/config/server_start_stop.sh start
sleep 5s
/opt/IBM/RationalRLKS/bin/lmutil lmstat -a

# cp /opt/IBM/RationalRLKS/config/start_lmgrd /etc/init.d/rlks
# chmod +x /etc/init.d/rlks
# chown root:root /etc/init.d/rlks
# chkconfig --add rlks
# chkconfig rlks on
# service rlks start 