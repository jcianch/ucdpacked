#!/bin/bash
#invoked by centos-expandLVM
pvcreate /dev/sda3 
vgextend centos /dev/sda3
lvextend -L+240.00G /dev/centos/root 
xfs_growfs /

