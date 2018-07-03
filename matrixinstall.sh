#!/bin/bash
echo
echo "Welcome to the Synapse Installer"
echo 

# Prompts for user input

echo "I Need to ask you a few questions before starting the setup"
echo "Please enter the domain name you would like to use"
read -p "Domain Name: " domain_name
echo
echo "We'll create a Postgresql database called synapse, and assign it to a user called synapse_user."
while true; do
	echo "Please enter a password for synapse_user"
	read -sp "Password: " synapse_user_passwd
	echo 
	read -sp "Confirm Password: " synapse_user_passwd2
	echo 
	[ "$synapse_user_passwd" = "$synapse_user_passwd2" ] && break
	echo
	echo "Passwords do not match, please try again"
done
echo
echo "Please enter a username for your chat application. The username will be @username:$domain_name"
read -p "Username: " matrix_user
while true; do
	echo "Please enter a password for $matrix_user"
	read -sp "Password: " matrix_password
	echo
	read -sp "Confirm Password: " matrix_password2
        [ "$matrix_password" = "$matrix_password2" ] && break
	echo
	echo "Passwords do not match, please try again"
done
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
#exit the virtual environment
deactivate
#open firewall ports
echo "Opening firewall ports"
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --permanent --zone=public --add-service=https
sudo firewall-cmd --zone=public --add-port=8008/tcp --permanent
sudo firewall-cmd --reload
echo
echo "Installing postgresql"
echo
sudo yum install postgresql-server postgresql-contrib
echo
echo "Creating a database cluster"
echo
sudo postgresql-setup initdb
echo
# Code for editing /var/lib/pgsql/data/pg_hba.conf
echo
echo "Starting and enabling postgresql"
echo
sudo systemctl start postgresql
sudo systemctl enable postgresql
echo
echo "Creating synapse_user and synapse database"
echo
sudo -i -u postgres <<EOF
psql -c "CREATE USER synapse_user WITH PASSWORD '$synapse_user_passwd';
psql -c "CREATE DATABASE synapse ENCODING 'UTF8' LC_COLLATE='C' LC_CTYPE='C' template=template0 OWNER synapse_user;
EOF
exit
echo
echo "Installing postgres-devel and psycopg2"
echo
sudo yum install https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-7-x86_64/pgdg-centos10-10-2.noarch.rpm -y
source ~/.synapse/bin/activate
sudo yum install postgresql-devel libpqxx-devel.x86_64 -y
export PATH=/usr/pgsql-10.2/bin/:$PATH
pip install psycopg2
echo
#code for editing homeserver.yaml goes here
echo
deactivate
echo
# code for editing pg_hba.conf goes here
echo
echo "Restarting postgresql"
echo
sudo systemctl stop postgresql
sudo systemctl start postgresql
echo
echo "Starting Synapse"
echo
source ~/.synapse/bin/activate
synctl start
echo
echo "Creating matrix user"
echo
register_new_matrix_user -c homeserver.yaml https://localhost:8008

