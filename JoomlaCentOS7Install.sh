#!/bin/bash
#Disabling SElinux

yum install wget bind-utils -y
yum install lsof -y

sudo setenforce 0
cp -arp /etc/selinux/config  /etc/selinux/config.bak
sed -i '07 s/^/#/' /etc/selinux/config
echo "SELINUX=disabled" >> /etc/selinux/config
sestatus

#Install MySQL 5.7 service

cd /home/centos/
wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
sudo rpm -ivh mysql-community-release-el7-5.noarch.rpm
rm -f mysql-community-release-el7-5.noarch.rpm
yum install mysql-server -y


#Install PHP and HTTPD service

yum install epel-release -y
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
yum install php72w  php72w-pdo php72w-bcmath php72w-mbstring php72w-mysqlnd php72w-curl php72w-intl php72w-cli  php72w-fpm php72w-opcache php72w-bcmath php72w-gd php72w-dom php72w-soap php72w-xsl httpd24-devel httpd-tools httpd -y
cp -arp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.bak
sed -i '151s/None/All/g'  /etc/httpd/conf/httpd.conf

#Make HTTPD and MySQL service to start on boot.

chkconfig httpd on
chkconfig mysqld on

#Start HTTPD and MySQL service

service httpd start
service mysqld start

#Set up MySQL root password.

newpass=`openssl rand -hex 8`
root=root
mysqladmin -u $root password $newpass
echo $newpass

#Setup new database and logins for Magento site.

DBNAME=db
NEWDBNAME=joomla$DBNAME


echo [client] > /root/.my.cnf
echo user=root >> /root/.my.cnf
echo password="\"$newpass"\" >> /root/.my.cnf

#Installing Composer command
cd /tmp
sudo curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer


#Install zip and unzip commands

yum install zip unzip git -y


#setting up swap space
dd if=/dev/zero of=/swapfile bs=1M count=4096
mkswap /swapfile
swapon /swapfile
cp -arp /etc/fstab /etc/fstab.bak
echo "/swapfile      swap    swap     defaults     0     0" >> /etc/fstab
swapon -a
echo "======================================================================================================================="
echo " swap creation completed "
echo "======================================================================================================================="
cd /var/www/
composer global require joomlatools/console

/root/.config/composer/vendor/bin/joomla site:create  easydeploy --release=latest --sample-data=blog --www="/var/www/"  --mysql-login="$root:$newpass" --mysql-host="localhost" --mysql-database="$NEWDBNAME"  --no-interaction
rm -rf /var/www/html
mv /var/www/easydeploy   /var/www/html
chown centos:apache /var/www/html -R
chmod 2775 /var/www/html -R
service httpd restart

touch /home/centos/Administrator.login
echo "username=admin" > /home/centos/Administrator.login
echo "password=admin " >> /home/centos/Administrator.login

echo "======================================================================================================================="
echo "       Joomla Installation Completed  "
echo "======================================================================================================================="
