#!/bin/bash

IP_ADDRESS=$(hostname -I | awk '{print $1}')
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

dpkg-reconfigure tzdata
apt update && apt dist-upgrade -y

# Install Sudo
apt install sudo -y

# Install Apache, MariaDB en PHP
sudo apt install -y apache2 mariadb-server php php-mysql php-curl php-gd php-pear php-intl php-mbstring php-zip

# Start en activeer Apache en MariaDB
sudo systemctl start apache2
sudo systemctl enable apache2
sudo systemctl start mariadb
sudo systemctl enable mariadb

echo Secure MariaDB installation
echo -e "\e[33mRemember this password that you create later \e[0m"
sudo mysql_secure_installation

# Install Git
sudo apt install git -y

# Install Spotweb
sudo apt install phpmyadmin -y
cd /var/www/html
git clone https://github.com/spotweb/spotweb.git
mkdir /var/www/html/spotweb/cache
chown -R www-data:www-data /var/www/html/spotweb/cache

# Create Spotweb database and user
sudo mysql -e "CREATE DATABASE spotweb;"
sudo mysql -e "GRANT ALL PRIVILEGES ON spotweb.* TO 'spotweb'@'localhost' IDENTIFIED BY 'DB_spotweb';"
sudo mysql -e "FLUSH PRIVILEGES;"

cat <<EOF > "$SCRIPT_DIR/dbsettings.inc.php"
<?php

\$dbsettings['engine'] = 'pdo_mysql';
\$dbsettings['host'] = 'localhost';
\$dbsettings['dbname'] = 'spotweb';
\$dbsettings['user'] = 'DB_spotweb';
\$dbsettings['pass'] = 'spotweb';
\$dbsettings['port'] = '3306';
\$dbsettings['schema'] = '';
EOF

cat <<EOF > "$SCRIPT_DIR/move.sh"
<?php
sudo mv dbsettings.inc.php /var/www/html/spotweb
echo Moved dbsettings.inc.php to /var/www/html/spotweb
rm move.sh
EOF

cat <<EOF > "$SCRIPT_DIR/auto_update.sh"
<?php
# Add cron-job
(crontab -l ; echo "*/30 * * * * cd /var/www/spotweb && php retrieve.php") | crontab -
echo A cron-job is created. Spotweb database refresh every 30 min.
EOF

chmod +x "$SCRIPT_DIR/move.sh"
chmod +x "$SCRIPT_DIR/auto_update.sh"
clear
echo
echo
echo Use a webbrowser to go to
echo -e "\e[32mhttp://$IP_ADDRESS/spotweb/install.php \e[0m"
echo And configure the rest of the settings in spotweb.
echo
echo -e "\e[36m Don't forget to add the password and \e[0m"
echo -e "\e[36m Change at the Database settings page \e[0m"
echo -e "\e[36m Database username from spotweb to DB_spotweb \e[0m"
echo
echo Later when asked, move dbsettings.inc.php to /var/www/html/spotweb
echo -e "\e[32msudo mv /tmp/dbsettings.inc.php /var/www/html/spotweb \e[0m"
echo or type:
echo -e "\e[32m ./move.sh \e[0m"
echo
echo To setup crontab for every 30 min. type:
echo -e "\e[32m ./auto_update \e[0m"
echo
echo phpMyAdmin 
echo -e "\e[32mhttp://$IP_ADDRESS/phpmyadmin \e[0m"
echo Login as root with the SQL password that you created earlier
echo
