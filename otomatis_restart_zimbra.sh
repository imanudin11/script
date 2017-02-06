#!/bin/bash
# Script monitoring status ZCS
clear

LISTZIMBRA="mail.imanudin.com";

for ZCS in $LISTZIMBRA; do

# Hapus file sebelum diisi
yes | rm /tmp/status-$ZCS-asli.txt
yes | rm /tmp/status-$ZCS.txt

# Cek status service dan masukkan pada file
su - zimbra -c 'zmcontrol status' > /tmp/status-$ZCS-asli.txt
/opt/zimbra/check_zimbra.pl > /tmp/status-$ZCS.txt


# Parameter cek status LDAP
ldap=`grep -wi "ldap:STOPPED" /tmp/status-$ZCS.txt | cut -d ":" -f2`;

# Cek service LDAP
if [[ "$ldap" == STOPPED* ]]; then
echo "Restart service Zimbra"
su - zimbra -c 'zmcontrol restart'

# Generate ulang status Zimbra
/opt/zimbra/check_zimbra.pl > /tmp/status-$ZCS.txt

else
echo "Status service ldap OK"
fi

amavis=`grep -wi "amavis:STOPPED" /tmp/status-$ZCS.txt | cut -d ":" -f2`;
antispam=`grep -wi "antispam:STOPPED" /tmp/status-$ZCS.txt | cut -d ":" -f2`;
antivirus=`grep -wi "antivirus:STOPPED" /tmp/status-$ZCS.txt | cut -d ":" -f2`;
cbpolicyd=`grep -wi "cbpolicyd:STOPPED" /tmp/status-$ZCS.txt | cut -d ":" -f2`;
logger=`grep -wi "logger:STOPPED" /tmp/status-$ZCS.txt | cut -d ":" -f2`;
mailbox=`grep -wi "mailbox:STOPPED" /tmp/status-$ZCS.txt | cut -d ":" -f2`;
memcached=`grep -wi "memcached:STOPPED" /tmp/status-$ZCS.txt | cut -d ":" -f2`;
mta=`grep -wi "mta:STOPPED" /tmp/status-$ZCS.txt | cut -d ":" -f2`;
opendkim=`grep -wi "opendkim:STOPPED" /tmp/status-$ZCS.txt | cut -d ":" -f2`;
proxy=`grep -wi "proxy:STOPPED" /tmp/status-$ZCS.txt | cut -d ":" -f2`;
snmp=`grep -wi "snmp:STOPPED" /tmp/status-$ZCS.txt | cut -d ":" -f2`;
zmconfigd=`grep -wi "zmconfigd:STOPPED" /tmp/status-$ZCS.txt | cut -d ":" -f2`;
stats=`grep -wi "stats:STOPPED" /tmp/status-$ZCS.txt | cut -d ":" -f2`;
spell=`grep -wi "spell:STOPPED" /tmp/status-$ZCS.txt | cut -d ":" -f2`;

# Cek service zmconfigd
if [[ "$zmconfigd" == STOPPED* ]]; then
echo "restart service zmconfigd"
su - zimbra -c 'zmconfigdctl restart'
else
echo "Status service zmconfigd OK"
fi

# Cek service logger
if [[ "$logger" == STOPPED* ]]; then
echo "restart service"
su - zimbra -c 'zmloggerctl restart'
else
echo "Status service logger OK"
fi

# Cek service memcached
if [[ "$memcached" == STOPPED* ]]; then
echo "restart service memcached"
su - zimbra -c 'zmmemcachedctl restart'
else
echo "Status service memcached OK"
fi

# Cek service proxy
if [[ "$proxy" == STOPPED* ]]; then
echo "restart service proxy"
su - zimbra -c 'zmproxyctl restart'
else
echo "Status service proxy OK"
fi

# Cek service amavis
if [[ "$amavis" == STOPPED* ]]; then
echo "restart service amavis"
su - zimbra -c 'zmamavisdctl restart'
else
echo "Status service amavis OK"
fi

