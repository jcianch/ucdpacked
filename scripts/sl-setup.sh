#!/bin/bash
source /vagrant/parameters.sh
echo " "
echo " "
echo "#######################################################################"
echo "   This script will connect this UCDP image to SoftLayer (SL)!"
echo " "
echo "    **** You will need to run this command each time you ****"
echo "    ****   restart this image and want to deploy to SL.  ****"
echo " "
echo " ++ You must provide your own SL username and password/access key"
echo " "
echo " ++ Please enter 'public' for endpoint"
echo " "
echo " ++ This script will instantiate a 2 core 1024 MB RAM instance on your"
echo "     SL account This instance is necessary in order for the UrbanCode"
echo "     Deploy agents to be able to communicate back into this image from"
echo "     outside your current network."
echo " "
echo "    If you shutdown the instance on SL the communication link will be"
echo "     broken and unrepairable.  You would have to run this script again"
echo "     to bring up another instance on SL to manage the communication link"
echo " "
echo "    This script will generate a new script 'sl-shutdown.sh' that you"
echo "     can use to shutdown the instance on SL so that you will no longer"
echo "     be charged for it's use."
echo "#######################################################################"
echo " "
echo " "

slcli config setup

echo " ++ Please enter a SL DataCenter that is nearest to your physical location"
echo " "
echo "           The SoftLayer Regions are:"
echo " "
echo "           'dal01' ----------------- US (Dallas)"
echo "           'dal05' ----------------- US (Dallas)"
echo "           'dal06' ----------------- US (Dallas)"
echo "           'dal09' ----------------- US (Dallas)"
echo "           'sea01' ----------------- US (Seatle)"
echo "           'sjc01' ----------------- US (San Jose)"
echo "           'hou02' ----------------- US (Houston)"
echo "           'wdc01' ----------------- US (Washington DC)"
echo "           'tor01' ----------------- Canada (Toronto)"
echo "           'ams01' ----------------- Europe (Amsterdam)"
echo "           'lon02' ----------------- Europe (London)"
echo "           'par01' ----------------- Europe (Paris)"
echo "           'sng01' ----------------- Asia (Singapore)"
echo " "
echo -n "Enter your preferred SL DataCenter [dal01]: "
read datacenter

slcli -y vs create \
--hostname=ucdpagentrelay \
--domain=softlayer.com \
--cpu=2 \
--memory=1024 \
--os=UBUNTU_14_64 \
--datacenter=$datacenter \
--billing hourly 

echo "waiting for Agent Relay instance to boot on SL..."
echo "(this will take a few minutes please be patient)"
slcli vs ready 'ucdpagentrelay' --wait=600

privateip=$(slcli vs detail ucdpagentrelay --passwords | awk '/private_ip/ {print $2}')
publicip=$(slcli vs detail ucdpagentrelay --passwords | awk '/public_ip/ {print $2}')
rootpass=$(slcli vs detail ucdpagentrelay --passwords | awk '/root/ {print $3}')

sudo yum install -y sshpass &>>.sl-setup-log

sshpass -p $rootpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
-tt root@$publicip &>>.sl-setup-log <<EOF

echo "\
GatewayPorts clientspecified" | sudo tee -a /etc/ssh/sshd_config
sudo initctl restart ssh

exit
EOF

sudo sshpass -p $rootpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
-f -N -R $privateip:20080:${IPADDRESS}:20080 \
-R $privateip:20081:${IPADDRESS}:20081 \
-R $privateip:7916:${IPADDRESS}:7916 root@$publicip &>>.sl-setup-log

# setup SL Cloud Provider in UCDP

wget -q http://stedolan.github.io/jq/download/linux64/jq &>>.sl-setup-log
chmod 755 jq
export PATH=$PATH:.

export SL_ID=`cat ~/.softlayer | grep username | head -1 | awk '{gsub(/\"/, "");gsub(/,/,""); print $3}'`
export SL_KEY=`cat ~/.softlayer | grep api_key | head -1 | awk '{gsub(/\"/, "");gsub(/,/,""); print $3}'`

export SL_CLOUD_PROVIDER_ID=`curl -s -u ucdpadmin:ucdpadmin \
  http://${IPADDRESS}:${MY_UCDP_HTTP_PORT}/landscaper/security/cloudprovider/ | python -c \
  "import json; import sys;
data=json.load(sys.stdin);
for index in range(len(data)):
  if data[index]['name'] == 'SoftLayer':
    print data[index]['id']"`

if [[ "$SL_CLOUD_PROVIDER_ID" == "" ]]; then
  rm -f ./sl-provider.json
  cat >> ./sl-provider.json <<EOF
  {
    "name": "SoftLayer",
    "type": "SOFTLAYER",
    "costCenterId": "",
    "properties": [
      {
        "name": "url",
        "value": "http://${IPADDRESS}:5000/v2.0",
        "secure": false
      },{
        "name": "timeoutMins",
        "value": "60",
        "secure": false
      },{
        "name": "useDefaultOrchestration",
        "value": "true",
        "secure": false
      },{
        "name": "orchestrationEngineUrl",
        "value": "",
        "secure": false
      }
    ]
  }
