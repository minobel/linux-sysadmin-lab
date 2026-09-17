#!/bin/bash

# Set the service account name
SVC_NAME="bgdsvc_nobel"

echo "Checking if user $SVC_NAME exists..."

# Check if the user already exists in the system
if id "$SVC_NAME" > /dev/null 2>&1; then
    echo "User $SVC_NAME already exists. Skipping creation."
else
    echo "User $SVC_NAME does not exist. Creating now..."
    sudo useradd -r -m -s /usr/sbin/nologin "$SVC_NAME"
    echo "User $SVC_NAME created successfully!"
fi

# Show user details
echo "--- User Details ---"
id "$SVC_NAME"
