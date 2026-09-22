#!/bin/bash
# ============================================================
# Part 8: System Cleanup Script
# Description: Safely deletes all created resources in reverse order
# ============================================================

# Define the service user variable
SVC_NAME="bgdsvc_mahdi"

echo "Starting system cleanup..."

# Step 1: Stop any running processes for this user
echo "1. Stopping active processes..."
sudo pkill -u "$SVC_NAME" 2>/dev/null || true

# Step 2: Remove cron automation, logrotate rule, and custom scripts
echo "2. Removing cron jobs, logrotate configs, and scripts..."
sudo crontab -r -u "$SVC_NAME" 2>/dev/null || true
sudo rm -f "/etc/logrotate.d/${SVC_NAME}"
sudo rm -f "/usr/local/bin/${SVC_NAME}_monitor.sh"
sudo rm -f "/usr/local/bin/${SVC_NAME}_cleanup_old_files.sh"

# Step 3: Unmount and delete temporary storage directory
echo "3. Cleaning up storage directory..."
if mount | grep -q "/mnt/${SVC_NAME}_tmp"; then
    sudo umount "/mnt/${SVC_NAME}_tmp" 2>/dev/null || true
fi
sudo rm -rf "/mnt/${SVC_NAME}_tmp"

# Step 4: Remove log directory
echo "4. Removing log directory..."
sudo rm -rf "/var/log/${SVC_NAME}"

# Step 5: Delete the service user account and home directory
echo "5. Deleting service user..."
sudo userdel -r "$SVC_NAME" 2>/dev/null || true

echo "Cleanup complete! System restored to original state."
