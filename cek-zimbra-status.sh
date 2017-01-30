#!/bin/bash
# Script monitoring status zimbra

clear
SRV="mail.imanudin.com";

yes | rm /tmp/status-$SRV.txt
su - zimbra -c 'zmcontrol status' > /tmp/status-$SRV.txt

NOTRUNNING=`grep -woi "not running" /tmp/status-$SRV.txt | uniq`;
STOPPED=`grep -woi "stopped" /tmp/status-$SRV.txt | uniq`;

if [ "$NOTRUNNING" == "not running" -o "$STOPPED" == "Stopped" ] ; then

DARI="from:report@imanudin.com";
TUJUAN="to:admin.monitoring@imanudin.com";
SALINAN="cc:admin@imanudin.com";
SERVER="$SRV";
STATUS=`cat /tmp/status-$SRV.txt`;
SUBJECT="Subject: [PEMBERITAHUAN] : Status $SERVER not Running atau Stopped"
SENDMAIL=$(ionice -c3 find /opt/zimbra/ -type f -iname sendmail)
BODY="
Hi Team,

Ada beberapa/semua service Zimbra $SERVER Tidak berjalan. Silakan dicek dan diperbaiki

$SERVER
*****************
$STATUS

Terima Kasih
"

echo "$DARI" > /tmp/statusservicezimbra.txt
echo "$TUJUAN" >> /tmp/statusservicezimbra.txt
echo "$SALINAN" >> /tmp/statusservicezimbra.txt
echo "$SUBJECT" >> /tmp/statusservicezimbra.txt
echo "$BODY" >> /tmp/statusservicezimbra.txt
cat /tmp/statusservicezimbra.txt | $SENDMAIL -t
fi
echo "Status service Zimbra $SRV aman"
