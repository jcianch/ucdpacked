#!/bin/bash
source /vagrant/parameters.sh
echo "Requesting new Auth Token from UCD server .."
token=`/opt/ibm-ucd/udclient/udclient -weburl http://${IPADDRESS}:${MY_UCD_HTTP_PORT}  \
-username admin \
-password ${MY_UCD_PASSWORD} createAuthToken \
-user admin \
-expireDate 12-31-2020-01:00 \
-description "Used for agent relay " | python -c \
"import json; import sys;
data=json.load(sys.stdin); print data['token']"`
echo "Retrieve Auth Token: ${token}"

curl -u admin:${MY_UCD_PASSWORD}  http://${IPADDRESS}:${MY_UCD_HTTP_PORT}/tools/agent-relay.zip > agent-relay.zip

unzip -q -o ./agent-relay.zip -d /tmp
rm -f agent-relay.zip

cd /tmp/agent-relay-install
echo "/opt/ibm/agentrelay
Y
/etc/alternatives/jre
agent-relay
0.0.0.0
20080
7916
Y
${IPADDRESS}
7918
N
N
N
http://${IPADDRESS}:${MY_UCD_HTTP_PORT}
${token}
root
root
" | ./install.sh

