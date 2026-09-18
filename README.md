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

-   **Script File Location:** [scripts/02_setup_tmpfs.sh](https://www.google.com/search?q=./scripts/02_setup_tmpfs.sh&utm_source=gemini)
    
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