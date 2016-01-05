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
GatewayPorts yes " | sudo tee -a /etc/ssh/sshd_config
sudo initctl restart ssh

exit
EOF
sshpass -p $rootpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
-o TCPKeepAlive=no -o ServerAliveInterval=10 -2 -f -N -T \
-R 20080:${IPADDRESS}:20080 \
-R 20081:${IPADDRESS}:20081 \
-R 7916:${IPADDRESS}:7916 \
root@$publicip 

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
