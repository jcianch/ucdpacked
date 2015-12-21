lsblk
pvcreate /dev/sda3 
vgdisplay
vgextend centos /dev/sda3
vgdisplay centos | grep "free"
vgdisplay centos | grep "Free"
lvextend -L+280.00G /dev/centos/root 
lvextend -L+279.00G /dev/centos/root 
xfs_growfs 
xfs_growfs /
