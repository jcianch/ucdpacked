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
echo "## Creating MobileFirst Application in UCD                                    ##"
echo "## using JAVA_HOME=$JAVA_HOME                                                ##"
echo "###############################################################################"
echo "                                                                               "
echo "        
PLUGINS=$MEDIA_DIR/plugins/*
for p in $PLUGINS
do 
  echo "Adding plugin $p..."
  curl --verbose -u admin:${MY_UCD_PASSWORD}  -s --insecure -F "file=@$p;type=application/zip" -F "filename=$p" \
    http://${IPADDRESS}:${MY_UCD_HTTP_PORT}/rest/plugin/automationPlugin
done
curl --verbose -u admin:${MY_UCD_PASSWORD}   --insecure -F "file=@$MEDIA_DIR/mobilefirst/MobileFirst.json;type=application/json;filename=MobileFirst.json" \
"http://${IPADDRESS}:${MY_UCD_HTTP_PORT}/rest/deploy/application/import?upgradeType=UPGRADE_IF_EXISTS&compTempUpgradeType=UPGRADE_IF_EXISTS&processUpgradeType=UPGRADE_IF_EXISTS"

echo Creating versions and files
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createVersion -component "IBM DB2" -name "10.5.0.5"
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createVersion -component "IBM HTTP Server" -name "8.5.0.20120501_1108"
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createVersion -component "IBM Installation Manager" -name  "1.8.3.0"
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createVersion -component "IBM MobileFirst Analytics Server" -name "7.1.0"
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createVersion -component "IBM MobileFirst DB" -name "7.0.0"
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createVersion -component "IBM MobileFirst Platform Server" -name  "7.1.0"
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createVersion -component "IBM MobileFirst Sample App" -name  "7.0.0"
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createVersion -component "IBM WAS Liberty" -name  "8.5.5.7"

/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component "IBM DB2" -version "10.5.0.5" -base "$MEDIA_DIR/mobilefirst/artifacts/IBM DB2"
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component "IBM HTTP Server" -version "8.5.0.20120501_1108" -base "$MEDIA_DIR/mobilefirst/artifacts/IBM HTTP Server" 
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component "IBM Installation Manager" -version  "1.8.3.0" -base "$MEDIA_DIR/mobilefirst/artifacts/IBM Installation Manager"
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component "IBM MobileFirst Analytics Server" -version "7.1.0" -base "$MEDIA_DIR/mobilefirst/artifacts/IBM MobileFirst Analytics Server" 
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component "IBM MobileFirst DB" -version "7.0.0" -base "$MEDIA_DIR/mobilefirst/artifacts/IBM MobileFirst DB" 
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component "IBM MobileFirst Platform Server" -version  "7.1.0" -base "$MEDIA_DIR/mobilefirst/artifacts/IBM MobileFirst Platform Server" 
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component "IBM MobileFirst Sample App" -version  "7.0.0" -base "$MEDIA_DIR/mobilefirst/artifacts/IBM MobileFirst Sample App" 
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component "IBM MobileFirst StrongLoop" -version  "1.0.0" -base "$MEDIA_DIR/mobilefirst/artifacts/IBM MobileFirst StrongLoop"
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component "IBM WAS Liberty" -version  "8.5.5.7" -base "$MEDIA_DIR/mobilefirst/artifacts/BM WAS Liberty" 

