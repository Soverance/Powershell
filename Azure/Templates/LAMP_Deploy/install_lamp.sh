#!/bin/bash
sudo apt-get -y update

# set up a silent install of MySQL
dbpass=$1

export DEBIAN_FRONTEND=noninteractive
echo mysql-server-5.6 mysql-server/root_password password $dbpass | sudo debconf-set-selections
echo mysql-server-5.6 mysql-server/root_password_again password $dbpass | sudo debconf-set-selections

# install the LAMP stack
sudo apt-get -y install apache2 mysql-server php5 php5-mysql  

# write some PHP
sudo echo \<center\>\<h1\>BKV Linux Demo App\</h1\>\<br/\>\</center\> > /var/www/html/phpinfo.php
sudo echo \<\?php phpinfo\(\)\; \?\> >> /var/www/html/phpinfo.php

# restart Apache
apachectl restart