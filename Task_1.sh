#!/bin/bash

# Function to get top 10 most used applications
get_top_10_apps() {
    ps aux | sort -nr -k3 | head -10 | awk '{print $2}'
}

# Function to get network monitoring data
get_network_stats() {
    netstat -s | grep -E "packets received|packets transmitted|segments received|segments sent"
}

# Function to get disk usage
get_disk_usage() {
    df -h | awk '{print $1, $5}'
}

# Function to get system load
get_system_load() {
    uptime | awk '{print $10, $11, $12}'
}

# Function to get memory usage
get_memory_usage() {
    free -m | grep -m 1 "Mem" | awk '{print $2, $3, $4}'
}

# Function to get process monitoring data
get_process_stats() {
    ps aux | sort -nr -k3 | head -5 | awk '{print $2}'
}

# Function to get service status
get_service_status() {
    systemctl status sshd nginx apache iptables | grep "Active (running)"
}

# Main loop
while true; do
    clear
    echo "System Resource Monitoring Dashboard"
    echo "----------------------------------"

    # Display top 10 most used applications
    echo "Top 10 Most Used Applications:"
    top_apps=$(get_top_apps)
    echo "$top_apps"

    # Display network monitoring data
    echo "Network Monitoring:"
    network_stats=$(get_network_stats)
    echo "$network_stats"

    # Display disk usage
    echo "Disk Usage:"
    disk_usage=$(get_disk_usage)
    echo "$disk_usage"

    # Display system load
    echo "System Load:"
    system_load=$(get_system_load)
    echo "$system_load"

    # Display memory usage
    echo "Memory Usage:"
    memory_usage=$(get_memory_usage)
    echo "$memory_usage"

    # Display process monitoring data
    echo "Process Monitoring:"
    process_stats=$(get_process_stats)
    echo "$process_stats"

    # Display service status
    echo "Service Status:"
    service_status=$(get_service_status)
    echo "$service_status"

    sleep 5
done

