#!/bin/bash
sudo apt-get -y update

# set up a silent install of MySQL
dbpass=$1

export DEBIAN_FRONTEND=noninteractive
echo mysql-server-5.6 mysql-server/root_password password $dbpass | sudo debconf-set-selections
echo mysql-server-5.6 mysql-server/root_password_again password $dbpass | sudo debconf-set-selections

# install Apache 2
sudo apt-get -y install apache2
# install MySQL Server
sudo apt-get -y install mysql-server
# install PHP
# We're deploying Unbuntu 17.04 with this script, which has updated to PHP 7.0 by default.
# If we must continue using PHP 5, we'll need to deploy Unbuntu 14.04 LTS
# libapache2-mod-php will install a virtual package that depends on the latest version of PHP, and will automatically pull common dependent modules
# This command also installs the php-mysql module - other modules can be added to enhance it's functionality. Find them with command:  "apt-cache search php- | less"
sudo apt-get -y install php libapache2-mod-php php-mysql 

# write some PHP
sudo echo '<center><h1>BKV Client Linux Deployment Test Page</h1></center\>' > /var/www/html/phpinfo.php
sudo echo '<?php phpinfo(); ?>' >> /var/www/html/phpinfo.php

# restart Apache
apachectl restart