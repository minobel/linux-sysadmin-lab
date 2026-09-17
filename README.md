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
