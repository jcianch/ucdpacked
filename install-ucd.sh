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
echo "## Installing UrbanCode Deploy                                               ##"
echo "## using JAVA_HOME=$JAVA_HOME                                                ##"
echo "###############################################################################"
echo ""
echo ""

# create mysql database for UCD
mysql --user=root -p${MY_OS_PASSWORD} -e "CREATE USER 'ibm_ucd'@'localhost' IDENTIFIED BY 'ibm_ucd';
CREATE DATABASE ibm_ucd;
GRANT ALL ON ibm_ucd.* TO 'ibm_ucd'@'%' IDENTIFIED BY 'ibm_ucd' WITH GRANT OPTION; "

# Download the mysql java driver jar and put it into ibm-ucd-install/lib/ext directory
cp $MEDIA_DIR/dbjar/mariadb-java-client-1.2.3.jar $MEDIA_DIR/$UCDVERSION/ibm-ucd-install/lib/ext

# make copy of original properies file
cp $MEDIA_DIR/$UCDVERSION/ibm-ucd-install/install.properties $MEDIA_DIR/$UCDVERSION/ibm-ucd-install/orig-install.properties

# echo per-deployment configurable properties
# TODO: make these values configurable from options.yml
echo "
nonInteractive=true
install.server.web.always.secure=N
install.server.web.host=${IPADDRESS}
install.server.web.ip=${IPADDRESS}
install.server.web.https.port=${MY_UCD_HTTPS_PORT}
install.server.web.port=${MY_UCD_HTTP_PORT}
server.jms.port=7918
server.external.web.url=http://${IPADDRESS}:${MY_UCD_HTTP_PORT}
database.type=mysql
hibernate.connection.driver_class=org.mariadb.jdbc.Driver
hibernate.connection.username=ibm_ucd
hibernate.connection.password=ibm_ucd
hibernate.connection.url=jdbc:mysql://localhost:3306/ibm_ucd
install.server.dir=/opt/ibm-ucd/server
server.jms.mutualAuth=false
server.initial.password=${MY_UCD_PASSWORD}
rcl.server.url=27000@${MY_RLKS_IP}
" >> $MEDIA_DIR/$UCDVERSION/ibm-ucd-install/install.properties

echo "Installing UCD Server with the following properties:"
cat $MEDIA_DIR/$UCDVERSION/ibm-ucd-install/install.properties
cd $MEDIA_DIR/$UCDVERSION/ibm-ucd-install/
./install-server.sh

# restore the orig-install.properties
rm $MEDIA_DIR/$UCDVERSION/ibm-ucd-install/install.properties
mv $MEDIA_DIR/$UCDVERSION/ibm-ucd-install/orig-install.properties $MEDIA_DIR/$UCDVERSION/ibm-ucd-install/install.properties

#install UCD Server as a service
sed -i -e 's/@SERVER_USER@/root/g' -e 's/@SERVER_GROUP@/root/g' /opt/ibm-ucd/server/bin/init/server
sed -i '/SERVER_PROG=/c\SERVER_PROG=ucd_server' /opt/ibm-ucd/server/bin/init/server
cp $BASE_DIR/scripts/ucd-server.service /etc/systemd/system/ucd-server.service
systemctl enable ucd-server.service
echo "Starting the UCD Server..."
systemctl start ucd-server.service

sleep 30s
# now install udclient
unzip -q $MEDIA_DIR/$UCDVERSION/ibm-ucd-install/overlay/opt/tomcat/webapps/ROOT/tools/udclient.zip -d /opt/ibm-ucd


echo ""
echo ""
echo "###############################################################################"
echo "## Installing UrbanCode Deploy Agent                                         ##"
echo "## using JAVA_HOME=$JAVA_HOME                                                ##"
echo "###############################################################################"
echo ""
echo ""

# unzip ucdagent install archive to /tmp
unzip -q $MEDIA_DIR/$UCDVERSION/ibm-ucd-install/overlay/opt/tomcat/webapps/ROOT/tools/ibm-ucd-agent.zip -d /tmp

# echo per-deployment configurable properties
# TODO: make these values configurable from options.yml
echo "
# Installation directory of the agent
locked/agent.home=/opt/ibm-ucd/agent

# Path to the Java installation
IBM UrbanCode Deploy/java.home=/opt/ibm/ibm-java-x86_64-70

# Name of the agent (should be unique)
locked/agent.name=local

# IP or host of the server or relay to connect to
locked/agent.jms.remote.host=${IPADDRESS}
locked/agent.jms.remote.port=7918

# If the agent should verify the certificate of the server or relay it connects to
locked/agent.mutual_auth=false
" > /tmp/ibm-ucd-agent-install/vagrant-agent-install.properties

# run the "silent" install script with our generated properties
echo "Installing the UCD Agent with the following properties:"
cat /tmp/ibm-ucd-agent-install/vagrant-agent-install.properties
/tmp/ibm-ucd-agent-install/install-agent-from-file.sh /tmp/ibm-ucd-agent-install/vagrant-agent-install.properties
rm -rf /tmp/ibm-ucd-agent-install

# install udagent as a service
sed -i -e 's/AGENT_USER=/AGENT_USER=root/g' -e 's/AGENT_GROUP=/AGENT_GROUP=root/' /opt/ibm-ucd/agent/bin/init/agent
sed -i '/unique_name=/c\unique_name=ucd_agent' /opt/ibm-ucd/agent/bin/init/agent
cp $BASE_DIR/scripts/ucd-agent.service /etc/systemd/system/ucd-agent.service
systemctl enable ucd-agent.service
echo "Starting the UCD Agent..."
systemctl start ucd-agent.service


# now license the ucd server
echo "Updating UCD Server system configuration..."
cat > /tmp/config.json <<EOF
{
	"agentAutoLicense": "true",
	"artifactAgent": "local"
}
EOF
sleep 30s # give UCD enough time to start up before running this command
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -username admin -password ${MY_UCD_PASSWORD} setSystemConfiguration /tmp/config.json

echo "Requesting new Auth Token from UCD server for UCDP..."
token=`/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT}  \
-username admin \
-password ${MY_UCD_PASSWORD} createAuthToken \
-user admin \
-expireDate 12-31-2020-01:00 \
-description "Used during server installation" | python -c \
"import json; import sys;
data=json.load(sys.stdin); print data['token']"`
echo "Retrieve Auth Token: ${token}"

echo "                                                                               "
echo "                                                                               "
echo "###############################################################################"
echo "## Adding Designer agent packages to UCD                                     ##"
echo "## using JAVA_HOME=$JAVA_HOME                                                ##"
echo "###############################################################################"
echo "                                                                               "
echo "                                                                               "            
cd $MEDIA_DIR/$UCDVERSION/ibm-ucd-patterns-install/agent-package-install
./install-agent-packages.sh -s http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -a $token 

