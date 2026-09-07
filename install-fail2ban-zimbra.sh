#!/bin/bash
# Jalankan sebagai root: bash install-fail2ban-zimbra.sh
set -e

# Cek akses root
if [ "$EUID" -ne 0 ]; then
    echo "Jalankan script sebagai root atau gunakan sudo."
    exit 1
fi

# Cek OS dan instal paket
source /etc/os-release
if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
    apt update
    apt install -y fail2ban wget ipset
else
    dnf install -y epel-release
    dnf install -y fail2ban wget ipset
fi

# Download jail Zimbra
cd /etc/fail2ban/jail.d/
wget -O zimbra-msc.local https://raw.githubusercontent.com/imanudin11/zimbra-fail2ban/master/zimbra-msc.local

# Download filter Zimbra
cd /etc/fail2ban/filter.d/
wget -O zimbra-smtp.conf https://raw.githubusercontent.com/imanudin11/zimbra-fail2ban/master/zimbra-smtp.conf
wget -O zimbra-nonsmtp.conf https://raw.githubusercontent.com/imanudin11/zimbra-fail2ban/master/zimbra-nonsmtp.conf
wget -O zimbra-cmdinject.conf https://raw.githubusercontent.com/imanudin11/zimbra-fail2ban/master/zimbra-cmdinject.conf
wget -O zimbra-nginx.conf https://raw.githubusercontent.com/imanudin11/zimbra-fail2ban/master/zimbra-nginx.conf
wget -O zimbra-nginx-authfail.conf https://raw.githubusercontent.com/imanudin11/zimbra-fail2ban/master/zimbra-nginx-authfail.conf
wget -O zimbra-imap-auth.conf https://raw.githubusercontent.com/imanudin11/zimbra-fail2ban/master/zimbra-imap-auth.conf
wget -O zimbra-uri.conf https://raw.githubusercontent.com/imanudin11/zimbra-fail2ban/master/zimbra-uri.conf

# Download script pemeriksaan
cd /usr/local/bin/
wget -O f2b-why https://raw.githubusercontent.com/imanudin11/zimbra-fail2ban/refs/heads/master/f2b-why
wget -O f2b-count https://raw.githubusercontent.com/imanudin11/zimbra-fail2ban/refs/heads/master/f2b-count
chmod +x f2b-why f2b-count

cat > /etc/fail2ban/jail.d/99-excellent-ignoreip.local <<'EOF'
[DEFAULT]
ignoreself = true
ignoreip = 127.0.0.1/8 ::1 192.53.174.242/32 172.104.49.236/32 172.232.226.193/32
EOF

# Uji konfigurasi sebelum restart
fail2ban-client -t

# Aktifkan dan restart service
systemctl enable fail2ban
if ! systemctl restart fail2ban; then
    systemctl status fail2ban --no-pager -l
    exit 1
fi

# Tampilkan status asli dari systemctl
systemctl status fail2ban --no-pager -l
