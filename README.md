# 🐧 Linux SysAdmin Story — DevOps Practical Lab

This repository documents the step-by-step implementation of a production-like test environment setup for **BongoDev**, built using Linux CLI and Bash scripting.

## 📖 Project Scenario & Objectives

As a Junior DevOps Engineer at **BongoDev**, the objective is to build, test, and safely tear down an environment for an upcoming internal service:

1.  **Service Identity:** Create an isolated system user following the **Principle of Least Privilege**.
    
2.  **Scratch Storage & Load Simulation:** Provision temporary memory storage and simulate real workload.
    
3.  **Automated Logging & Monitoring:** Set up automated log generation, log rotation, and periodic system checks.
    
4.  **Environment Teardown:** Ensure a clean cleanup of all created artifacts without leaving residual files.
    

## 🛠️ Part 1 — Service Identity Setup

### 📌 Overview & Concept

Background services should never run under `root` or a personal login account. In this step, we provision a dedicated system account with:

-   **`-r`**: System account (UID < 1000).
    
-   **`-m`**: Dedicated home directory (`/home/bgdsvc_nobel`).
    
-   **`-s /usr/sbin/nologin`**: Restricts interactive shell and SSH access for security.
    

### 💻 Commands Executed

Bash

```
# 1. Set identity variable
export SVC_NAME=bgdsvc_nobel

# 2. Create non-login system service account
sudo useradd -r -m -s /usr/sbin/nologin "$SVC_NAME"

# 3. Verify user creation
id "$SVC_NAME"
getent passwd "$SVC_NAME"

```

## 📦 Deliverables

### 🔹 Part 1 Deliverable: `01_create_user.sh`

