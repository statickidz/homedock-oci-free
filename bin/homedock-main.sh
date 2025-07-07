#!/bin/bash

# Ensure we're running as root
if [ "$EUID" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

# Log everything
exec > >(tee -a /var/log/homedock-install.log)
exec 2>&1

echo "=== Starting HomeDock OS setup at $(date) ==="

# Wait for system to be ready
sleep 30

# Wait for package manager to be available
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ||
    fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    echo "Waiting for package manager..."
    sleep 5
done

# Update package lists first
apt update -y

# Check if the /opt/ directory exists
if [ ! -d "/opt/" ]; then
    mkdir -p /opt/
fi

# Change to the /opt/ directory
cd /opt/

# Add ubuntu SSH authorized keys to the root user
mkdir -p /root/.ssh
cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/
chown root:root /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# Add ubuntu user to sudoers
echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# OpenSSH
apt install -y openssh-server
systemctl status sshd

# Permit root login
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart sshd

# Allow all traffic
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F
iptables --flush

# Save iptables rules
apt install -y netfilter-persistent
netfilter-persistent save

# Install HomeDockOS > pseudo-TTY
echo "Installing HomeDock OS..."
script -qec "curl -fsSL https://get.homedock.cloud | bash" /dev/null

echo "=== HomeDock OS setup completed at $(date) ==="
