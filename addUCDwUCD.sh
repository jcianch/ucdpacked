#!/bin/bash
source /vagrant/parameters.sh

echo "Requesting new Auth Token from UCD server ."
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
echo "## Creating UCDwUCD Application in UCD                                    ##"
echo "## using JAVA_HOME=$JAVA_HOME                                                ##"
echo "###############################################################################"
echo "                                                                               "
PLUGINS=$MEDIA_DIR/plugins/*
for p in $PLUGINS
do 
  echo "Adding plugin $p..."
  curl -s -o /dev/null -w "%{http_code}" -u admin:${MY_UCD_PASSWORD}  -s --insecure -F "file=@$p;type=application/zip" -F "filename=$p" \
    http://${IPADDRESS}:${MY_UCD_HTTP_PORT}/rest/plugin/automationPlugin
done
echo "Importing UCDwUCD application"
curl -s -o /dev/null -w "%{http_code}" -u admin:${MY_UCD_PASSWORD}   --insecure -F "file=@$MEDIA_DIR/ucdwucd/UCDwUCD.json;type=application/json;filename=UCDwUCD.json" \
"http://${IPADDRESS}:${MY_UCD_HTTP_PORT}/rest/deploy/application/import?upgradeType=UPGRADE_IF_EXISTS&compTempUpgradeType=UPGRADE_IF_EXISTS&processUpgradeType=UPGRADE_IF_EXISTS"

echo Creating versions and files
cat > newVersions.json <<'EOF'
[
  {
    "version": "5.6",
    "componentName": "MySQL"
  },
  {
    "version": "7",
    "componentName": "openjdk"
  },
  {
    "version": "11gR2",
    "componentName": "Oracle"
  },
  {
    "version": "8.1.4",
    "componentName": "RLKS"
  },
  {
    "version": "6.2.1",
    "componentName": "ucd-designer"
  },
  {
    "version": "6.2.1",
    "componentName": "ucd-engine"
  },
  {
    "version": "6.2.1",
    "componentName": "ucd-server"
  },
  {
    "version": "6.2.1",
    "componentName": "ucd-server.db"
  },
  {
    "version": "1.0",
    "componentName": "utilities"
  }
]
EOF
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token createManyVersions newVersions.json

/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component "MySQL" -version "5.6" -base "$MEDIA_DIR/ucdwucd/artifacts/MySQL"
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component "openjdk" -version "7" -base "$MEDIA_DIR/ucdwucd/artifacts/openjdk"
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component "Oracle" -version "11gR2" -base "$MEDIA_DIR/ucdwucd/artifacts/Oracle"
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component "RLKS" -version "8.1.4" -base "$MEDIA_DIR/ucdwucd/artifacts/RLKS"
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component "ucd-designer" -version "6.2.1" -base "$MEDIA_DIR/ucdwucd/artifacts/ucd-designer"
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component "ucd-engine" -version "6.2.1" -base "$MEDIA_DIR/ucdwucd/artifacts/ucd-engine"
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component "ucd-server" -version "6.2.1" -base "$MEDIA_DIR/ucdwucd/artifacts/ucd-server"
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component "ucd-server.db" -version "6.2.1" -base "$MEDIA_DIR/ucdwucd/artifacts/ucd-server.db"
/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT} -authtoken $token addVersionFiles -component "utilities" -version "1.0" -base "$MEDIA_DIR/ucdwucd/artifacts/utilities"