-   **Script File Location:** [scripts/01_create_user.sh](https://github.com/minobel/linux-sysadmin-lab/blob/main/scripts/01_create_user.sh)
    
-   **Requirement:** Make the script **Idempotent** (safe to run twice by checking if the user already exists before attempting creation).
    

#### 🧪 Idempotency Proof & Execution Output

Plaintext

```
nobel@DESKTOP-G7VQA63:~/linux-sysadmin-lab$ ./scripts/01_create_user.sh
Checking if user bgdsvc_nobel exists...
User bgdsvc_nobel already exists. Skipping creation.
--- User Details ---
uid=999(bgdsvc_nobel) gid=986(bgdsvc_nobel) groups=986(bgdsvc_nobel)
```
## ⚡ Part 2 — Give It Somewhere Fast to Work (`tmpfs`)

### 📌 Overview & Concept

Real disks can introduce I/O latency bottlenecks. To provide the internal service with high-speed temporary storage (like a cache), we provision a **`tmpfs`** filesystem that lives entirely in system memory (RAM).

> ⚠️ **Watch Out (Critical Rule):**  
> Always set a hard size limit using `-o size=256M`. Omitting the size cap allows `tmpfs` to grow dynamically until it consumes all available RAM, causing host system freezes or Kernel OOM (Out-Of-Memory) crashes.

---

### 💻 Commands Executed

```bash
# 1. Create the mount point directory
sudo mkdir -p "/mnt/${SVC_NAME}_tmp"

# 2. Mount tmpfs with a strict 256MB memory cap
sudo mount -t tmpfs -o size=256M tmpfs "/mnt/${SVC_NAME}_tmp"

# 3. Assign file ownership to the service account
sudo chown "$SVC_NAME:$SVC_NAME" "/mnt/${SVC_NAME}_tmp"

# 4. Verify memory allocation and mount status
df -h "/mnt/${SVC_NAME}_tmp"

```
## 📦 Deliverables

### 🔹 Part 2 Deliverable: `02_setup_tmpfs.sh`

-   **Script File Location:** [scripts/02_setup_tmpfs.sh](https://github.com/minobel/linux-sysadmin-lab/blob/main/scripts/02_setup_tmpfs.sh)
    
-   **Requirement:** Idempotent provisioning of RAM-backed scratch space with a strict `256M` size cap and ownership assignment to `$SVC_NAME`.
    

#### 🧪 Script Execution Output
Plaintext
```nobel@DESKTOP-G7VQA63:~/linux-sysadmin-lab$ ./scripts/02_setup_tmpfs.sh
=== Part 2: Setting up tmpfs ===
[1/4] Creating mount directory at /mnt/bgdsvc_nobel_tmp...
[2/4] Mounting tmpfs with 256M size cap...
[3/4] Assigning ownership to service user: bgdsvc_nobel...
[4/4] Verifying tmpfs mount allocation:
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           256M     0  256M   0% /mnt/bgdsvc_nobel_tmp
=== Part 2 Completed Successfully ===
```
## 💥 Part 3 — System Stress Testing & Resource Allocation

### 📌 Overview & Objective
This phase focuses on validating system resilience under heavy load. By simulating resource exhaustion—filling the isolated RAM disk (`tmpfs`), maxing out CPU cores, and allocating dedicated memory blocks—we observed system behavior, verified process limits under dedicated service accounts, and monitored kernel stability.

---

### 💻 Manual Commands & Workflows

```bash
# 1. Disk Stress Test (Populating RAM Disk)
for i in $(seq 1 20); do
  dd if=/dev/urandom of="/mnt/${SVC_NAME}_tmp/file_$i.dat" bs=1M count=10
  df -h "/mnt/${SVC_NAME}_tmp"
done

# 2. Dedicated CPU Stress Test (2 cores for 30s)
sudo -u "$SVC_NAME" stress-ng --cpu 2 --temp-path "/mnt/${SVC_NAME}_tmp" --timeout 30s

# 3. Dedicated Memory Stress Test (200MB allocation for 30s)
sudo -u "$SVC_NAME" stress-ng --vm 1 --vm-bytes 200M --temp-path "/mnt/${SVC_NAME}_tmp" --timeout 30s

# 4. Simultaneous Multi-Resource Load Test
sudo -u "$SVC_NAME" stress-ng --cpu 2 --vm 1 --vm-bytes 200M --temp-path "/mnt/${SVC_NAME}_tmp" --timeout 30s & \
for i in $(seq 1 5); do 
  dd if=/dev/urandom of="/mnt/${SVC_NAME}_tmp/file_$i.dat" bs=1M count=10 2>/dev/null
done

```

## 📦 Deliverables

### 🔹 Part 3 Deliverable: `03_stress_and_populate.sh`

-   **Script Location:** [scripts/03_stress_and_populate.sh](https://github.com/minobel/linux-sysadmin-lab/blob/main/scripts/03_stress_and_populate.sh)
    
-   **Description:** Automates disk population, CPU stress, memory stress, and combined parallel stress testing using configurable CLI flags (`--disk`, `--cpu`, `--mem`, `--all`).

 #### 🧪 System Monitoring Output & Evidence 
 - **[`screenshots/03_free_before.png`](https://github.com/minobel/linux-sysadmin-lab/blob/main/screenshots/Part%203/Bash%20Script%20Output/03_free_before.png)**: Baseline memory state before triggering stress tests. 
 - **[`screenshots/03_free_during.png`](https://github.com/minobel/linux-sysadmin-lab/blob/main/screenshots/Part%203/Bash%20Script%20Output/03_free_during.png)**: Memory and system load during active multi-resource stress execution. 
 - **[`screenshots/03_free_after.png`](https://github.com/minobel/linux-sysadmin-lab/blob/main/screenshots/Part%203/Bash%20Script%20Output/03_free_after.png)**: Post-execution memory usage showing resource recovery. 
 - **[`screenshots/03_dmesg_oom.png`](https://github.com/minobel/linux-sysadmin-lab/blob/main/screenshots/Part%203/Bash%20Script%20Output/03_dmesg_oom.png)**: Kernel audit using `dmesg | grep -i oom` confirming no unhandled Out-Of-Memory process kills occurred during the tests.

```
```
### 🔑 Part 4 — Give It a Front Door (SSH Public Key Authentication)

### 📌 Overview & Concept
In this section, secure remote administration access was set up for the service user (`bgdsvc_mahdi`). Password-based logins are inherently insecure for automated service accounts, so we implemented **Ed25519 Public Key Cryptography**.

Key security constraints enforced:
1. **Public/Private Key Handshake:** Authentication is granted solely via matched Ed25519 key pairs.
2. **POSIX Permission Hardening:** OpenSSH strictly rejects keys with loose permissions.
   - `.ssh` directory: `700` (`rwx------`)
   - `authorized_keys` file: `600` (`rw-------`)
3. **Restricted Shell Policy:** Since `bgdsvc_mahdi` is a non-interactive service account (assigned `/usr/sbin/nologin`), SSH successfully authenticates the key and immediately terminates the interactive terminal session, maintaining zero-trust system integrity.

---

### 💻 Command-by-Command Execution History

#### 1. OpenSSH Server Verification & Service Activation
Ensure OpenSSH server binaries are present and active on the host:
```bash
sudo apt update && sudo apt install openssh-server -y
sudo systemctl enable --now ssh
systemctl status ssh sshd 2>/dev/null

```

#### 2. Ed25519 SSH Key Pair Generation

Generate a high-security Ed25519 key pair dedicated to the service account:

Bash

```
ssh-keygen -t ed25519 -f ~/.ssh/${SVC_NAME}_key

```

-   **Private Key:** `~/.ssh/bgdsvc_mahdi_key` (Kept secret on client machine)
    
-   **Public Key:** `~/.ssh/bgdsvc_mahdi_key.pub` (Deployed to server)
    

#### 3. Provisioning Authorized Keys & Permissions

Deploy the public key to the target user's home directory and enforce strict file ownership and POSIX mode bits:

Bash

```
# Create target SSH directory
sudo mkdir -p "/home/$SVC_NAME/.ssh"

# Deploy public key into authorized_keys
sudo cp ~/.ssh/${SVC_NAME}_key.pub "/home/$SVC_NAME/.ssh/authorized_keys"

# Set proper user and group ownership
sudo chown -R "$SVC_NAME:$SVC_NAME" "/home/$SVC_NAME/.ssh"

# Apply strict POSIX permissions
sudo chmod 700 "/home/$SVC_NAME/.ssh"
sudo chmod 600 "/home/$SVC_NAME/.ssh/authorized_keys"

```

#### 4. Authentication Verification

Test the SSH handshake via identity flag `-i`:

Bash

```
ssh -i ~/.ssh/bgdsvc_mahdi_key bgdsvc_mahdi@localhost

```
### 📦 Deliverables & Verification Evidence
* **Automation Script:** [`scripts/04_setup_ssh.sh`](./scripts/04_setup_ssh.sh)
* **Execution Evidence:**
  - **[`screenshots/04_ssh_key_connect.png`](./screenshots/04_ssh_key_connect.png):** Confirms successful passwordless authentication handshake, followed by shell isolation enforcement (`This account is currently not available.`).
  - **[`screenshots/04_systemctl_status.png`](./screenshots/04_systemctl_status.png):** Demonstrates active `sshd` daemon status with journald system logs confirming `Accepted publickey for bgdsvc_mahdi`.
  ```
  
---
## 🔒 Part 5 — Lock the Door Properly (SSH Hardening)

### 📌 Overview & Hardening Constraints
In this phase, we implemented production-grade OpenSSH security hardening on the server to prevent common attack vectors:
1. **Port Migration (`Port 2222`):** Changed the default listening port from 22 to 2222 to eliminate automated bot scans.
2. **Disabling Password Authentication (`PasswordAuthentication no`):** Completely removed password-based login to enforce strict key-pair isolation.
3. **Disabling Direct Root Access (`PermitRootLogin no`):** Prevents administrative logins via root; privileges must be escalated through dedicated user accounts.
4. **Restricted Access Control (`AllowUsers`):** Strictly restricted SSH access to authorized accounts (`bgdsvc_mahdi` and system admin `nobel`).

---

### ⚠️ Technical Root Cause Analysis: `ssh.socket` Conflict
During initial testing, connecting via `-p 2222` resulted in `Connection refused` despite updating `/etc/ssh/sshd_config`. 

* **Root Cause:** Modern Ubuntu releases utilize `ssh.socket` for systemd socket activation, which overrides `sshd_config` port directives and strictly binds to Port 22.
* **Resolution:** Disabled `ssh.socket` and enabled `ssh.service` directly to allow `sshd` daemon to listen on custom Port 2222.

---

### 💻 Command Execution History

```bash
# 1. Edit SSH configuration file
sudo nano /etc/ssh/sshd_config

# Configured lines:
# Port 2222
# PermitRootLogin no
# PasswordAuthentication no
# AllowUsers bgdsvc_mahdi nobel

# 2. Resolve systemd socket activation conflict & enable direct service
sudo systemctl stop ssh.socket
sudo systemctl disable ssh.socket
sudo systemctl enable --now ssh.service
sudo systemctl restart ssh

# 3. Test hardened SSH connection on Port 2222
ssh -i ~/.ssh/bgdsvc_mahdi_key -p 2222 bgdsvc_mahdi@localhost

```

### 📦 Deliverables & Verification Evidence

-   **Execution Evidence:**
    
    -   **[`screenshots/05_ssh_port_2222_login.png`](https://github.com/minobel/linux-sysadmin-lab/blob/main/screenshots/Part%205/05.ssh_port_2222_login.png):** Confirms successful SSH handshake on hardened Port 2222, followed by immediate shell execution termination (`This account is currently not available.`).
        
    -   **[`screenshots/05_systemctl_status_port2222.png`](https://github.com/minobel/linux-sysadmin-lab/blob/main/screenshots/Part%205/05.systemctl_status_port2222.png):** Demonstrates active `sshd` service bound specifically to Port 2222..
    ```
---
### ⏰ Part 6 — Teach the System to Watch Itself (Cron)

### 📌 Overview & System Automation
In this section, automated reporting and maintenance tasks were configured using scheduled `cron` jobs under the isolated service user (`bgdsvc_mahdi`):
1. **Health Monitoring (`bgdsvc_mahdi_monitor.sh`):** Runs every 5 minutes (`*/5 * * * *`) to append system memory (`free -h`), scratch directory storage usage (`df -h`), and running processes (`ps -u`) to `/var/log/bgdsvc_mahdi/monitor.log`.
2. **Nightly File Cleanup (`bgdsvc_mahdi_cleanup_old_files.sh`):** Executes daily at 2:00 AM (`0 2 * * *`) to delete test files older than 24 hours from `/mnt/bgdsvc_mahdi_tmp/`, keeping disk space clear.

---

### 💻 Command & Script Execution History

#### 1. Directory Provisioning & Permissions
```bash
sudo mkdir -p /var/log/bgdsvc_mahdi
sudo chown -R bgdsvc_mahdi:bgdsvc_mahdi /var/log/bgdsvc_mahdi
sudo chmod 755 /var/log/bgdsvc_mahdi

```

#### 2. System Monitoring Script (`/usr/local/bin/bgdsvc_mahdi_monitor.sh`)

Bash

```
#!/bin/bash
SVC_NAME="bgdsvc_mahdi"
LOGFILE="/var/log/${SVC_NAME}/monitor.log"
echo "--- $(date) ---" >> "$LOGFILE"
free -h >> "$LOGFILE"
df -h "/mnt/${SVC_NAME}_tmp" >> "$LOGFILE" 2>&1
ps -u "$SVC_NAME" >> "$LOGFILE" 2>&1

```

#### 3. Cleanup Script (`/usr/local/bin/bgdsvc_mahdi_cleanup_old_files.sh`)

Bash

```
#!/bin/bash
SVC_NAME="bgdsvc_mahdi"
TMPDIR="/mnt/${SVC_NAME}_tmp"
LOGFILE="/var/log/${SVC_NAME}/monitor.log"

find "$TMPDIR" -type f -mtime +1 -delete
echo "$(date): cleanup run - removed files older than 1 day from $TMPDIR" >> "$LOGFILE"

```

#### 4. Active Crontab Schedule (`sudo crontab -u bgdsvc_mahdi -l`)

Code snippet

```
*/5 * * * * /usr/local/bin/bgdsvc_mahdi_monitor.sh
0 2 * * * /usr/local/bin/bgdsvc_mahdi_cleanup_old_files.sh

```

### 📦 Deliverables & Verification Evidence

-   **Execution Evidence:**
    
    -   **[`screenshots/06_crontab_list.png`](https://github.com/minobel/linux-sysadmin-lab/blob/main/screenshots/Part%206/06_crontab_list.png):** Displays active cron schedule operating under `bgdsvc_mahdi`.
        
    -   **[`screenshots/06_monitor_log.png`](https://github.com/minobel/linux-sysadmin-lab/tree/main/screenshots/Part%206/Log-Monitor):** Confirms cron-driven automated health logs capturing memory, storage, and running process status.
    ```

---
## 🔄 Part 7 — Don't Let the Logs Eat the Disk (Logrotate)

### 🎯 Objective & Core Purpose
In a production-grade Linux environment, continuous monitoring services, debug tasks, and system activities generate ongoing log entries. Left unmanaged, these log files grow indefinitely and will eventually exhaust the server's available storage space (`Disk Full`). A full disk condition can crash services, cause database corruption, or lead to complete system downtime just as severely as a critical memory leak.

**Key Objectives of Part 7:**
* **Automated Log Rotation:** Establish an automated policy to archive active logs based on time intervals or file size limits.
* **Storage Space Optimization:** Automatically compress older log files (`.gz`) to conserve disk space.
* **Retention Policy Management:** Maintain a strict retention window (e.g., keeping only 5 historical rotations) and automatically purge stale logs.
* **Security & Ownership Preservation:** Ensure newly instantiated log files inherit exact ownership (`bgdsvc_mahdi:bgdsvc_mahdi`) and restricted permissions (`0640`).

---

### 💡 Key Technical Learnings
Implementing this module provided hands-on experience with production log lifecycle management:
* **Custom Logrotate Configurations:** Learned how to create and manage application-specific rotation rules inside the `/etc/logrotate.d/` directory.
* **Directive Functionality & Tuning:**
  * `daily`: Runs rotation checks on a daily schedule.
  * `rotate 5`: Retains up to 5 rotated backup archives before deleting the oldest entry.
  * `compress`: Compresses rotated log files using `gzip` to minimize disk footprint.
  * `size 10M`: Triggers immediate rotation if a log file reaches 10 Megabytes, regardless of the daily schedule.
  * `missingok`: Prevents error generation if a target log file is missing.
  * `notifempty`: Skips rotation if the log file contains zero data.
  * `create 0640 bgdsvc_mahdi bgdsvc_mahdi`: Recreates a fresh, empty active log file with exact `0640` permissions and service user ownership after rotation.
* **Testing & Manual Execution (`-f` flag):** Learned how to use `sudo logrotate -f` to force immediate policy execution and verify system behavior without waiting for scheduled cron triggers.

---

### 💻 Configuration & Verification Commands

#### 1. Logrotate Rule (`/etc/logrotate.d/bgdsvc_mahdi`)
```text
/var/log/bgdsvc_mahdi/*.log {
    daily
    rotate 5
    compress
    missingok
    notifempty
    size 10M
    create 0640 bgdsvc_mahdi bgdsvc_mahdi
}

```

#### 2. Execution & Verification Commands

Bash

```
# Apply proper permissions to the logrotate configuration
sudo chmod 644 /etc/logrotate.d/bgdsvc_mahdi

# Force manual execution of the logrotate rule
sudo logrotate -f /etc/logrotate.d/bgdsvc_mahdi

# Verify generated compressed archives and newly created active log file
ls -lh /var/log/bgdsvc_mahdi/

```

### 📦 Deliverables & Verification Evidence

-   **Execution Evidence:**
    
    -   **[`screenshots/07_logrotate_verification.png`](https://github.com/minobel/linux-sysadmin-lab/blob/main/screenshots/07_logrotate_verification.png):** Confirms successful log rotation, demonstrating the creation of the compressed archive `monitor.log.1.gz` alongside a newly instantiated, zero-byte `monitor.log` file with `0640` permissions assigned to `bgdsvc_mahdi:bgdsvc_mahdi`.
    ```

---

## 🧹 Part 8 — The Test Is Over. Leave No Trace. (Cleanup)

### 🎯 Objective & Architectural Overview

The primary objective of Part 8 is to perform a controlled, idempotent teardown of all system resources provisioned throughout Parts 1–7. Decommissioning isolated workloads in production environments requires leaving zero residual footprints to ensure system integrity and prevent resource leaking.

> **Why Order Matters: Reverse Execution Dependency**
> Teardown follows the exact **reverse order** of the initial build sequence:
> `Processes` ➔ `Automation` ➔ `Storage` ➔ `Logs` ➔ `Identity`

* **Killing Active Processes:** Linux prevents account deletion while processes remain bound to the UID. Running processes also lock mounted filesystems.
* **Purging Automation:** Removing cron jobs and logrotate policies prevents scheduled tasks from recreating deleted log directories.
* **Unmounting Storage:** Storage cannot be unmounted while open file descriptors exist within the mount point.
* **Purging Logs:** Clears diagnostic artifacts generated during execution.
* **Deleting Identity:** Removes user boundaries, home directory files, and authorization keys.

---

### 💡 Execution Steps & Command Reference

| Sequence | Action Target | Executed Commands | Technical Purpose |
| :--- | :--- | :--- | :--- |
| **Step 1** | **Processes** | `sudo pkill -u "bgdsvc_mahdi"` | Terminates active background jobs under the service UID, releasing file handles. |
| **Step 2** | **Automation** | `sudo crontab -r -u "bgdsvc_mahdi"`<br>`sudo rm -f /etc/logrotate.d/bgdsvc_mahdi`<br>`sudo rm -f /usr/local/bin/bgdsvc_mahdi_*` | Wipes cron schedules, custom logrotate rules, and executable binaries from system paths. |
| **Step 3** | **Storage** | `sudo umount /mnt/bgdsvc_mahdi_tmp`<br>`sudo rm -rf /mnt/bgdsvc_mahdi_tmp` | Unmounts scratch space filesystems and recursively deletes directory structures. |
| **Step 4** | **Logs** | `sudo rm -rf /var/log/bgdsvc_mahdi` | Cleans up system log tracking directories and `.gz` archives. |
| **Step 5** | **Identity** | `sudo userdel -r "bgdsvc_mahdi"` | Purges user account, primary group, home directory (`/home/bgdsvc_mahdi`), and SSH keys. |

---

### 🔍 Verification & Crime Scene Audit

| Audit Target | Command Executed | Observed Output | System State Result |
| :--- | :--- | :--- | :--- |
| **User Identity** | `id bgdsvc_mahdi` | `id: 'bgdsvc_mahdi': no such user` | User account, UID mapping, and home directory fully purged. |
| **Mount Points** | `mount \| grep "bgdsvc_mahdi"` | *(Empty)* | Zero lingering temporary mounts or locked storage descriptors. |
| **Process Table** | `ps -u bgdsvc_mahdi` | `error: user name does not exist` | No orphaned processes, background tasks, or active subshells remain. |

---

### 📦 Deliverables & Verification Evidence

* 📜 **Teardown Deliverable Script:** [`scripts/04_cleanup.sh`](https://github.com/minobel/linux-sysadmin-lab/blob/main/scripts/04_cleanup.sh) — Fully automated, idempotent system teardown script.
* 📸 **Execution & Audit Evidence:** [`screenshots/08_cleanup_verification.png`](https://github.com/minobel/linux-sysadmin-lab/blob/main/screenshots/08_cleanup_verification.png) — Terminal evidence confirming full resource clearance.





