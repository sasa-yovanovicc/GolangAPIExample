#!/bin/bash

# Functions
ok() { echo -e '\e[32m'$1'\e[m'; } # Green
red(){ echo -e '\e[31m'$1'\e[m'; } # Red

EXPECTED_ARGS=3
E_BADARGS=65
MYSQL=`which mysql`
 

 
#if [ $# -ne $EXPECTED_ARGS ]
#then
#  echo "Usage: $0 dbname dbuser dbpass"
#  exit $E_BADARGS
#fi

read -p "Database name:" dbname
echo " "
read -p "Database username:" dbuser
echo " "
read -p "Database password:" dbpass
echo " "


Q1="CREATE DATABASE IF NOT EXISTS $dbname;"
Q2="GRANT ALL ON *.* TO '$dbuser'@'localhost' IDENTIFIED BY '$dbpass';"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"


echo "Creating database."
echo "Enter MySQL root password:" 



$MYSQL -uroot -p -e "$SQL"

ok "Database $dbname and user $dbuser created with a password $dbpass"

echo "Restoring database tables." 
red "Enter MySQL root password:" 

$MYSQL -uroot -p $dbname < ./spec/test.sql

ok "Database tables retored from SQL dump"

cp .env.template .env
cp .env ./post_code_gen
cp .env ./restapi

sed -i "s/DBNAME/$dbname/g" .env
sed -i "s/DBUSER/$dbuser/g" .env
sed -i "s/DBPASS/$dbpass/g" .env

ok "Database credentials stored in base.env (use this file just in development)"