# Cek service antispam
if [[ "$antispam" == STOPPED* ]]; then
echo "restart service antispam"
su - zimbra -c 'zmantispamctl restart'
else
echo "Status service antispam OK"
fi

# Cek service antivirus
if [[ "$antivirus" == STOPPED* ]]; then
echo "restart service antivirus"
su - zimbra -c 'zmantivirusctl restart'
else
echo "Status service antivirus OK"
fi

# Cek service opendkim
if [[ "$opendkim" == STOPPED* ]]; then
echo "restart service opendkim"
su - zimbra -c 'zmopendkimctl restart'
else
echo "Status service opendkim OK"
fi

# Cek service cbpolicyd
if [[ "$cbpolicyd" == STOPPED* ]]; then
echo "restart service cbpolicyd"
su - zimbra -c 'zmcbpolicydctl restart'
else
echo "Status service cbpolicyd OK"
fi

# Cek service snmp
if [[ "$snmp" == STOPPED* ]]; then
echo "restart service snmp"
su - zimbra -c 'zmswatchctl restart'
else
echo "Status service snmp OK"
fi

# Cek service spell
if [[ "$spell" == STOPPED* ]]; then
echo "restart service spell"
su - zimbra -c 'zmspellctl restart'
else
echo "Status service spell OK"
fi

# Cek service mta
if [[ "$mta" == STOPPED* ]]; then
echo "restart service mta"
su - zimbra -c 'zmmtactl restart'
else
echo "Status service mta OK"
fi

# Cek service stats
if [[ "$stats" == STOPPED* ]]; then
echo "restart service stats"
su - zimbra -c 'zmstatctl restart'
else
echo "Status service stats OK"
fi

# Cek service mailbox
if [[ "$mailbox" == STOPPED* ]]; then
echo "restart service mailbox"
su - zimbra -c 'zmmailboxdctl restart'
else
echo "Status service mailbox OK"
fi
done

# Cek service kondisi sebelum restart dan pasca restart kemudian kirim via email

su - zimbra -c 'zmcontrol status' > /tmp/status-$ZCS-pasca-restart.txt
NOTRUNNING=`grep -woi "not running" /tmp/status-$ZCS-asli.txt | uniq`;
STOPPED=`grep -woi "stopped" /tmp/status-$ZCS-asli.txt | uniq`;

if [ "$NOTRUNNING" == "not running" -o "$STOPPED" == "Stopped" ] ; then

DARI="from:report@imanudin.com";
TUJUAN="to:admin@imanudin.com";
SALINAN="cc:monitoring@imanudin.com";
SERVER="$ZCS";
STATUS1=`cat /tmp/status-$ZCS-asli.txt`;
STATUS2=`cat /tmp/status-$ZCS-pasca-restart.txt`;
SUBJECT="Subject: [INFO] : Status Service $SERVER not Running atau Stopped"
BODY1="
Hi All,

Tadi ada beberapa/semua service Zimbra $SERVER Tidak berjalan loh. Berikut statusnya

$SERVER
*****************
$STATUS1
"
BODY2="
Tapi sekarang sudah diperbaiki dan dilakukan restart otomatis. Berikut statusnya saat ini

$SERVER
*****************
$STATUS2

Terima Kasih
AI -> Ahmad Imanudin not Artificial Intelligence :D
"
# Kirim email
echo "$DARI" > /tmp/statusservicezimbra.txt
echo "$TUJUAN" >> /tmp/statusservicezimbra.txt
echo "$SALINAN" >> /tmp/statusservicezimbra.txt
echo "$SUBJECT" >> /tmp/statusservicezimbra.txt
echo "$BODY1" >> /tmp/statusservicezimbra.txt
echo "" >> /tmp/statusservicezimbra.txt
echo "$BODY2" >> /tmp/statusservicezimbra.txt

cat /tmp/statusservicezimbra.txt | /opt/zimbra/postfix/sbin/sendmail -t
fi
echo "Status service Zimbra $ZCS aman"
