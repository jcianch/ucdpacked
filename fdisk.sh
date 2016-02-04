#!/bin/bash
##invoked by centos-expandLVM
sfdisk  --no-reread --force /dev/sda < /vagrant/sda.layout