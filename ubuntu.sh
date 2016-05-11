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
    	##### UPDATE SOURCES LIST
        locale-gen en_US.UTF-8
        export LANG=en_US.UTF-8
        cp /etc/apt/sources.list /etc/apt/sources.list.backup
        cat > /etc/apt/sources.list <<EOF
deb http://archive.ubuntu.com/ubuntu $DISTRIBUTION_VERSION main restricted
deb http://archive.ubuntu.com/ubuntu $DISTRIBUTION_VERSION-updates main restricted
deb http://archive.ubuntu.com/ubuntu $DISTRIBUTION_VERSION-security main restricted
EOF
        apt-get update;
        
        ########Question Procedure
        apt-get install whiptail;
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
            while [ "$MARIADB_VERSION" == "" ]; do
                MARIADB_VERSION=$(whiptail --title "$SQL_SERVER Version" --backtitle "$whiptail_title" --nocancel --radiolist "Select $SQL_SERVER Version" 10 50 3 "5.5" "" OFF "10.0" "(default)" ON "10.1" "" OFF 3>&1 1>&2 2>&3);
            done;
        elif [ "$SQL_SERVER" == "MySQL" ]; then
            while [ "$MYSQL_VERSION" == "" ]; do
                MYSQL_VERSION=$(whiptail --title "$SQL_SERVER Version" --backtitle "$whiptail_title" --nocancel --radiolist "Select $SQL_SERVER Version" 10 50 3 "5.5" "" OFF "5.6" "(default)" ON "5.7" "" OFF 3>&1 1>&2 2>&3);
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
                WEB_SERVER=$(whiptail --title "Web Server" --backtitle "$whiptail_title" --nocancel --radiolist "Select Web Server Software" 10 50 2 "Nginx" "(default)" ON 3>&1 1>&2 2>&3);
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
        if (whiptail --title "Installation Confirmation" --backtitle "$whiptail_title" --yesno "Server IP: $SERVER_IP \nShort Hostname: $HOSTNAME_SHORT" 50 50) then
            install_jailkit=true;
        else
            echo "Script exiting...";
        	exit 1;
        fi
    fi;
else
	echo "Error: Your OS is not supported.";
	exit 1;
fi;
