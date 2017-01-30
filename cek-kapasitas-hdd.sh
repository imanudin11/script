#!/bin/bash
# Script monitoring kapasitas harddisk

clear
yes | rm /tmp/hdd.txt

# Cek kapasitas harddisk
CURRENT=$(df -h | grep / | awk '{ print $5}' | sed 's/%//g' | sort -g | tail -n1)
THRESHOLD=80

if [ "$CURRENT" -gt "$THRESHOLD" ] ; then

DARI="from:report@imanudin.com”;
TUJUAN="to:monitoring@imanudin.com";
SALINAN="cc:admin@imanudin.com";
SERVER=`hostname -f`;
KAPASITAS=`df -h`;
SUBJECT="Subject: [PEMBERITAHUAN] : Kapasitas HDD $SERVER sudah mencapai $CURRENT%"
BODY="
Hi Team,

Ada beberapa partisi mounting server $SERVER yang penggunaannya $CURRENT%. Silakan dicek

$SERVER
*****************
$KAPASITAS

Terima Kasih
"
SENDMAIL=$(ionice -c3 find /opt/zimbra/ -type f -iname sendmail)
echo "$DARI" >> /tmp/hdd.txt
echo "$TUJUAN" >> /tmp/hdd.txt
echo "$SALINAN" >> /tmp/hdd.txt
echo "$SUBJECT" >> /tmp/hdd.txt
echo "$BODY" >> /tmp/hdd.txt
cat /tmp/hdd.txt | /opt/zimbra/postfix/sbin/sendmail -t
fi
echo "Pemakaian kapasitas HDD belum mencapai $THRESHOLD%"
