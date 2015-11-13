#!/bin/bash
source /vagrant/parameters.sh

echo "                                                                               "
echo "                                                                               "
echo "###############################################################################"
echo "## Installing UrbanCode Deploy with Patterns Web Designer                    ##"
echo "## using JAVA_HOME=$JAVA_HOME                                                ##"
echo "###############################################################################"
echo "                                                                               "
echo "                                                                               "

# locate the admin tenant uuid
echo "Retrieving OpenStack 'admin' tenant id from OpenStack server"

# request auth token from OpenStack Keystone server
cat > OStokenrequest.json <<EOF
{ "auth":
  { "tenantName": "admin",
    "passwordCredentials": {
        "username": "admin",
        "password": "${MY_OS_PASSWORD}"
    }
  }
}
EOF
OS_TOKEN=`curl -s -H "Content-Type: application/json" \
  -d @OStokenrequest.json  http://${IPADDRESS}:5000/v2.0/tokens | python -c "import json; import sys;
data=json.load(sys.stdin); print data['access']['token']['id']"`
echo "Found OpenStack 'admin' auth token: ${OS_TOKEN}"

# request listing of all tenants in OpenStack server, send AuthToken we retrieve earlier
tenant=`curl -s -H "X-Auth-Token:${OS_TOKEN}" http://${IPADDRESS}:35357/v2.0/tenants | python -c \
"import json; import sys;
data=json.load(sys.stdin);
for index in range(len(data['tenants'])):
    if data['tenants'][index]['name'] == 'admin':
      print data['tenants'][index]['id']"`

echo "Found 'admin' tenant id: ${tenant}"

# create new auth token for use by UCDP web-designer
echo "Requesting new Auth Token from UCD server for UCDP..."
token=`/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} \
-username admin \
-password ${MY_UCD_PASSWORD} createAuthToken \
-user admin \
-expireDate 12-31-2020-01:00 \
-description "Used by UCDP web designer application for authentication with this UCD server" | python -c \
"import json; import sys;
data=json.load(sys.stdin); print data['token']"`
echo "Retrieve Auth Token: ${token}"

# create new pattern integration (have to do this with curl b/c udclient does not support it yet)
echo "Adding new Pattern Integration on UCD Server for UCDP"
# execute put with json that will define a new pattern integration with the 'landscaper' server
cat > addIntegration.json <<EOF
{
  "name": "landscaper",
  "description": "",
  "properties": {
    "landscaperUrl": "http://${IPADDRESS}:${MY_UCDP_HTTP_PORT}/landscaper",
    "landscaperUser": "ucdpadmin",
    "landscaperPassword": "ucdpadmin"
  }
}
EOF
curl -u admin:${MY_UCD_PASSWORD} -s --insecure -b cookies.txt -H "Accept: application/json" -X PUT \
  -d @addIntegration.json http://${IPADDRESS}:${MY_UCD_HTTP_PORT}/rest/integration/pattern

# create mysql database for UCD+P
mysql --user=root -p${MY_OS_PASSWORD} -e "CREATE USER 'ibm_ucdp'@'localhost' IDENTIFIED BY 'ibm_ucdp';
CREATE DATABASE ibm_ucdp;
GRANT ALL ON ibm_ucdp.* TO 'ibm_ucdp'@'%' IDENTIFIED BY 'ibm_ucdp' WITH GRANT OPTION;"

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
-Dinstall.server.db.installSchema=Y \
-Dinstall.server.db.username=ibm_ucdp \
-Dinstall.server.db.password=ibm_ucdp \
-Dinstall.server.deployServer.url=http://${IPADDRESS}:${MY_UCD_HTTP_PORT} \
-Dinstall.server.deployServer.authToken=$token \
-Dinstall.server.discoveryServer.url=http://${IPADDRESS}:7575"

./gradlew -sSq install

# copy mysql-jdbc.jar to tomcat home lib dir
cp $MEDIA_DIR/dbjar/mariadb-java-client-1.2.3.jar /opt/ibm-ucd-patterns/opt/tomcat/lib/

/opt/ibm-ucd-patterns/bin/server start

#TODO add UCDP and CDS as service
# cp /opt/ibm-ucd-patterns/bin/server /etc/init.d/ucdp
# chmod +x /etc/init.d/ucdp
# update-rc.d ucdp defaults 98
# service ucdp start

# cp /vagrant/landscaper/ibmcds /etc/init.d/ibmcds
# chmod +x /etc/init.d/ibmcds
# update-rc.d ibmcds defaults 99
# service ibmcds start

#setup CDS
cp $MEDIA_DIR/landscaper/cloud_setting.conf /opt/cloud_setting.conf
echo export CLOUDDISCOVERYSERVICE_SETTINGS_FILE=/opt/cloud_setting.conf > /etc/profile.d/ibmcds.sh
export CLOUDDISCOVERYSERVICE_SETTINGS_FILE=/opt/cloud_setting.conf
/opt/ibm-ucd-patterns/opt/udeploy-patterns-cloud-discovery-service/runserver &


