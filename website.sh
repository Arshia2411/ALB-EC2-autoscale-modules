#!/bin/bash
sudo su
yum update -y
yum install httpd -y
cd /var/www/html
echo "Hellozzz" > /var/www/html/index.html
service httpd restart