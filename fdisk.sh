#!/bin/bash
##invoked by centos-expandLVM
echo "n
p
3


3
8e
w
" | fdisk /dev/sda
