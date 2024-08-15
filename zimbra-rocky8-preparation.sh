#!/bin/bash
clear

echo -e "##########################################################################"
echo -e "#               Ahmad Imanudin - http://www.imanudin.net                 #"
echo -e "#If there any question about this script, feel free to contact me below  #"
echo -e "#                    Contact at ahmad@imanudin.com                       #"
echo -e "#                     Contact at iman@imanudin.net                       #"
echo -e "#                               www.imanudin.net                         #"
echo -e "##########################################################################"

echo ""
echo -e "Make sure you have internet connection to install packages..."
echo ""
echo -e "Press key enter"
read presskey

# Disable Selinux & Firewall

echo -e "[INFO] : Configuring Firewall & Selinux"
sleep 2
sed -i s/'SELINUX='/'#SELINUX='/g /etc/selinux/config
echo 'SELINUX=disabled' >> /etc/selinux/config
setenforce 0
service firewalld stop
service iptables stop
service ip6tables stop
systemctl disable firewalld
systemctl disable iptables
systemctl disable ip6tables

# Configuring network, /etc/hosts and resolv.conf

echo ""
echo -e "[INFO] : Configuring /etc/hosts"
echo ""
echo -n "Hostname. Example mail : "
read HOSTNAME
echo -n "Domain name. Example imanudin.net : "
read DOMAIN
echo -n "IP Address : "
read IPADDRESS
echo ""

# /etc/hosts

cp /etc/hosts /etc/hosts.backup

echo "127.0.0.1       localhost" > /etc/hosts
echo "$IPADDRESS   $HOSTNAME.$DOMAIN       $HOSTNAME" >> /etc/hosts

# Change Hostname
hostnamectl set-hostname $HOSTNAME.$DOMAIN


# Disable service sendmail or postfix (if any) 

systemctl disable --now sendmail
systemctl disable --now postfix

# Update repo and install dependencies

yum update -y
yum install epel-release -y
yum update -y
yum upgrade -y
yum -y install perl perl-core wget screen tar openssh-clients openssh-server dnsmasq bind-utils unzip nmap sed nc sysstat libaio rsync telnet aspell net-tools rsyslog


# Setup local DNS

echo "server=8.8.8.8
mx-host=$DOMAIN,$HOSTNAME.$DOMAIN,10
host-record=$DOMAIN,$IPADDRESS
host-record=$HOSTNAME.$DOMAIN,$IPADDRESS" > /etc/dnsmasq.d/$DOMAIN.conf

systemctl enable --now dnsmasq
systemctl restart dnsmasq

# Insert localhost as the first Nameserver
sed -i '1 s/^/nameserver 127.0.0.1\n/' /etc/resolv.conf

# Check results configuring DNS Server
echo "Check results"
echo ""
host -t MX $DOMAIN
host -t A $HOSTNAME.$DOMAIN
dig MX $DOMAIN

echo ""
echo "Configuring Firewall, network, /etc/hosts and DNS server has been configured. please install Zimbra now"