EOF

  curl -s -u ucdpadmin:ucdpadmin \
       -H 'Content-Type: application/json' \
       -d @sl-provider.json \
       http://${IPADDRESS}:${MY_UCDP_HTTP_PORT}/landscaper/security/cloudprovider/ -X POST -o cloudProvider.rsp
fi
SL_CLOUD_PROVIDER_ID=`awk -F: '{print $2}' cloudProvider.rsp | awk -F, '{print $1}'`
echo "SL_CLOUD_PROVIDER_ID: $SL_CLOUD_PROVIDER_ID" &>>.sl-setup-log

export CLOUD_PROJECTS=`curl -s -u ucdpadmin:ucdpadmin \
http://${IPADDRESS}:${MY_UCDP_HTTP_PORT}/landscaper/security/cloudproject/`

export SL_CLOUD_PROJECT_ID=`echo ${CLOUD_PROJECTS} | python -c \
"import json; import sys;
data=json.load(sys.stdin);
for index in range(len(data)):
  if data[index]['displayName'] == 'admin@SoftLayer':
    print data[index]['id']"`

if [[ "$SL_CLOUD_PROJECT_ID" == "" ]]; then
  rm -f ./sl-cloud-project.json
  cat > ./sl-cloud-project.json <<EOF
  {
    "name": "admin",
    "cloudProviderId": "${SL_CLOUD_PROVIDER_ID//\"}",
    "properties": [
      {
        "name": "functionalId",
        "value": "admin",
        "secure": false
      },{
        "name": "functionalPassword",
        "value": "${MY_OS_PASSWORD}",
        "secure": true
      },{
        "name": "SoftLayerUser",
        "value": "$SL_ID",
        "secure": false
      },{
        "name": "SoftLayerApiKey",
        "value": "$SL_KEY",
        "secure": false
      },{
        "name": "defaultRegion",
        "value": "RegionOne",
        "secure": false
      }
    ]
  }
EOF

  curl -s -u ucdpadmin:ucdpadmin \
       -H 'Content-Type: application/json' \
       -d @sl-cloud-project.json \
       http://${IPADDRESS}:${MY_UCDP_HTTP_PORT}/landscaper/security/cloudproject/ -X POST -o cloudProject.rsp
fi
export SL_CLOUD_PROJECT_ID=`awk -F: '{print $2}' cloudProject.rsp | awk -F, '{print $1}'`
echo "SL_CLOUD_PROJECT_ID: $SL_CLOUD_PROJECT_ID" &>>.sl-setup-log

export CURR_CLOUD_PROJECT_IDS=`echo ${CLOUD_PROJECTS} | python -c \
"import json; import sys;
data=json.load(sys.stdin);
for index in range(len(data)):
    print '\"' + data[index]['id'] + '\"' + ','"`

cat > cloudAuthorisation.json <<EOF
{
   "name":"Internal Team",
   "resources":[],
   "cloud_projects":[${CURR_CLOUD_PROJECT_IDS}${SL_CLOUD_PROJECT_ID}]
}   
EOF
curl -u ucdpadmin:ucdpadmin  http://${IPADDRESS}:${MY_UCDP_HTTP_PORT}/landscaper/security/team/ -o getTeam.rsp
TEAM_ID=`awk -F: '{print $2}' getTeam.rsp | awk -F, '{print $1}'`

curl -u ucdpadmin:ucdpadmin  -H 'Content-Type: application/json' -d @cloudAuthorisation.json \
http://${IPADDRESS}:${MY_UCDP_HTTP_PORT}/landscaper/security/team/${TEAM_ID//\"} -X PUT -o cloudAuthorisation.rsp

rm -f ./sl-shutdown.sh
cat > ./sl-shutdown.sh <<EOF
#!/bin/bash

# terminates the UCD Agent Relay on SoftLayer (SL)
# this script is dynamically created everytime you run './sl-setup.sh' and
# cannot be used to shutdown anything other than the instance that was started
# with the last execution of the './sl-setup.sh' script
echo "waiting for Agent Relay instance to shutdown on SL in datacenter $datacenter..."
echo "(this will take a few minutes please be patient)"
slcli -y vs cancel ucdpagentrelay
EOF

chmod 755 ./sl-shutdown.sh

echo " "
echo " "
echo "#######################################################################"
echo "This UCDP image is now configured to use SoftLayer (SL)!"
echo "    **** You will need to run this command each time you ****"
echo "    **** restart this image and want to deploy to SL.    ****"
echo " "
echo "You must use the following parameters when provisioning from UCDP"
echo "to enable the UCD Agent's to talk to the UCD server on this image"
echo " "
echo "AGENT RELAY PUBLIC HOST: http://$publicip"
echo " "
echo "Run the following command to terminate the Agent Relay instance on SL:"
echo " "
echo "./sl-shutdown.sh"
echo " "
echo "#######################################################################"
echo " "
echo " "
