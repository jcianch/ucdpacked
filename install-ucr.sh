#!/bin/bash
source /vagrant/parameters.sh

yum install -y unzip
# install java
mkdir -p /opt/IBM/
cp -R $MEDIA_DIR/$UCDVERSION/ibm-ucd-patterns-install/web-install/media/server/java /opt/IBM/
export JAVA_HOME=/opt/IBM/java/jre
export PATH=$PATH:$JAVA_HOME/bin


chmod 755 /opt/IBM/java/jre/bin/java

echo ""
echo ""
echo "###############################################################################"
echo "## Installing UrbanCode Release                                              ##"
echo "## using JAVA_HOME=$JAVA_HOME                                                ##"
echo "###############################################################################"
echo ""
echo ""

# create mysql database for UCD
mysql --user=root -p${MY_OS_PASSWORD} -e "CREATE USER 'ibm_ucr'@'localhost' IDENTIFIED BY 'ibm_ucr';
CREATE DATABASE ibm_ucr CHARACTER SET = utf8 COLLATE =utf8_bin;
GRANT ALL ON ibm_ucr.* TO 'ibm_ucr'@'%' IDENTIFIED BY 'ibm_ucr' WITH GRANT OPTION;"

#./IBMIM -record responseFile -skipInstall tempFolder
./IBMIM --launcher.ini silent-install.ini -input /vagrant/ucrResponse.xml -acceptLicense

#install UCD Server as a service
cp $BASE_DIR/scripts/ucr.service /etc/systemd/system/ucr.service
systemctl enable ucr.service
echo "Starting the ucr Server..."
systemctl start ucr.service

#TODO
# add UCD plugin and integrate
#import assets?
