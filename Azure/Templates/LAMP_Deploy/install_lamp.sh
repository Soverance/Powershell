#!/bin/bash
sudo apt-get -y update

# set up a silent install of MySQL
dbpass=$1

export DEBIAN_FRONTEND=noninteractive
echo mysql-server-5.6 mysql-server/root_password password $dbpass | sudo debconf-set-selections
echo mysql-server-5.6 mysql-server/root_password_again password $dbpass | sudo debconf-set-selections

# install the LAMP stack
sudo apt-get -y install apache2 
sudo apt-get -y install mysql-server 
sudo apt-get -y install php5 
sudo apt-get -y install php5-mysql  

# write some PHP
echo '<center><h1>BKV Client Linux Deployment Test Page</h1></center\>' > /var/www/html/phpinfo.php
echo '<?php phpinfo(); ?>' >> /var/www/html/phpinfo.php

# restart Apache
apachectl restart