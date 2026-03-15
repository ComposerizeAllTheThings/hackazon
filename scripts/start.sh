#!/bin/bash

#mysql has to be started this way as it doesn't work to call from /etc/init.d
#and files need to be touched to overcome overlay file system issues on Mac and Windows
find /var/lib/mysql -type f -exec touch {} \; && /usr/bin/mysqld_safe & 
sleep 10s
# Here we generate random passwords
RANDOM_PASS=`date +%s|sha256sum|base64|head -c 10`
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-$RANDOM_PASS}"
MYSQL_HOST="localhost"
HACKAZON_DB="hackazon" # Must stay hackazon, or modify in .php file
MYSQL_USER="hackazon" # Must stay hackazon, or modify in .php file

HACKAZON_PASSWORD="${HACKAZON_PASSWORD:-$RANDOM_PASS}" # Setup panel password

# Admin panel password
ADMIN_PASSWORD="${ADMIN_PASSWORD:-$HACKAZON_PASSWORD}"
# HASHED_PASSWORD=`php /passwordHash.php $HACKAZON_PASSWORD`
HASHED_PASSWORD=`echo '<?php $salt=uniqid(rand()); echo hash("md5", $argv[1].$salt).":".$salt; ?>' | php -- ${ADMIN_PASSWORD}`


#This is so the passwords show up in logs. 
echo hackazon password: $HACKAZON_PASSWORD
echo $MYSQL_ROOT_PASSWORD > /mysql-root-pw.txt
echo $HACKAZON_PASSWORD > /hackazon-db-pw.txt

#set DB password in db.php
sed -i "s/yourdbpass/$HACKAZON_PASSWORD/" /var/www/hackazon/assets/config/db.php
sed -i "s/'localhost'/'$MYSQL_HOST'/" /var/www/hackazon/assets/config/db.php
sed -i "s/youradminpass/$HACKAZON_PASSWORD/" /var/www/hackazon/assets/config/parameters.php

# Reset MySQL root password
mysqladmin -u root password $MYSQL_ROOT_PASSWORD

# Automate the Hackazon database installation
mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE $HACKAZON_DB; GRANT ALL PRIVILEGES ON $HACKAZON_DB.* TO '$MYSQL_USER'@'localhost' IDENTIFIED BY '$HACKAZON_PASSWORD'; FLUSH PRIVILEGES;"
mysql -uroot -p$MYSQL_ROOT_PASSWORD $HACKAZON_DB < "/var/www/hackazon/database/createdb.sql"
# Admin panel password
mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "UPDATE $HACKAZON_DB.tbl_users SET password='${HASHED_PASSWORD}' WHERE username='admin';"

killall mysqld
sleep 10s

supervisord -n