sleep 60s
# hit landscaper homepage to ensure database setup occurs
wget -q http://${IPADDRESS}:${MY_UCDP_HTTP_PORT}/landscaper
sleep 30s
#Add UCD integration to UCDP System Settings
cat  > systemSettings.json <<EOF
{"designerServerUrl":"http://${IPADDRESS}:${MY_UCDP_HTTP_PORT}/landscaper",
"cloudDiscoveryServer":"http://${IPADDRESS}:7575",
"ucdUrl":"http://${IPADDRESS}:${MY_UCD_HTTP_PORT}",
"tokenBasedAuthentication":true,
"ucdToken":"${token}",
"chefUrl":"","chefValidatorName":"",
"chefValidatorKey":"",
"chefValidatorKeyUrl":"",
"chefClientName":"",
"chefClientKey":"",
"licenseServer":"27000@${MY_RLKS_IP}"}
EOF
curl -u ucdpadmin:ucdpadmin  -H 'Content-Type: application/json' -d @systemSettings.json \
http://${IPADDRESS}:${MY_UCDP_HTTP_PORT}/landscaper/security/system/configuration -X PUT


#Add OpenStack Cloud Provider
cat > cloudProvider.json <<EOF
{
  "description": "OpenStack Local",
  "name": "OpenStack Local",
  "properties": [
    {
      "label": "",
      "name": "timeoutMins",
      "secure": false,
      "value": "60"
    },
    {
      "label": "",
      "name": "url",
      "secure": false,
      "value": "http://${IPADDRESS}:5000/v2.0"
    },
    {
      "name": "useDefaultOrchestration",
      "secure": false,
      "value": "true"
    },
    {
      "name":"facing",
      "value":"PUBLIC",
      "secure":false
    },
    {
      "name":"orchestrationEngineUrl",
      "value":"",
      "secure":false
    }
  ],
  "type": "OPENSTACK"
}
EOF
curl -u ucdpadmin:ucdpadmin  -H 'Content-Type: application/json' -d @cloudProvider.json \
http://${IPADDRESS}:${MY_UCDP_HTTP_PORT}/landscaper/security/cloudprovider/ -X POST -o cloudProvider.rsp
#add OpenStackProject
CLOUDPROVIDER_ID=`awk -F: '{print $2}' cloudProvider.rsp | awk -F, '{print $1}'`

cat > cloudProject.json <<EOF
{
  "cloudProviderId": "${CLOUDPROVIDER_ID//\"}",
  "description": "OpenStack Local Cloud Provider",
  "name": "admin",
      "properties": [
        {
            "name": "functionalId",
            "value": "admin",
            "secure": "false"
        },
        {
            "name": "functionalPassword",
            "value": "${MY_OS_PASSWORD}",
            "secure": true
        }
    ]
}
EOF
curl -u ucdpadmin:ucdpadmin  -H 'Content-Type: application/json' -d @cloudProject.json \
http://${IPADDRESS}:${MY_UCDP_HTTP_PORT}/landscaper/security/cloudproject/ -X POST -o cloudProject.rsp

#Add project to Internal Team
curl -u ucdpadmin:ucdpadmin  http://${IPADDRESS}:${MY_UCDP_HTTP_PORT}/landscaper/security/team/ -o getTeam.rsp
TEAM_ID=`awk -F: '{print $2}' getTeam.rsp | awk -F, '{print $1}'`
curl -u ucdpadmin:ucdpadmin  http://${IPADDRESS}:${MY_UCDP_HTTP_PORT}/landscaper/security/cloudproject/ -o getCloudProject.rsp
CLOUDPROJECT_ID=`awk -F: '{print $2}' getCloudProject.rsp | awk -F, '{print $1}'`

cat > cloudAuthorisation.json <<EOF
{
   "name":"Internal Team",
   "resources":[],
   "cloud_projects":["${CLOUDPROJECT_ID//\"}"]
}   
EOF
curl -u ucdpadmin:ucdpadmin  -H 'Content-Type: application/json' -d @cloudAuthorisation.json \
http://${IPADDRESS}:${MY_UCDP_HTTP_PORT}/landscaper/security/team/${TEAM_ID//\"} -X PUT -o cloudAuthorisation.rsp


cp $MEDIA_DIR/landscaper/tunnel.sh /home/vagrant
chmod 755 /home/vagrant/tunnel.sh
chown vagrant:vagrant /home/vagrant/tunnel.sh

cp $MEDIA_DIR/landscaper/aws-setup.sh /home/vagrant/aws-setup.sh
chmod 755 /home/vagrant/aws-setup.sh
chown vagrant:vagrant /home/vagrant/aws-setup.sh

cp $MEDIA_DIR/landscaper/sl-setup.sh /home/vagrant/sl-setup.sh
chmod 755 /home/vagrant/sl-setup.sh
chown vagrant:vagrant /home/vagrant/sl-setup.sh
sleep 60

# Add tutorial content to image
#cp $MEDIA_DIR/landscaper/tutorials/jke.js /opt/ibm-ucd-patterns/opt/tomcat/webapps/landscaper/static/6.*/js/tutorial/nls/TutorialContent.js
