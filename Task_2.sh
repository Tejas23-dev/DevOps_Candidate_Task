#!/bin/bash

# Define constants
REPORT_FILE="/var/log/security_audit_report.txt"
CONFIG_FILE="/etc/security_audit_config.conf"
EMAIL_ALERTS="your-email@example.com"

# Create report file and initialize
echo "Security Audit Report - $(date)" > $REPORT_FILE

# Function to list all users and groups
audit_users_groups() {
    echo -e "\n### User and Group Audits ###" >> $REPORT_FILE
    echo "Users and Groups:" >> $REPORT_FILE
    cut -d: -f1 /etc/passwd >> $REPORT_FILE
    cut -d: -f1 /etc/group >> $REPORT_FILE

    echo -e "\nUsers with UID 0 (root privileges):" >> $REPORT_FILE
    awk -F: '$3 == 0 {print $1}' /etc/passwd >> $REPORT_FILE

    echo -e "\nUsers without passwords or with weak passwords:" >> $REPORT_FILE
    awk -F: '($2 == "" || $2 == "x") {print $1}' /etc/passwd >> $REPORT_FILE
}

# Function to check file and directory permissions
audit_permissions() {
    echo -e "\n### File and Directory Permissions ###" >> $REPORT_FILE
    echo "World-writable files and directories:" >> $REPORT_FILE
    find / -perm -0002 -type f -o -type d >> $REPORT_FILE

    echo -e "\nSSH directory permissions:" >> $REPORT_FILE
    find /home -name ".ssh" -type d -exec ls -ld {} \; >> $REPORT_FILE

    echo -e "\nFiles with SUID or SGID bits set:" >> $REPORT_FILE
    find / -perm /6000 -type f -exec ls -l {} \; >> $REPORT_FILE
}

# Function to audit services
audit_services() {
    echo -e "\n### Service Audits ###" >> $REPORT_FILE
    echo "Running services:" >> $REPORT_FILE
    systemctl list-units --type=service --state=running >> $REPORT_FILE

    echo -e "\nChecking critical services configuration:" >> $REPORT_FILE
    systemctl status sshd >> $REPORT_FILE
    iptables -L -n -v >> $REPORT_FILE

    echo -e "\nServices listening on non-standard ports:" >> $REPORT_FILE
    netstat -tuln | grep -v ':22\|:80\|:443' >> $REPORT_FILE
}

# Function to check firewall and network security
audit_firewall_network() {
    echo -e "\n### Firewall and Network Security ###" >> $REPORT_FILE
    echo "Active firewall configuration:" >> $REPORT_FILE
    iptables -L -n -v >> $REPORT_FILE

    echo -e "\nOpen ports and associated services:" >> $REPORT_FILE
    ss -tuln >> $REPORT_FILE

    echo -e "\nIP forwarding status:" >> $REPORT_FILE
    sysctl net.ipv4.ip_forward >> $REPORT_FILE
}

# Function to check IP and network configuration
audit_ip_network() {
    echo -e "\n### IP and Network Configuration ###" >> $REPORT_FILE
    echo "IP addresses:" >> $REPORT_FILE
    ip a >> $REPORT_FILE

    echo -e "\nPublic vs. Private IPs:" >> $REPORT_FILE
    for ip in $(ip -o -4 addr show | awk '{print $4}' | cut -d/ -f1); do
        if [[ "$ip" == 10.* || "$ip" == 172.16.* || "$ip" == 192.168.* ]]; then
            echo "$ip is a private IP" >> $REPORT_FILE
        else
            echo "$ip is a public IP" >> $REPORT_FILE
        fi
    done
}

# Function to check security updates and patching
audit_updates() {
    echo -e "\n### Security Updates and Patching ###" >> $REPORT_FILE
    echo "Available updates:" >> $REPORT_FILE
    apt-get update -qq && apt-get -s upgrade | grep "^Inst" >> $REPORT_FILE

    echo -e "\nAutomatic updates configuration:" >> $REPORT_FILE
    cat /etc/apt/apt.conf.d/10periodic >> $REPORT_FILE
}

# Function to check logs for suspicious activities
audit_logs() {
    echo -e "\n### Log Monitoring ###" >> $REPORT_FILE
    echo "Recent SSH logins:" >> $REPORT_FILE
    grep "sshd" /var/log/auth.log | tail -n 50 >> $REPORT_FILE
}

# Function to apply server hardening steps
server_hardening() {
    echo -e "\n### Server Hardening Steps ###" >> $REPORT_FILE

    # SSH Configuration
    echo -e "\nConfiguring SSH:" >> $REPORT_FILE
    sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    systemctl restart sshd

    # Disabling IPv6
    echo -e "\nDisabling IPv6 (if required):" >> $REPORT_FILE
    sysctl -w net.ipv6.conf.all.disable_ipv6=1
    sysctl -w net.ipv6.conf.default.disable_ipv6=1
    sysctl -w net.ipv6.conf.lo.disable_ipv6=1

    # Securing the Bootloader
    echo -e "\nSecuring the GRUB bootloader:" >> $REPORT_FILE
    grub-mkpasswd-pbkdf2
    echo "Set a password for GRUB in /etc/grub.d/40_custom"

    # Firewall Configuration
    echo -e "\nConfiguring iptables firewall:" >> $REPORT_FILE
    iptables -F
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    iptables-save > /etc/iptables/rules.v4

    # Automatic Updates
    echo -e "\nConfiguring automatic updates:" >> $REPORT_FILE
    apt-get install unattended-upgrades -y
    dpkg-reconfigure --priority=low unattended-upgrades
}

# Function to send email alerts (optional)
send_email_alerts() {
    echo -e "\n### Sending Email Alerts ###" >> $REPORT_FILE
    if [[ -s $REPORT_FILE ]]; then
        mail -s "Security Audit Report" $EMAIL_ALERTS < $REPORT_FILE
    fi
}

# Main execution
audit_users_groups
audit_permissions
audit_services
audit_firewall_network
audit_ip_network
audit_updates
audit_logs
server_hardening
send_email_alerts

echo "Security audit and hardening completed. Report generated at $REPORT_FILE"
