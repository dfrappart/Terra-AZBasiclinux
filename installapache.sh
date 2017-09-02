#!/bin/bash

yum -y update
yum -y install httpd
apachectl start