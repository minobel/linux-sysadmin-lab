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

-   **Script Location:** [scripts/03_stress_and_populate.sh](https://www.google.com/search?q=./scripts/03_stress_and_populate.sh&utm_source=gemini)
    
-   **Description:** Automates disk population, CPU stress, memory stress, and combined parallel stress testing using configurable CLI flags (`--disk`, `--cpu`, `--mem`, `--all`).

 #### 🧪 System Monitoring Output & Evidence - **[`screenshots/03_free_before.png`]([linux-sysadmin-lab/screenshots/Part 3/Bash Script Output/03_free_before.png at main · minobel/linux-sysadmin-lab](https://github.com/minobel/linux-sysadmin-lab/blob/main/screenshots/Part%203/Bash%20Script%20Output/03_free_before.png))**: Baseline memory state before triggering stress tests. - **[`screenshots/03_free_during.png`]([linux-sysadmin-lab/screenshots/Part 3/Bash Script Output/03_free_during.png at main · minobel/linux-sysadmin-lab](https://github.com/minobel/linux-sysadmin-lab/blob/main/screenshots/Part%203/Bash%20Script%20Output/03_free_during.png))**: Memory and system load during active multi-resource stress execution. - **[`screenshots/03_free_after.png`]([linux-sysadmin-lab/screenshots/Part 3/Bash Script Output/03_free_after.png at main · minobel/linux-sysadmin-lab](https://github.com/minobel/linux-sysadmin-lab/blob/main/screenshots/Part%203/Bash%20Script%20Output/03_free_after.png))**: Post-execution memory usage showing resource recovery. - **[`screenshots/03_dmesg_oom.png`]([linux-sysadmin-lab/screenshots/Part 3/Bash Script Output/03_dmesg_oom.png at main · minobel/linux-sysadmin-lab](https://github.com/minobel/linux-sysadmin-lab/blob/main/screenshots/Part%203/Bash%20Script%20Output/03_dmesg_oom.png))**: Kernel audit using `dmesg | grep -i oom` confirming no unhandled Out-Of-Memory process kills occurred during the tests.