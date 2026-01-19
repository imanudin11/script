#!/bin/bash


# --- BAGIAN INFORMASI/WARNING AWAL ---
clear
echo "================================================================"
echo "        PENTING: HARAP BACA SEBELUM MELANJUTKAN                "
echo "================================================================"
echo "1. Script ini hanya bisa dijalankan 1 KALI dan tidak bisa diulang."
echo "2. OS Target: Ubuntu 24.04 (Hanya ditest pada versi ini)."
echo "3. Pastikan Intel-VT atau AMD-V sudah aktif di BIOS."
echo "4. Jika diinstall pada VM Nested Proxmox, gunakan CPU type: 'host'."
echo "5. Minimal Spesifikasi: RAM 4 GB & 2 vCPU."
echo "6. Pastikan memiliki koneksi internet."
echo "7. Panduan ini berdasarkan link: https://scaleninja.com/blog/cloudstack/"
echo "================================================================"
echo ""

# Menanyakan konfirmasi sebelum lanjut
read -p "Apakah Anda sudah memastikan poin-poin di atas? (y/n): " setuju
if [[ "$setuju" != "y" ]]; then
    echo "Eksekusi dibatalkan."
    exit 1
fi

echo "Memulai proses..."
sleep 3
echo "Persiapan system"

# Ganti password Root

read -p "Masukkan password root : " passWord
printf "$passWord\n$passWord\n" | passwd root

# Konfigurasi hostname

read -p "Masukkan nama hostname (ie: cs1.imanudin.web.id) : " namaHostname
hostnamectl set-hostname $namaHostname

# Disable firewall and apparmor

echo -ne "\rDisable firewall and apparmor…..Done"

systemctl disable apparmor firewalld iptables
systemctl stop apparmor firewalld iptables

# Update Repo

echo -ne "\rUpdate repo….Done"

apt update -y
apt upgrade -y

# Install package standard

echo -ne "\rProses Install package standard... Done!"

apt-get -y install openntpd openssh-server sudo vim htop tar intel-microcode

# Setup Akses SSH via Root

echo "Allow Root Login via SSH"

# 1. Cek apakah konfigurasi "PermitRootLogin yes" sudah ada dan aktif (tidak di-comment)
if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
    echo "PermitRootLogin sudah dikonfigurasi yes, diabaikan."
else
    # 2. Cek apakah baris PermitRootLogin ada (mungkin di-comment atau nilainya salah)
    if grep -q "^#\?PermitRootLogin" /etc/ssh/sshd_config; then
        echo "Mengubah konfigurasi PermitRootLogin menjadi yes..."
        sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
    else
        # 3. Jika barisnya benar-benar tidak ada, tambahkan di akhir file
        echo "Menambahkan konfigurasi PermitRootLogin yes..."
        echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
    fi
fi

# 4. Restart service SSH agar perubahan diterapkan
systemctl restart ssh

# Setup network Bridge

echo -ne "\rInstall network bridge... Done!"

apt-get -y install bridge-utils

# Backup Network

