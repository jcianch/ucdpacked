Uses Vagrant to build a VM (tested with VmWare)  with:
OpenStack (Kilo) using Packstack(see packstack.sh for which modules are enabled)
Rational License key Server (put license keys in $MEDIA_DIR/rlks814/server_license.lic)
UrbanCode Deploy (including Designer)

Install the vagrant reload plugin.
Edit parameters.sh as required for the for usernames passwords, ports etc.
The default Vagrant image used is Centos 7, which has a NIC designated "ens32". CHange this in parameters.sh and networks.sh, as also the network details in netowkrs.sh.
The rest should not require modification.
Put the extracted media somewhere and point to it via the $BASE_DIR and $MEDIA_DIR in parameters.sh.

