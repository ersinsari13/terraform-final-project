#!/bin/bash
dnf update -y
dnf install pip -y
pip3 install flask
pip3 install flask_mysql
dnf install git -y
TOKEN=${git-tokens}
dbendpoint=${db-endpoint}
cd /home/ec2-user && git clone https://$TOKEN@github.com/ersinsari13/phonebook.git
cd /home/ec2-user/phonebook 
echo "$dbendpoint" > dbserver.endpoint
python3 /home/ec2-user/phonebook/phonebook-app.py