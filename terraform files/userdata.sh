#!/bin/bash
yum update -y
yum install -y python3 python3-pip
pip3 install flask
pip3 install flask_mysql
yum install git -y
mkdir /home/ec2-user/phonebook
echo "${db_endpoint}" > /home/ec2-user/phonebook/dbserver.endpoint
cd /home/ec2-user
git clone https://github.com/ersinsari13/terraform-final-project.git
cd terraform-final-project
#FOLDER ="https://raw.githubusercontent.com/ersinsari13/terraform-final-project/main/"
#curl -s --create-dirs -o "/home/ec2-user/templates/index.html" -L "$FOLDER"templates/index.html
#curl -s --create-dirs -o "/home/ec2-user/templates/add-update.html" -L "$FOLDER"templates/add-update.html
#curl -s --create-dirs -o "/home/ec2-user/templates/delete.html" -L "$FOLDER"templates/delete.html
#curl -s --create-dirs -o "/home/ec2-user/app.py" -L "$FOLDER"phonebook-app.py
python3 phonebook-app.py 