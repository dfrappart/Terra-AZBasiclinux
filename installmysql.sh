#!/bin/bash

yum -y update
sudo yum -y install mariadb-server
sudo systemctl enable mariadb
sudo systemctl start mariadb

echo "customscript done" > /tmp/results.txt

exit 0