mkdir /srv/backup-netplan/
mv /etc/netplan/* /srv/backup-netplan/

# Setup Network

# 1. Deteksi Interface Utama (yang memiliki default route)
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)

# 2. Deteksi IP Address dan Prefix (misal: 192.168.1.10/24)
IP_ADDR=$(ip -o -f inet addr show $INTERFACE | awk '{print $4}' | head -n1)
IP_ADDR_ONLY=$(ip -o -f inet addr show $INTERFACE | awk '{print $4}' | head -n1 | cut -d '/' -f1)


# 3. Deteksi Gateway (Via)
GATEWAY=$(ip route | grep default | awk '{print $3}' | head -n1)

# Konfigurasi /etc/hosts
echo "127.0.0.1 localhost
$IP_ADDR_ONLY    $namaHostname" > /etc/hosts

echo "--- Mendeteksi Konfigurasi Sistem ---"
echo "Interface: $INTERFACE"
echo "IP/Netmask: $IP_ADDR"
echo "Gateway: $GATEWAY"
echo "------------------------------------"

# 4. Generate Output YAML
cat <<EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE:
      dhcp4: false
      dhcp6: false
      optional: true
  bridges:
    cloudbr0:
      addresses: [$IP_ADDR]
      routes:
        - to: default
          via: $GATEWAY
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
      interfaces: [$INTERFACE]
      dhcp4: false
      dhcp6: false
      parameters:
        stp: false
        forward-delay: 0
EOF

# Generate dan apply network

netplan generate
netplan apply

# Setup Repo

echo -ne "\rKonfigurasi Repository….. Done"

mkdir -p /etc/apt/keyrings
wget -O- http://packages.shapeblue.com/release.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/cloudstack.gpg > /dev/null
echo deb [signed-by=/etc/apt/keyrings/cloudstack.gpg] http://packages.shapeblue.com/cloudstack/upstream/debian/4.22 / > /etc/apt/sources.list.d/cloudstack.list
apt-get update -y

# Install management server

echo -ne "\rInstall management server…Done"

apt-get -y install cloudstack-management mysql-server

# Setup Database

cat <<EOF > /etc/mysql/mysql.conf.d/mysqld.cnf
[mysqld]
server_id = 1
sql-mode="STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION,ERROR_FOR_DIVISION_BY_ZERO,NO_ZERO_DATE,NO_ZERO_IN_DATE,NO_ENGINE_SUBSTITUTION"
innodb_rollback_on_timeout=1
innodb_lock_wait_timeout=600
max_connections=1000
log-bin=mysql-bin
binlog-format = 'ROW'
#default-authentication-plugin=mysql_native_password
EOF

# Restart MySQL dan setup database

echo -ne "\Restart MySQL dan setup Database pada IP address $IP_ADDR_ONLY….Done"

systemctl restart mysql
cloudstack-setup-databases cloud:cloud@localhost --deploy-as=root: -i $IP_ADDR_ONLY

# Install NFS Server

echo -ne "\rInstall NFS Server…..Done"

apt-get -y install nfs-kernel-server quota

# Konfigurasi export

echo "/export  *(rw,async,no_root_squash,no_subtree_check)" > /etc/exports
mkdir -p /export/primary /export/secondary
exportfs -a

# Konfigurasi NFS

sed -i -e 's/^RPCMOUNTDOPTS="--manage-gids"$/RPCMOUNTDOPTS="-p 892 --manage-gids"/g' /etc/default/nfs-kernel-server
sed -i -e 's/^STATDOPTS=$/STATDOPTS="--port 662 --outgoing-port 2020"/g' /etc/default/nfs-common
echo "NEED_STATD=yes" >> /etc/default/nfs-common
sed -i -e 's/^RPCRQUOTADOPTS=$/RPCRQUOTADOPTS="-p 875"/g' /etc/default/quota
service nfs-kernel-server restart

# Setup KVM Host

echo -ne "\rInstall qemu-kvm…..Done"

apt-get -y install qemu-kvm cloudstack-agent

# Enable VNC for console proxy

sed -i -e 's/\#vnc_listen.*$/vnc_listen = "0.0.0.0"/g' /etc/libvirt/qemu.conf
echo LIBVIRTD_ARGS=\"--listen\" >> /etc/default/libvirtd

# Restart libvirt

systemctl mask libvirtd.socket libvirtd-ro.socket libvirtd-admin.socket libvirtd-tls.socket libvirtd-tcp.socket

# Edit libvirt

cat <<EOF >> /etc/libvirt/libvirt.conf
remote_mode="legacy"
EOF

# Konfigurasi default libvirtd

echo 'listen_tls=0' >> /etc/libvirt/libvirtd.conf
echo 'listen_tcp=1' >> /etc/libvirt/libvirtd.conf
echo 'tcp_port = "16509"' >> /etc/libvirt/libvirtd.conf
echo 'mdns_adv = 0' >> /etc/libvirt/libvirtd.conf
echo 'auth_tcp = "none"' >> /etc/libvirt/libvirtd.conf

# Konfigurasi UUID (jika diinstall di atas VM)

apt-get -y install uuid
UUID=$(uuid)
echo host_uuid = \"$UUID\" >> /etc/libvirt/libvirtd.conf
systemctl restart libvirtd

# Disable apparmor jika masih aktif

# Disable apparmour on libvirtd
ln -s /etc/apparmor.d/usr.sbin.libvirtd /etc/apparmor.d/disable/
ln -s /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper /etc/apparmor.d/disable/
apparmor_parser -R /etc/apparmor.d/usr.sbin.libvirtd
apparmor_parser -R /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper

# Start Control Plane

echo -ne "\rSetup CloudStack Management….Done"

cloudstack-setup-management
systemctl enable cloudstack-management

# Akses Control Plane

echo "--- Informasi Akses Control Plane ---"
echo "Proses Setup CloudStack Management membutuhkan waktu lebih kurang 15-30 menit"
echo "URL: http://$IP_ADDR_ONLY:8080"
echo "username : admin"
echo "password : password"
echo "------------------------------------"
echo "Jika belum bisa diakses, silakan pantau proses setup CloudStack Management pada log"
echo "tail -f /var/log/cloudstack/management/management-server.log"
