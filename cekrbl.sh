#!/bin/sh
# Check if an IP address is listed on one of the following blacklists
# The format is chosen to make it easy to add or delete
# The shell will strip multiple whitespace

yes | rm /tmp/cek-rbl.txt
yes | rm /tmp/rbl.txt

LISTIP="
103.xx.xx.xx
123.xx.xx.xx
"

for IPSERVER in $LISTIP; do

BLISTS="
bl.score.senderscore.com
bl.mailspike.net
bl.spameatingmonkey.net
b.barracudacentral.org
bl.deadbeef.com
bl.emailbasura.org
bl.spamcannibal.org
bl.spamcop.net
blackholes.five-ten-sg.com
blacklist.woody.ch
bogons.cymru.com
cbl.abuseat.org
cdl.anti-spam.org.cn
combined.abuse.ch
combined.rbl.msrbl.net
db.wpbl.info
dnsbl-1.uceprotect.net
dnsbl-2.uceprotect.net
dnsbl-3.uceprotect.net
dnsbl.inps.de
dnsbl.sorbs.net
drone.abuse.ch
drone.abuse.ch
duinv.aupads.org
dul.dnsbl.sorbs.net
dul.ru
dyna.spamrats.com
dynip.rothen.com
http.dnsbl.sorbs.net
images.rbl.msrbl.net
ips.backscatterer.org
ix.dnsbl.manitu.net
korea.services.net
misc.dnsbl.sorbs.net
noptr.spamrats.com
ohps.dnsbl.net.au
omrs.dnsbl.net.au
orvedb.aupads.org
osps.dnsbl.net.au
osrs.dnsbl.net.au
owfs.dnsbl.net.au
owps.dnsbl.net.au
pbl.spamhaus.org
phishing.rbl.msrbl.net
probes.dnsbl.net.au
proxy.bl.gweep.ca
proxy.block.transip.nl
psbl.surriel.com
rbl.interserver.net
rdts.dnsbl.net.au
relays.bl.gweep.ca
relays.bl.kundenserver.de
relays.nether.net
residential.block.transip.nl
ricn.dnsbl.net.au
rmst.dnsbl.net.au
sbl.spamhaus.org
short.rbl.jp
smtp.dnsbl.sorbs.net
socks.dnsbl.sorbs.net
spam.abuse.ch
spam.dnsbl.sorbs.net
spam.rbl.msrbl.net
spam.spamrats.com
spamlist.or.kr
spamrbl.imp.ch
t3direct.dnsbl.net.au
ubl.lashback.com
ubl.unsubscore.com
virbl.bit.nl
virus.rbl.jp
virus.rbl.msrbl.net
web.dnsbl.sorbs.net
wormrbl.imp.ch
xbl.spamhaus.org
zen.spamhaus.org
zombie.dnsbl.sorbs.net
"

reverse=$(echo $IPSERVER |
  sed -ne "s~^\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)$~\4.\3.\2.\1~p")

if [ "x${reverse}" = "x" ] ; then
      ERROR  "IMHO '$1' doesn't look like a valid IP address"
      exit 1
fi

# -- cycle through all the blacklists
for BL in ${BLISTS} ; do
    # show the reversed IP and append the name of the blacklist
#    printf "%-60s" " ${reverse}.${BL}."

    # use dig to lookup the name in the blacklist
    #echo "$(dig +short -t a ${reverse}.${BL}. |  tr '\n' ' ')"
dig +short -t a ${reverse}.${BL}. > /tmp/rbl$IPSERVER.txt
cekrbl=`cat /tmp/rbl$IPSERVER.txt`;

if [ -z "$cekrbl" ]; then
    echo "Horeeeeee, IP $IPSERVER aman dari RBL $BL"

else
echo "IP $IPSERVER terblacklist pada RBL $BL" >> /tmp/cek-rbl.txt

fi

done
done

BLACKLIST=`cat /tmp/cek-rbl.txt`;

if [ -z "$BLACKLIST" ]; then
    echo "IP tidak ada yang tercantum pada RBL"

else

DARI="from:report@example.com";
TUJUAN="to:admin@example.com";
SALINAN="cc:admin@example.com";
SUBJECT="Subject: IP Public Terblacklist pada RBL"
BODY="
Hi Team,

$BLACKLIST

Silakan dibersihkan

Terima Kasih
"

SENDMAIL=$(ionice -c3 find /opt/zimbra/ -type f -iname sendmail)
echo "$DARI
$TUJUAN
$SALINAN
$SUBJECT
$BODY" >> /tmp/rbl.txt
cat /tmp/rbl.txt | $SENDMAIL -t

echo "$BLACKLIST"
fi
