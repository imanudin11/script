#!/bin/bash
# TDH 2015-04-27
# Messy script for zimbra password expiry email notification.
# Meant to be performed as daily cronjob run as zimbra user. 
# redirect output to a file to get a 'log file' of sorts.

# Time taken of script;
echo "$SECONDS Started on: $(date)"

# Set some vars:
# First notification in days, then last warning:
FIRST="7"
LAST="3"
# pass expiry in days
POLICY="90"
# Sent from:
FROM="postmaster@imanudin.com"
# Domain to check, e.g. 'example.com'; leave blank for all
DOMAIN=""
# Recipient who should receive an email with all expired accounts
ADMIN_RECIPIENT="postmaster@imanudin.com"

# Sendmail executable
SENDMAIL=$(ionice -c3 find /opt/zimbra/ -type f -iname sendmail)

# Get all users - it should run once only.
USERS=`/opt/zimbra/bin/zmprov -l gaa`;

#Todays date, in seconds:
DATE=$(date +%s)

# Iterate through them in for loop:
for USER in $USERS
 do
# When was the password set?
OBJECT="(&(objectClass=zimbraAccount)(mail=$USER))"
ZIMBRA_LDAP_PASSWORD=`su - zimbra -c "zmlocalconfig -s zimbra_ldap_password | cut -d ' ' -f3"`
LDAP_MASTER_URL=`su - zimbra -c "zmlocalconfig -s ldap_master_url | cut -d ' ' -f3"`
LDAPSEARCH=$(ionice -c3 find /opt/zimbra/ -type f -iname ldapsearch)
PASS_SET_DATE=`$LDAPSEARCH -H $LDAP_MASTER_URL -w $ZIMBRA_LDAP_PASSWORD -D uid=zimbra,cn=admins,cn=zimbra -x $OBJECT | grep zimbraPasswordModifiedTime: | cut -d " " -f 2 | cut -c 1-8`

# Make the date for expiry from now.
EXPIRES=$(date -d  "$PASS_SET_DATE $POLICY days" +%s)

# Now, how many days until that?
DEADLINE=$(( (($DATE - $EXPIRES)) / -86400 ))

# Email to send to victims, ahem - users...
SUBJECT="$USER - Password email anda akan expire $DEADLINE hari lagi"
BODY="
Kepada Yth $USER,

Dengan ini diberitahukan bahwa password Email Anda akan expire dalam $DEADLINE hari. Harap mengganti password Email Anda segera melalui Web Mail:

 - Akses : https://mail.imanudin.com

Cara penggantian password Email :

1. Login pada Web Mail sesuai alamat di atas
2. Pilih tab Preferences
3. Pada menu General | Sign in. klik tombol Change Password
4. Isikan password lama, password baru & konfirmasi password baru Anda
5. Klik tombol Change password untuk menggantinya

Password akun Email minimal terdiri dari 8 karakter, dengan kombinasi alphanumerik (huruf besar, huruf kecil, angka) dan simbol (!@#$, dst.).

Jika ada pertanyaan mengenai cara mengganti password Email, silakan menghubungi team Support pada ext. 123321


Terima Kasih,
Postmaster
"
# Send it off depending on days, adding verbose statements for the 'log'
# First warning
if [[ "$DEADLINE" -eq "$FIRST" ]]
then
	echo "Subject: $SUBJECT" "$BODY" | $SENDMAIL -f "$FROM" "$USER"
	echo "Reminder email sent to: $USER - $DEADLINE days left" 
# Second
elif [[ "$DEADLINE" -eq "$LAST" ]]
then
	echo "Subject: $SUBJECT" "$BODY" | $SENDMAIL -f "$FROM" "$USER"
	echo "Reminder email sent to: $USER - $DEADLINE days left"
# Final
elif [[ "$DEADLINE" -eq "1" ]]
then
    echo "Subject: $SUBJECT" "$BODY" | $SENDMAIL -f "$FROM" "$USER"
	echo "Last chance for: $USER - $DEADLINE days left"
	
else 

    echo "Account: $USER reports; $DEADLINE days on Password policy"
fi

# Finish for loop
done

echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
