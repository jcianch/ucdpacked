#!/bin/bash
source /vagrant/parameters.sh

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
echo "## Creating Sample JKE Application in UCD                                    ##"
echo "## using JAVA_HOME=$JAVA_HOME                                                ##"
echo "###############################################################################"
echo "                                                                               "
echo "                                                                               "


# add example jke application to UCD
curl --verbose -u admin:${MY_UCD_PASSWORD}  -s --insecure -F "file=@$MEDIA_DIR/landscaper/plugins/WebSphere-Liberty-3.641636.zip;type=application/zip" -F "filename=WebSphere-Liberty-3.641636.zip" http://${IPADDRESS}:${MY_UCD_HTTP_PORT}/rest/plugin/automationPlugin
curl --verbose -u admin:${MY_UCD_PASSWORD}   --insecure -F "file=@$MEDIA_DIR/landscaper/jke/JKE.json;type=application/json;filename=JKE.json" \
"http://${IPADDRESS}:${MY_UCD_HTTP_PORT}/rest/deploy/application/import?upgradeType=UPGRADE_IF_EXISTS&compTempUpgradeType=UPGRADE_IF_EXISTS&processUpgradeType=UPGRADE_IF_EXISTS"

echo Importing MySQL
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createVersion -component "MySQL Server" -name 5.6.22
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component "MySQL Server" -version 5.6.22 -base $MEDIA_DIR/landscaper/mysql/artifacts/ -exclude .DS_Store
echo Importing WAS Liberty
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createVersion -component "WebSphere Liberty Profile" -name 8.5.5.5
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component "WebSphere Liberty Profile" -version 8.5.5.5 -base $MEDIA_DIR/landscaper/wlp/artifacts/ -exclude .DS_Store
echo Importing JKE db
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createVersion -component jke.db -name 1.0
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component jke.db -version 1.0 -base $MEDIA_DIR/landscaper/jke/jke.db/artifacts/ -exclude .DS_Store
echo Importing JKE war
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createVersion -component jke.war -name 1.0
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component jke.war -version 1.0 -base $MEDIA_DIR/landscaper/jke/jke.war/artifacts/ -exclude .DS_Store

