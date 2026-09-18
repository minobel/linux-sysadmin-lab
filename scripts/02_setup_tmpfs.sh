#!/bin/bash

# Check if environment variable SVC_NAME is set
if [ -z "$SVC_NAME" ]; then
    echo "Error: SVC_NAME variable is missing! Run: export SVC_NAME=bgdsvc_mahdi"
    exit 1
fi

MOUNT_DIR="/mnt/${SVC_NAME}_tmp"

echo "=== Part 2: Setting up tmpfs ==="

# Step 1: Create target mount directory if it doesn't exist
echo "[1/4] Creating mount directory at $MOUNT_DIR..."
sudo mkdir -p "$MOUNT_DIR"

# Step 2: Mount memory-backed filesystem with a strict 256MB cap
echo "[2/4] Mounting tmpfs with 256M size cap..."
sudo mount -t tmpfs -o size=256M tmpfs "$MOUNT_DIR"

# Step 3: Assign file ownership to the service account
echo "[3/4] Assigning ownership to service user: $SVC_NAME..."
sudo chown "$SVC_NAME:$SVC_NAME" "$MOUNT_DIR"

# Step 4: Verify mounted filesystem status
echo "[4/4] Verifying tmpfs mount allocation:"
df -h "$MOUNT_DIR"

echo "=== Part 2 Completed Successfully ==="
