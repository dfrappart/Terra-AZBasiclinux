#!/bin/bash

#yum -y update
yum -y install httpd
apachectl start

echo "customscript done" > /tmp/results.txt

exit 0