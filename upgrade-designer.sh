#!/bin/bash
source /vagrant/parameters.sh

echo "                                                                               "
echo "                                                                               "
echo "###############################################################################"
echo "## Upgrading UrbanCode Deploy with Patterns Web Designer                    ##"
echo "## using JAVA_HOME=$JAVA_HOME                                                ##"
echo "###############################################################################"
echo "                                                                               "
echo "                                                                               "

systemctl stop ucd-designer.service

#install UIBM CLoud Discovery Service as a service
systemctl stop ibm-cds.service


rm -rf /opt/ibm-ucd-patterns/opt/tomcat/webapps/landscaper

echo "Requesting Auth Token from UCD server for UCDP..."
token=`curl -u admin:${MY_UCD_PASSWORD} -s --insecure  http://${IPADDRESS}:${MY_UCD_HTTP_PORT}/security/authtoken | python -c \
  "import json; import sys;
data=json.load(sys.stdin);
for elem in data:
   if 'description' in elem and elem['description'] == 'Used by UCDP web designer application for authentication with this UCD server':
     print elem['token']"`
echo "Retrieve Auth Token: ${token}"

#Install UCDP web designer
cp $MEDIA_DIR/dbjar/mariadb-java-client-1.2.3.jar $MEDIA_DIR/ibm-ucd-patterns-install/web-install/media/server/lib/ext
#chmod 755 $MEDIA_DIR/ibm-ucd-patterns-install/web-install/install.sh
chmod 755 $MEDIA_DIR/ibm-ucd-patterns-install/web-install/gradlew
cd $MEDIA_DIR/ibm-ucd-patterns-install/web-install

export JAVA_OPTS="-Dlicense.accepted=Y \
-Dinstall.server.dir=/opt/ibm-ucd-patterns \
-Dinstall.server.web.host=${IPADDRESS}  \
-Dinstall.server.web.https.port=${MY_UCDP_HTTPS_PORT} \
-Dinstall.server.web.port=${MY_UCDP_HTTP_PORT} \
-Dinstall.server.web.always.secure=N  \
-Dnon-interactive=true \
-Dinstall.server.licenseServer.url=27000@${MY_RLKS_IP} \
-Dinstall.server.db.type=mysql \
-Dinstall.server.db.driver=org.mariadb.jdbc.Driver \
-Dinstall.server.db.url=jdbc:mysql://localhost:3306/ibm_ucdp \
-Dinstall.server.db.installSchema=N \
-Dinstall.server.db.username=ibm_ucdp \
-Dinstall.server.db.password=ibm_ucdp \
-Dinstall.server.deployServer.url=http://${IPADDRESS}:${MY_UCD_HTTP_PORT} \
-Dinstall.server.deployServer.authToken=$token \
-Dinstall.server.discoveryServer.url=http://${IPADDRESS}:7575"

./gradlew -sSq install

# copy mysql-jdbc.jar to tomcat home lib dir
cp $MEDIA_DIR/dbjar/mariadb-java-client-1.2.3.jar /opt/ibm-ucd-patterns/opt/tomcat/lib/

#install UCD Designer as a service
systemctl start ucd-designer.service

#install UIBM CLoud Discovery Service as a service
systemctl start ibm-cds.service


sleep 30s
# hit landscaper homepage to ensure database setup occurs
wget -q http://${IPADDRESS}:${MY_UCDP_HTTP_PORT}/landscaper
sleep 60s
