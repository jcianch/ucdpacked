#!/bin/bash
source /vagrant/parameters.sh

#ssh -i /vagrant/images/aws.pem -f -N -R *:20080:192.168.27.100:8081 ubuntu@54.165.178.106
set -o errexit

key=${1:-~/default.pem}
pubhost=${2:-localhost}
privhost=${3:-localhost}
user=${4:-ubuntu}

# default values match UCD Agent Relay default port values
jmsPort=${5:-7916}
httpPort=${6:-20080}
codestationPort=${7:-20081}

ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
-i $key -tt $user@$pubhost &>>configssh.log <<EOF

echo "\
GatewayPorts clientspecified" | sudo tee -a /etc/ssh/sshd_config
echo "\
ClientAliveInterval 5" | sudo tee -a /etc/ssh/sshd_config
sudo initctl restart ssh

exit
EOF

ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
-i $key -f -N -R $privhost:$httpPort:${IPADDRESS}:$httpPort \
-R $privhost:$codestationPort:${IPADDRESS}:$codestationPort \
-R $privhost:$jmsPort:${IPADDRESS}:$jmsPort $user@$pubhost 

ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
-i $key -tt $user@$pubhost <<EOF
sudo netstat -tulpn
exit
EOF
