#!/bin/bash

####################################################
# Automate ISPConfig Installation
# Nam Hoang
# https://github.com/z3rol0ve/ISPConfig-3-Installer
####################################################

#if user is not root then exit script
if [ $(id -u) != "0" ]; then
	echo "Error: You must be root to run this script, please use the root user to install the software.";
	exit 1;
fi;
#if ispconfig is installed exit script
if [ -f /usr/local/ispconfig/interface/lib/config.inc.php ]; then
	echo "Error: You must be root to run this script, please use the root user to install the software.";
	exit 1;
fi;

# Default Distribution
DISTRIBUTION="";
# Default Distribution version
DISTRIBUTION_VERSION="";
# Default Server Main IP
SERVER_IP="";
# Default Hostname short
HOSTNAME_SHORT="";
# Default Hostname full / FQDN
HOSTNAME_FULL="";

###### DETECTING OS & ITS VERSION
#if lsb_release command exist do
if [ $(command -v lsb_release) ]; then
    if [ $(lsb_release -is) == "Ubuntu" ]; then
        DISTRIBUTION=ubuntu;
        DISTRIBUTION_VERSION=$(lsb_release -sc);
    fi;
fi;
###### GETTING SERVER MAIN IP
#if all needed command exist do
if [ $(command -v ip) ] && [ $(command -v cut) ] && [ $(command -v head) ] && [ $(command -v tail) ]; then
    if [ ! -f /proc/user_beancounters ]; then
        SERVER_IP=$(ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1 | head -2 | tail -1);
    else
        SERVER_IP=$(ip -f inet -o addr show venet0|cut -d\  -f 7 | cut -d/ -f 1 | head -2 | tail -1);
    fi;
fi;

whiptail_title="ISPConfig Installer";
####### MAIN INSTALLATION
if [ $DISTRIBUTION == "ubuntu" ] && [ $DISTRIBUTION_VERSION = "xenial" ]; then
    #if apt-get command exist do
    if [ $(command -v apt-get) ]; then
    locale-gen en_US.UTF-8
        export LANG=en_US.UTF-8
        cp /etc/apt/sources.list /etc/apt/sources.list.backup
        cat > /etc/apt/sources.list <<EOF
