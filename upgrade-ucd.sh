#!/bin/bash
source /vagrant/parameters.sh

echo ""
echo ""
echo "###############################################################################"
echo "## Upgrading UrbanCode Deploy                                               ##"
echo "## using JAVA_HOME=$JAVA_HOME                                                ##"
echo "###############################################################################"
echo ""
echo ""

systemctl stop ucd-server.service

# Download the mysql java driver jar and put it into ibm-ucd-install/lib/ext directory
cp $MEDIA_DIR/dbjar/mariadb-java-client-1.2.3.jar $MEDIA_DIR/$UCDVERSION/ibm-ucd-install/lib/ext

# make copy of original properies file
cp $MEDIA_DIR/$UCDVERSION/ibm-ucd-install/install.properties $MEDIA_DIR/$UCDVERSION/ibm-ucd-install/orig-install.properties

# echo per-deployment configurable properties
# TODO: make these values configurable from options.yml
echo "
nonInteractive=true
" >> $MEDIA_DIR/$UCDVERSION/ibm-ucd-install/install.properties

echo "Installing UCD Server with the following properties:"
cat $MEDIA_DIR/$UCDVERSION/ibm-ucd-install/install.properties
cd $MEDIA_DIR/$UCDVERSION/ibm-ucd-install/
./install-server.sh

# restore the orig-install.properties
rm $MEDIA_DIR/$UCDVERSION/ibm-ucd-install/install.properties
mv $MEDIA_DIR/$UCDVERSION/ibm-ucd-install/orig-install.properties $MEDIA_DIR/$UCDVERSION/ibm-ucd-install/install.properties

echo "Starting the UCD Server..."
sed -i -e 's/@SERVER_USER@/root/g' -e 's/@SERVER_GROUP@/root/g' /opt/ibm-ucd/server/bin/init/server
sed -i '/SERVER_PROG=/c\SERVER_PROG=ucd_server' /opt/ibm-ucd/server/bin/init/server
systemctl start ucd-server.service

sleep 30s
# now install udclient
rm -rf /opt/ibm-ucd/udclient
unzip -q $MEDIA_DIR/$UCDVERSION/ibm-ucd-install/overlay/opt/tomcat/webapps/ROOT/tools/udclient.zip -d /opt/ibm-ucd


echo ""
echo ""
echo "###############################################################################"
echo "## Upgrading UrbanCode Deploy Agent                                         ##"
echo "## using JAVA_HOME=$JAVA_HOME                                                ##"
echo "###############################################################################"
echo ""
echo ""

sleep 30s # give UCD enough time to start up before running this command
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -username admin -password ${MY_UCD_PASSWORD} upgradeAgent -agent local
echo "Starting the UCD Agent..."
systemctl start ucd-agent.service

