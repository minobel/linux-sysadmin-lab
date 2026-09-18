#!/bin/bash

# Check if SVC_NAME is set
if [ -z "$SVC_NAME" ]; then
    echo "Error: SVC_NAME environment variable is missing!"
    exit 1
fi

MOUNT_DIR="/mnt/${SVC_NAME}_tmp"

# Helper functions for each stress test
run_disk_test() {
    echo "=== Running Disk Stress Test (Filling tmpfs) ==="
    for i in $(seq 1 20); do
        echo "Creating file_$i.dat..."
        dd if=/dev/urandom of="${MOUNT_DIR}/file_$i.dat" bs=1M count=10 2>/dev/null
        df -h "$MOUNT_DIR"
    done
}

run_cpu_test() {
    echo "=== Running CPU Stress Test (30s) ==="
    sudo -u "$SVC_NAME" stress-ng --cpu 2 --temp-path "$MOUNT_DIR" --timeout 30s
}

run_mem_test() {
    echo "=== Running Memory Stress Test (30s) ==="
    sudo -u "$SVC_NAME" stress-ng --vm 1 --vm-bytes 200M --temp-path "$MOUNT_DIR" --timeout 30s
}

# Check flags passed to the script
case "$1" in
    --disk)
        run_disk_test
        ;;
    --cpu)
        run_cpu_test
        ;;
    --mem)
        run_mem_test
        ;;
    --all)
        echo "=== Running ALL Stress Tests Simultaneously ==="
        run_disk_test
        run_cpu_test &
        run_mem_test &
        wait
        echo "=== All Stress Tests Finished ==="
        ;;
    *)
        echo "Usage: $0 {--disk|--cpu|--mem|--all}"
        exit 1
        ;;
esac
