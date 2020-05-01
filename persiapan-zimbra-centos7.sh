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

# Disable service sendmail or postfix

service sendmail stop
service postfix stop
systemctl disable sendmail
systemctl disable postfix

# Update repo and install package needed by Zimbra

yum update -y
yum upgrade -y
yum -y install perl perl-core wget screen w3m elinks openssh-clients openssh-server bind bind-utils unzip nmap sed nc sysstat libaio rsync telnet aspell net-tools

# Restart Network
service network restart

# Configuring DNS Server

echo ""
echo -e "[INFO] : Configuring DNS Server"
echo ""

NAMED=`ls /etc/ | grep named.conf.back`;

        if [ "$NAMED" == "named.conf.back" ]; then
	cp /etc/named.conf.back /etc/named.conf        
        else
	cp /etc/named.conf /etc/named.conf.back        
        fi

sed -i s/"listen-on port 53 { 127.0.0.1; };"/"listen-on port 53 { 127.0.0.1; any; };"/g /etc/named.conf
# sed -i s/"allow-query     { localhost; };"/"allow-query     { localhost; any; };"/g /etc/named.conf

echo 'zone "'$DOMAIN'" IN {' >> /etc/named.conf
echo "        type master;" >> /etc/named.conf
echo '        file "'db.$DOMAIN'";' >> /etc/named.conf
echo "        allow-update { none; };" >> /etc/named.conf
echo "};" >> /etc/named.conf

touch /var/named/db.$DOMAIN
chgrp named /var/named/db.$DOMAIN

echo '$TTL 1D' > /var/named/db.$DOMAIN
echo "@       IN SOA  ns1.$DOMAIN. root.$DOMAIN. (" >> /var/named/db.$DOMAIN
echo '                                        0       ; serial' >> /var/named/db.$DOMAIN
echo '                                        1D      ; refresh' >> /var/named/db.$DOMAIN
echo '                                        1H      ; retry' >> /var/named/db.$DOMAIN
echo '                                        1W      ; expire' >> /var/named/db.$DOMAIN
echo '                                        3H )    ; minimum' >> /var/named/db.$DOMAIN
echo "@		IN	NS	ns1.$DOMAIN." >> /var/named/db.$DOMAIN
echo "@		IN	MX	0 $HOSTNAME.$DOMAIN." >> /var/named/db.$DOMAIN
echo "ns1	IN	A	$IPADDRESS" >> /var/named/db.$DOMAIN
echo "$HOSTNAME	IN	A	$IPADDRESS" >> /var/named/db.$DOMAIN

# Insert localhost as the first Nameserver
sed -i '1 s/^/nameserver 127.0.0.1\n/' /etc/resolv.conf

# Restart Service & Check results configuring DNS Server

service named restart
systemctl enable named
nslookup $HOSTNAME.$DOMAIN
dig $DOMAIN mx

echo ""
echo "Configuring Firewall, network, /etc/hosts and DNS server has been finished. please install Zimbra now"
