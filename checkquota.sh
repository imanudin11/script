#!/bin/bash
# Dibuat oleh Ahmad Imanudin (https://imanudin.net | https://imanudin.com)

clear

# Variable yang harus disesuaikan
tanggal=`date +"%d-%b-%Y"`;
attachment="quota-usage-report-$tanggal.csv";
emailSender="quotareport@imanudin.net";
emailRecipient="admin@imanudin.net";
emailSubject="Quota usage report $tanggal";
emailBody="Terlampir adalah laporan penggunaan quota per tanggal $tanggal";
mtaServer="localhost";

# Hapus attachment jika ada
yes | rm /tmp/$attachment

# Jalankan script pengecekan quota

/opt/zimbra/libexec/checkquota.pl > /tmp/$attachment

# Kirim laporan via email

/usr/bin/swaks --to $emailRecipient --from "$emailSender" --header "Subject: $emailSubject" --body "$emailBody" --attach /tmp/$attachment --server $mtaServer
