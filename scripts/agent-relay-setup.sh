#!/bin/bash

curl -u admin:admin http://192.168.27.100:8081/tools/agent-relay.zip > agent-relay.zip

unzip -q -o ./agent-relay.zip -d /tmp
rm -f agent-relay.zip

/tmp/agent-relay-install
