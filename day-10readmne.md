# 📅 Day 10 – Automate Website Backup with Bash Script

## 🎯 Task

Create a bash script named `media_backup.sh` on **App Server 1** to automate website backups.

Requirements:

* Archive `/var/www/html/media` into a zip file
* Save it as `/backup/xfusioncorp_media.zip`
* Copy the archive to **Nautilus Storage Server (`ststor01`)** under `/backup/`
* Ensure **passwordless SSH** for copying
* Script must be executable by user `tony`
* Do **not use sudo inside the script**

---

## 🧠 Understanding the Task

This task simulates a real-world **backup automation scenario**:

* Web assets must be backed up regularly
* Local backup is temporary
* Remote storage ensures durability
* SSH key-based authentication enables automation

---

## ⚙️ Solution

### Step 1: Connect to App Server 1

```bash
ssh tony@stapp01
```

---

### Step 2: Ensure Required Packages

```bash
sudo yum install -y zip
```

---

### Step 3: Setup Passwordless SSH (if not already done)

```bash
ssh-keygen -t rsa
ssh-copy-id natasha@ststor01
```

---

### Step 4: Create Script Directory

```bash
mkdir -p /scripts
```

---

### Step 5: Create Script

```bash
vi /scripts/media_backup.sh
```

(Add script from `media_backup.sh` file)

---

### Step 6: Make Script Executable

```bash
chmod +x /scripts/media_backup.sh
```

---

### Step 7: Execute Script

```bash
/scripts/media_backup.sh
```

---

## ✅ Verification

### Check local backup:

```bash
ls /backup
```

Expected:

```
xfusioncorp_media.zip
```

---

### Check remote backup:

```bash
ssh natasha@ststor01
ls /backup
```

Expected:

```
xfusioncorp_media.zip
```

---

## ❗ Common Mistakes

* Not setting up passwordless SSH
* Not making script executable

---

## 🏁 Result

* Backup script created successfully
* Website files archived
* Backup stored locally and remotely
* Fully automated and ready for scheduling

---

## 💡 Real-World Relevance

This pattern is used in:

* Website backups
* Disaster recovery setups
* Scheduled cron-based backups
* DevOps automation pipelines

---
