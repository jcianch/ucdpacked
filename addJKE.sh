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

PLUGINS=$MEDIA_DIR/plugins/*
for p in $PLUGINS
do 
  echo "Adding plugin $p..."
  curl -s -o /dev/null -w "%{http_code}" -u admin:${MY_UCD_PASSWORD}  -s --insecure -F "file=@$p;type=application/zip" -F "filename=$p" \
    http://${IPADDRESS}:${MY_UCD_HTTP_PORT}/rest/plugin/automationPlugin
done

curl --verbose -u admin:${MY_UCD_PASSWORD}   --insecure -F "file=@$MEDIA_DIR/landscaper/jke/jke.db/jke.db.json;type=application/json;filename=jke.db.json" \
"http://${IPADDRESS}:${MY_UCD_HTTP_PORT}/rest/deploy/component/import?upgradeType=USE_EXISTING_IF_EXISTS&processUpgradeType=USE_EXISTING_IF_EXISTS"
curl --verbose -u admin:${MY_UCD_PASSWORD}   --insecure -F "file=@$MEDIA_DIR/landscaper/jke/jke.war/jke.war.json;type=application/json;filename=jke.war.json" \
"http://${IPADDRESS}:${MY_UCD_HTTP_PORT}/rest/deploy/component/import?upgradeType=USE_EXISTING_IF_EXISTS&processUpgradeType=USE_EXISTING_IF_EXISTS"
curl --verbose -u admin:${MY_UCD_PASSWORD}   --insecure -F "file=@$MEDIA_DIR/landscaper/mysql/MySQL+Server.json;type=application/json;filename=MySQL+Server.json" \
"http://${IPADDRESS}:${MY_UCD_HTTP_PORT}/rest/deploy/component/import?upgradeType=USE_EXISTING_IF_EXISTS&processUpgradeType=USE_EXISTING_IF_EXISTS"
curl --verbose -u admin:${MY_UCD_PASSWORD}   --insecure -F "file=@$MEDIA_DIR/landscaper/wlp/WebSphere+Liberty+Profile.json;type=application/json;filename=WebSphere+Liberty+Profile.json" \
"http://${IPADDRESS}:${MY_UCD_HTTP_PORT}/rest/deploy/component/import?upgradeType=USE_EXISTING_IF_EXISTS&processUpgradeType=USE_EXISTING_IF_EXISTS"


echo "
{
  "description": "Sample JKE Banking application",
  "name": "JKE"
}" > jke.json
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createApplication jke.json

/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token  addComponentToApplication \
  -application JKE \
  -component  "MySQL Server"
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token  addComponentToApplication \
  -application JKE \
  -component  "WebSphere Liberty Profile"
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token  addComponentToApplication \
  -application JKE \
  -component  "jke.db"
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token  addComponentToApplication \
  -application JKE \
  -component  "jke.war"

echo "
[
  {
    "version": "5.6.22",
    "componentName": "MySQL Server",
  },
  {
    "version": "8.5.5.5",
    "componentName": "WebSphere Liberty Profile",
  },
  {
    "version": "1.0",
    "componentName": "jke.db",
  },
  {
    "version": "1.0",
    "componentName": "jke.war",
  }
]" > newVersions.json
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createManyVersions newVersions.json
 

echo Importing MySQL
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component "MySQL Server" -version 5.6.22 -base $MEDIA_DIR/landscaper/mysql/artifacts/ -exclude .DS_Store
echo Importing WAS Liberty
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component "WebSphere Liberty Profile" -version 8.5.5.5 -base $MEDIA_DIR/landscaper/wlp/artifacts/ -exclude .DS_Store
echo Importing JKE db
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component jke.db -version 1.0 -base $MEDIA_DIR/landscaper/jke/jke.db/artifacts/ -exclude .DS_Store
echo Importing JKE war
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component jke.war -version 1.0 -base $MEDIA_DIR/landscaper/jke/jke.war/artifacts/ -exclude .DS_Store

/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createGenericProcess "$MEDIA_DIR/landscaper/stress.json"
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createGenericProcess "$MEDIA_DIR/landscaper/destress.json"
