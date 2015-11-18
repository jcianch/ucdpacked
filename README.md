Based off of Tim Pouyer's stackinabox.
Uses Vagrant to build a VM (tested with VmWare)  with:
OpenStack (Kilo) using Packstack(see packstack.sh for which modules are enabled)
Rational License key Server (put license keys in $MEDIA_DIR/rlks814/server_license.lic)
UrbanCode Deploy (including Designer)

1. what's needed:
Vagrant (I use 1.7.4 on RedHat 6.7)
vagrant-cachier plugin (vagrant plugin install vagrant-cachier)
vagrant-reload plugin (vagrant plugin install vagrant-reload)
vagrant-vmware-workstation plugin

2. Put all the *extracted* media "somewhere", so that following directories exist:
ibm-ucd-install
ibm-ucd-patterns-install
rlks814

The ibm-ucd-patterns-install should obvously contain engine-install & web-install.
The "rlks814" should contain the content of disk1 from the RLKS 8.1.4 linux install zip.

3. Also in the same media directory create an "osimages" subdirectory and wget the  http://cloud.centos.org/centos/6/images/CentOS-6-x86_64-GenericCloud.qcow2 & http://uec-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img OpenStack images in there. If you want to add other images put them in there and modify openstack-config.sh to load them into Glance.

4. Edit parameters.sh as required for the for usernames passwords, ports etc.

5. The Vagrant box used is puppetlabs/centos-7.0-64-nocm, which has a NIC designated "ens32". If you decide to change Vagrantfile to use a different RedHat/Centos box, then also change the network device name and subnet details parameters.sh and networks.sh. The default values there reflect what I get on vmnet8 on my VMWare workstation. 

The rest should not require modification.

6. Once you're satisfied with 1-5 above just run "vagrant up" and in about 20 minutes you sould have a fully functional VM and the alldone.sh will spit out the URLs, usernames and passwords to use. A default SSH key for access to any OpenStack VMs created will be generated in "admin_key.priv" in the same directory as Vagrantfile. Or you can generate your own.

7. Once you have a working VM the same Vagrantfile can be used to just upgrade UCD, Designer and the Engine. Just put the media for the version required want as in (2) and then run
UPGRADE="UCD designer engine" vagrant up --provision

note that the vale for UPGRADE is case-sensitive but can have "UCD", "designer", "engine" in any order or combination. So to just upgrade UCD run
UPGRADE="UCD" vagrant up --provision

8. you can also run ovf.sh to autogenerate an OVF for the VM. But be aware that for some reason the VT-X setting (vhv.enable) is not passed into the generaed OVF, so will need to be manually set once imported.

