#!/bin/bash
source /vagrant/parameters.sh

yum install -y unzip
# install java
mkdir -p /opt/IBM/
cp -R $MEDIA_DIR/ibm-ucd-patterns-install/web-install/media/server/java /opt/IBM/
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
cp $MEDIA_DIR/dbjar/mariadb-java-client-1.2.3.jar $MEDIA_DIR/ibm-ucd-install/lib/ext

# make copy of original properies file
cp $MEDIA_DIR/ibm-ucd-install/install.properties $MEDIA_DIR/ibm-ucd-install/orig-install.properties

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
" >> $MEDIA_DIR/ibm-ucd-install/install.properties

echo "Installing UCD Server with the following properties:"
cat $MEDIA_DIR/ibm-ucd-install/install.properties
cd $MEDIA_DIR/ibm-ucd-install/
./install-server.sh

# restore the orig-install.properties
rm $MEDIA_DIR/ibm-ucd-install/install.properties
mv $MEDIA_DIR/ibm-ucd-install/orig-install.properties $MEDIA_DIR/ibm-ucd-install/install.properties

# now start the ucd server
/opt/ibm-ucd/server/bin/server start

# now install udclient
unzip -q $MEDIA_DIR/ibm-ucd-install/overlay/opt/tomcat/webapps/ROOT/tools/udclient.zip -d /opt/ibm-ucd


echo ""
echo ""
echo "###############################################################################"
echo "## Installing UrbanCode Deploy Agent                                         ##"
echo "## using JAVA_HOME=$JAVA_HOME                                                ##"
echo "###############################################################################"
echo ""
echo ""

# unzip ucdagent install archive to /tmp
unzip -q $MEDIA_DIR/ibm-ucd-install/overlay/opt/tomcat/webapps/ROOT/tools/ibm-ucd-agent.zip -d /tmp

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
# now start the udagent
echo "Starting the UCD Agent..."
/opt/ibm-ucd/agent/bin/agent start

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

#TODO install UCD Server as a service
# sed -e 's/@SERVER_USER@/root/g' -e 's/@SERVER_GROUP@/root/g' /opt/ibm-ucd/server/bin/init/server > /etc/init.d/ucd
# chmod +x /etc/init.d/ucd
# chown root:root /etc/init.d/ucd
# update-rc.d ucd defaults
# update-rc.d ucd enable

# install udagent as a service
# sed -e 's/AGENT_USER=/AGENT_USER=root/g' -e 's/AGENT_GROUP=/AGENT_GROUP=root/' /opt/ibm-ucd/agent/bin/init/agent > /etc/init.d/udagent

# ln -s /opt/ibm-ucd/agent/bin/agent /opt/ibm-ucd/agent/bin/ibm-ucdagent

# chmod +x /etc/init.d/udagent
# chown root:root /etc/init.d/udagent
# update-rc.d udagent defaults
# update-rc.d udagent enable

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
$MEDIA_DIR/ibm-ucd-patterns-install/agent-package-install/install-agent-packages.sh -s http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -a $token 

echo "                                                                               "
echo "                                                                               "
echo "###############################################################################"
echo "## Creating Sample JKE Application in UCD                                    ##"
echo "## using JAVA_HOME=$JAVA_HOME                                                ##"
echo "###############################################################################"
echo "                                                                               "
echo "                                                                               "


# add example jke application to UCD
curl --verbose -u admin:${MY_UCD_PASSWORD}  -s --insecure -F "file=@$MEDIA_DIR/landscaper/plugins/WebSphere-Liberty-3.641636.zip;type=application/zip" -F "filename=WebSphere-Liberty-3.641636.zip" http://${IPADDRESS}:${MY_UCD_HTTP_PORT}/rest/plugin/automationPlugin
echo Importing MySQL
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createComponent $MEDIA_DIR/landscaper/mysql/MySQL+Server.json
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createComponentProcess $MEDIA_DIR/landscaper/mysql/deploy-ubuntu.json
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createComponentProcess $MEDIA_DIR/landscaper/mysql/deploy-windows.json
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createComponentProcess $MEDIA_DIR/landscaper/mysql/deploy.json
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createVersion -component "MySQL Server" -name 5.6.22
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component "MySQL Server" -version 5.6.22 -base $MEDIA_DIR/landscaper/mysql/artifacts/ -exclude .DS_Store
echo Importing WAS Liberty
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createComponent $MEDIA_DIR/landscaper/wlp/WebSphere+Liberty+Profile.json
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createComponentProcess $MEDIA_DIR/landscaper/wlp/open-firewall-port-ubuntu.json
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createComponentProcess $MEDIA_DIR/landscaper/wlp/open-firewall-port-windows.json
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createComponentProcess $MEDIA_DIR/landscaper/wlp/deploy.json
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createVersion -component "WebSphere Liberty Profile" -name 8.5.5.5
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component "WebSphere Liberty Profile" -version 8.5.5.5 -base $MEDIA_DIR/landscaper/wlp/artifacts/ -exclude .DS_Store
echo Importing JKE db
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createComponent $MEDIA_DIR/landscaper/jke/jke.db/jke.db.json
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createComponentProcess $MEDIA_DIR/landscaper/jke/jke.db/deploy.json
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createVersion -component jke.db -name 1.0
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component jke.db -version 1.0 -base $MEDIA_DIR/landscaper/jke/jke.db/artifacts/ -exclude .DS_Store
echo Importing JKE war
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createComponent $MEDIA_DIR/landscaper/jke/jke.war/jke.war.json
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createComponentProcess $MEDIA_DIR/landscaper/jke/jke.war/deploy.json
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createVersion -component jke.war -name 1.0
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component jke.war -version 1.0 -base $MEDIA_DIR/landscaper/jke/jke.war/artifacts/ -exclude .DS_Store
echo Importing JKE Application
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createApplication $MEDIA_DIR/landscaper/jke/JKE.json
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addComponentToApplication -component "MySQL Server" -application JKE
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addComponentToApplication -component "WebSphere Liberty Profile" -application JKE
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addComponentToApplication -component jke.db -application JKE
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addComponentToApplication -component jke.war -application JKE

