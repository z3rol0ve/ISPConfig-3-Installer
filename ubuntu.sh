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
        ########Question Procedure
        apt-get update;
        apt-get install whiptail;
        #if SERVER_IP is defined do confirmation
        if [ $SERVER_IP != "" ]; then
            if ! (whiptail --title "IP Address Check" --backtitle "$whiptail_title" --yesno "Is the Main IP of the Server? $SERVER_IP" 10 50) then
                SERVER_IP="";
            fi;
        fi;
        
    fi;
else
	echo "Error: Your OS is not supported.";
	exit 1;
fi;
