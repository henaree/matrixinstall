#!/bin/bash

# TODO: Add link to github read me for config edit instructions

echo
echo "Welcome to the Synapse Installer"
echo 

# Prompts for user input

echo "I Need to ask you a few questions before starting the setup"
echo
echo "Please enter the domain name you would like to use"
read -p "Domain Name: " domain_name
echo
while true; do
	echo
	read -p "Should synapse keep logs?" yn
	case $yn in
		[Yy]* ) answer=yes; break;;
		[Nn]* ) answer=no; break;;
		* ) echo "Please answer yes or no.";;
	esac
done
echo

# Program Installation

echo
echo "Installing pre-requisites"
echo
sudo yum install libtiff-devel libjpeg-devel libzip-devel freetype-devel \
lcms2-devel libwebp-devel tcl-devel tk-devel redhat-rpm-config \
python-virtualenv libffi-devel openssl-devel -y
sudo yum groupinstall "Development Tools" -y
echo
echo "Installing Synapse"
echo
virtualenv -p python2.7 ~/.synapse
source ~/.synapse/bin/activate
pip install --upgrade pip
pip install --upgrade setuptools
pip install https://github.com/matrix-org/synapse/tarball/master
echo
echo "Generating config homeserver.yaml"
echo
cd ~/.synapse
python -m synapse.app.homeserver \
    --server-name $domain_name \
    --config-path homeserver.yaml \
    --generate-config \
    --report-stats=$answer
echo
# pretty sure you don't need to deactivate here
# deactivate
echo
echo "Installing postgresql"
echo
sudo yum install postgresql-server postgresql-contrib
echo
# Code for editing /var/lib/pgsql/data/pg_hba.conf
echo
echo "Starting and enabling postgresql"
echo
sudo systemctl start postgresql
sudo systemctl enable postgresql
echo
echo "Installing postgres-devel and psycopg2"
echo
sudo yum install https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-7-x86_64/pgdg-centos10-10-2.noarch.rpm -y
source ~/.synapse/bin/activate
sudo yum install postgresql-devel libpqxx-devel.x86_64 -y
export PATH=/usr/pgsql-10.2/bin/:$PATH
pip install psycopg2
echo
deactivate
echo
echo Installing nginx
echo
sudo yum install epel-release -y
sudo yum install nginx -y
echo
echo Starting and enabling nginx
sudo systemctl start nginx
sudo systemctl enable nginx
echo
echo Installing Cerbot
sudo yum install certbot-nginx -y
echo 
echo Opening firewall ports 443, 80 and 8080
echo
sudo firewall-cmd --add-service=http
sudo firewall-cmd --add-service=https
sudo firewall-cmd --runtime-to-permanent
sudo firewall-cmd --zone=public --add-port=8008/tcp --permanent
sudo firewall-cmd --reload
echo
echo Installation Complete!