deb http://archive.ubuntu.com/ubuntu $DISTRIBUTION_VERSION main restricted universe
deb http://archive.ubuntu.com/ubuntu $DISTRIBUTION_VERSION-updates main restricted universe
deb http://archive.ubuntu.com/ubuntu $DISTRIBUTION_VERSION-security main restricted universe
EOF
        apt-get update;
        apt-get -y upgrade;
        ########Question Procedure
        apt-get install -y whiptail;
        #if SERVER_IP is defined do confirmation
        if [ "$SERVER_IP" != "" ]; then
            if ! (whiptail --title "IP Address Check" --backtitle "$whiptail_title" --yesno "Is the Main IP of the Server? $SERVER_IP" 10 50) then
                SERVER_IP="";
            fi;
        fi;
        
        #if SERVER_IP is not defined do loop till user input
        while [ "$SERVER_IP" == "" ]; do
            SERVER_IP=$(whiptail --title "Server IP" --backtitle "$whiptail_title" --inputbox "Please specify a Server IP" --nocancel 10 50 3>&1 1>&2 2>&3);
        done;
    
        #if $HOSTNAME_SHORT is not defined do loop till user input
        while [ "$HOSTNAME_SHORT" == "" ]; do
            HOSTNAME_SHORT=$(whiptail --title "Short Hostname" --backtitle "$whiptail_title" --inputbox "Please specify a Short Hostname" --nocancel 10 50 3>&1 1>&2 2>&3);
        done;
    
        #if $HOSTNAME_FULL is not defined do loop till user input
        while [ "$HOSTNAME_FULL" == "" ]; do
            HOSTNAME_FULL=$(whiptail --title "Fully Qualified Hostname" --backtitle "$whiptail_title" --inputbox "Please specify a Fully Qualified Hostname" --nocancel 10 50 3>&1 1>&2 2>&3);
        done;
    
        #which SQL SERVER engine to install?
        while [ "$SQL_SERVER" == "" ]; do
            SQL_SERVER=$(whiptail --title "SQL Server" --backtitle "$whiptail_title" --nocancel --radiolist "Select SQL Server Software" 10 50 2 "MariaDB" "(default)" ON "MySQL" "" OFF 3>&1 1>&2 2>&3);
        done;
        
        #Pick SQL Version
        if [ "$SQL_SERVER" == "MariaDB" ]; then
            while [ "$SQL_VERSION" == "" ]; do
                SQL_VERSION=$(whiptail --title "$SQL_SERVER Version" --backtitle "$whiptail_title" --nocancel --radiolist "Select $SQL_SERVER Version" 10 50 2 "10.0" "(default)" ON "10.1" "" OFF 3>&1 1>&2 2>&3);
            done;
        fi;
        
        #Set SQL ROOT PASSWORD
        while [ "$SQL_PASS" == "" ]
        do
            SQL_PASS=$(whiptail --title "$SQL_SERVER Root Password" --backtitle "$whiptail_title" --inputbox "Please specify a $SQL_SERVER Root Password" --nocancel 10 50 3>&1 1>&2 2>&3)
        done
    
        #install web server?
        if (whiptail --title "Install Web Server" --backtitle "$whiptail_title" --yesno "Install Web Server?" 10 50) then
            install_web_server=true;
            while [ "$WEB_SERVER" == "" ]; do
                WEB_SERVER=$(whiptail --title "Web Server" --backtitle "$whiptail_title" --nocancel --radiolist "Select Web Server Software" 10 50 1 "Nginx" "(default)" ON 3>&1 1>&2 2>&3);
            done;
        else
            install_web_server=false;
        fi;
        
        #install ftp server?
        if (whiptail --title "Install FTP Server" --backtitle "$whiptail_title" --yesno "Install FTP Server?" 10 50) then
            install_ftp_server=true;
            install_quota=true;
        else
            install_ftp_server=false;
            install_quota=false;
        fi
        
        #install DNS server?
        if (whiptail --title "Install DNS Server" --backtitle "$whiptail_title" --yesno "Install DNS Server?" 10 50) then
            install_dns_server=true;
        else
            install_dns_server=false;
        fi
        
        #install Jailkit?
        if (whiptail --title "Install Jailkit" --backtitle "$whiptail_title" --yesno "Setup User Jailkits?" 10 50) then
            install_jailkit=true;
        else
            install_jailkit=false;
        fi
        
        ###### CONFIRMATION BEFORE PROCEED TO INSTALLATION
        if (whiptail --title "Installation Confirmation" --backtitle "$whiptail_title" --yesno "Server IP: $SERVER_IP \nShort Hostname: $HOSTNAME_SHORT \nFQDN: $HOSTNAME_FULL \nSQL Server: $SQL_SERVER $SQL_VERSION \nSQL Root password: $SQL_PASS \nWeb Server: $install_web_server | $WEB_SERVER \nFTP Server: $install_ftp_server \nDNS Server: $install_dns_server \nJailkit: $install_jailkit" 20 50) then
            echo "################# SET HOSTNAME ##################\n"
            apt-get install -y hostname sed;
            sed -i "s/${SERVER_IP}.*/${SERVER_IP} ${HOSTNAME_FULL} ${HOSTNAME_SHORT}/" /etc/hosts
            echo "$HOSTNAME_FULL" > /etc/hostname
            /etc/init.d/hostname.sh start >/dev/null 2>&1
            apt-get install -y dialog nano cron unzip binutils sudo bzip2 zip e2fsprogs libss2 ntp ntpdate software-properties-common
            echo "dash dash/sh boolean false" | debconf-set-selections
            dpkg-reconfigure -f noninteractive dash > /dev/null 2>&1
            
            echo "################# INSTALL SQL ##################\n"
            if [ "$SQL_SERVER" == "MariaDB" ]; then
            	if [ "$SQL_VERSION" != "" ]; then
            		apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
            		add-apt-repository "deb [arch=amd64,i386] http://nyc2.mirrors.digitalocean.com/mariadb/repo/$SQL_VERSION/ubuntu xenial main"
            		apt-get update
            		echo "mysql-server mysql-server/root_password password $SQL_PASS" | debconf-set-selections
            		echo "mysql-server mysql-server/root_password_again password $SQL_PASS" | debconf-set-selections
            		apt-get install -y mariadb-server mariadb-client
            		cp /etc/mysql/my.cnf /etc/mysql/my.cnf.backup
            		sed -i 's/bind-address/#bind-address/' /etc/mysql/my.cnf
            		if [ "$SQL_VERSION" == "10.1" ]; then
            			sed -i 's/\[mysqld\]/\[mysqld\]\nsql-mode="NO_ENGINE_SUBSTITUTION"/' /etc/mysql/my.cnf
            		fi;
            		service mysql restart
            	fi;
        	elif [ "$SQL_SERVER" == "MySQL" ]; then
    	        echo "mysql-server mysql-server/root_password password $SQL_PASS" | debconf-set-selections
        	    echo "mysql-server mysql-server/root_password_again password $SQL_PASS" | debconf-set-selections
        	    apt-get install -y mysql-server mysql-client
    	        cp /etc/mysql/my.cnf /etc/mysql/my.cnf.backup
    	        sed -i 's/bind-address/#bind-address/' /etc/mysql/my.cnf
    	        service mysql restart
            fi;
            
            #install php
            apt-get -y install php
            
            if [ $install_web_server == true ]; then
                echo "################# INSTALL WEB SERVER ##################\n"
                if [ "$WEB_SERVER" == "Nginx" ]; then
                    add-apt-repository -y ppa:nginx/stable
                    apt-get update
                    apt-get -y install nginx
                    cat > /etc/nginx/conf.d/open_file_cache.conf <<EOF
