#!/bin/bash


yum -y update
yum -y install epel-release
yum repolist
yum -y update
yum -y install mariadb-server


echo "customscript done" > /tmp/results.txt

exit 0