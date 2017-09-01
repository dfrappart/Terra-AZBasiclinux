#!/bin/bash

yum -y update
yum -y install httpd
start service httpd