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
    
    -   **[`screenshots/06_crontab_list.png`](https://www.google.com/search?q=./screenshots/06_crontab_list.png&utm_source=gemini):** Displays active cron schedule operating under `bgdsvc_mahdi`.
        
    -   **[`screenshots/06_monitor_log.png`](https://www.google.com/search?q=./screenshots/06_monitor_log.png&utm_source=gemini):** Confirms cron-driven automated health logs capturing memory, storage, and running process status.