open_file_cache          max=10000 inactive=5m;
open_file_cache_valid    2m;
open_file_cache_min_uses 1;
open_file_cache_errors   on;
EOF
			LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
                    apt-get -y install php php7.0-fpm php7.0-curl php7.0-gd php7.0-intl php-pear php7.0-imap php-memcached php-memcache memcached php7.0-pspell php7.0-recode php7.0-sqlite3 php7.0-tidy php7.0-xmlrpc php7.0-xml php7.0-xsl php7.0-mbstring php7.0-mcrypt mcrypt php7.0-mysql phpmyadmin fcgiwrap php-gettext letsencrypt
                    #reconfig php-fpm php.ini without touching it
                    cat > /etc/php/7.0/fpm/conf.d/custom.ini <<EOF
opcache.enable=1
opcache.enable_cli=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=4000
opcache.fast_shutdown=1
cgi.fix_pathinfo=0
date.timezone ="Asia/Ho_Chi_Minh"
display_errors=on
EOF
                    service php7.0-fpm restart
                    
                elif [ "$WEB_SERVER" == "Apache" ]; then
                    echo "NOT YET SUPPORT"
                    #apt-get -y install apache2
                fi;
                #Install Stats
                apt-get -y install vlogger webalizer awstats geoip-database libclass-dbi-mysql-perl
                sed -i "s/*/10 * * * * www-data/#*/10 * * * * www-data/" /etc/cron.d/awstats
                sed -i "s/10 03 * * * www-data/#10 03 * * * www-data/" /etc/cron.d/awstats
            fi;
            
            if [ $install_ftp_server == true ]; then
                echo "################# INSTALL FTP SERVER ##################\n"
                apt-get -y install pure-ftpd-common pure-ftpd-mysql
                #Setting up Pure-Ftpd
                
                sed -i 's/VIRTUALCHROOT=false/VIRTUALCHROOT=true/' /etc/default/pure-ftpd-common
                echo 1 > /etc/pure-ftpd/conf/TLS
                mkdir -p /etc/ssl/private/
                
                openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -subj "/C=/ST=/L=/O=/CN=$(hostname -f)" -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
                chmod 600 /etc/ssl/private/pure-ftpd.pem
                service pure-ftpd-mysql restart
            fi;
            
            if [ $install_quota == true ]; then
                echo "################# INSTALL QUOTA ##################\n"
                #Editing FStab
                cp /etc/fstab /etc/fstab.backup
                sed -i "s/errors=remount-ro/errors=remount-ro,usrjquota=quota.user,grpjquota=quota.group,jqfmt=vfsv0/" /etc/fstab
                
                #Setting up Quota
                
                apt-get -y install quota quotatool
                mount -o remount /
                quotacheck -avugm
                quotaon -avug
            fi;
            
            if [ $install_dns_server == true ]; then
                echo "################# INSTALL DNS SERVER ##################\n"
                apt-get -y install bind9 dnsutils
            fi;
            
            if [ $install_jailkit == true ]; then
                echo "################# INSTALL JAILKIT ##################\n"
                apt-get -y install python build-essential autoconf automake libtool flex bison debhelper
                cd /tmp
                wget http://olivier.sessink.nl/jailkit/jailkit-2.19.tar.gz
                tar xvfz jailkit-2.19.tar.gz
                cd jailkit-2.19
                ./debian/rules binary
                cd ..
                dpkg -i jailkit_2.19-1_*.deb
                rm -rf jailkit-2.19*
            fi;
            
            #Install Fail2ban
            apt-get install -y fail2ban
            
            #Install Ubuntu firewall
            apt-get install -y ufw
            
            #Install ISPConfig 3
            echo "################# INSTALL ISPConfig ##################\n"
            cd /tmp
            wget http://www.ispconfig.org/downloads/ISPConfig-3.1.1.tar.gz
            tar xvfz ISPConfig-3.1.1.tar.gz
            cd ispconfig3_install/install
            php -q install.php
            
        else
            echo "Script exiting...";
            exit 1;
        fi
    fi;
else
	echo "Error: Your OS is not supported.";
	exit 1;
fi;
