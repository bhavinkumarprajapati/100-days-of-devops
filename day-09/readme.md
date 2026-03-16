# 📅 Day 09 – Fix MariaDB Service on Database Server

## 🎯 Task

The Nautilus application in **Stratos Datacenter** was unable to connect to the database.
The production support team identified that the **MariaDB service is down** on the database server.

Your task was to **investigate and fix the issue**.

Server involved:

* `stdb01` → Nautilus Database Server

---

## 🧠 Understanding the Issue

The application relies on **MariaDB** as its backend database.
If the MariaDB service stops or fails to start, the application cannot:

* Establish database connections
* Retrieve or store data
* Serve requests properly

Therefore, restoring the **database service** is critical for application availability.

---

## 🔎 Investigation

### Step 1 – Connect to Database Server

```bash
ssh peter@stdb01
```

---

### Step 2 – Check MariaDB Service Status

```bash
systemctl status mariadb
```

Output showed:

```
Active: inactive (dead)
```

This confirmed the database service was **not running**.

---

### Step 3 – Check Logs

To identify the root cause:

```bash
journalctl -xeu mariadb.service
```

Error found:

```
Cannot change ownership of the database directories to the 'mysql' user
chown: changing ownership of '/var/lib/mysql': Operation not permitted
```

This indicated that **the MariaDB data directory had incorrect ownership**.

---

## ⚙️ Solution

### Fix Directory Ownership

MariaDB requires `/var/lib/mysql` to be owned by the `mysql` user.

```bash
sudo chown -R mysql:mysql /var/lib/mysql
```

---

### Start MariaDB Service

```bash
sudo systemctl start mariadb
```

---

### Enable Service at Boot

```bash
sudo systemctl enable mariadb
```

---

## ✅ Verification

Check service status again:

```bash
systemctl status mariadb
```

Expected output:

```
Active: active (running)
Status: "Taking your SQL requests now..."
```

MariaDB is now running successfully.

---

## 🏁 Result

* Root cause identified (incorrect directory ownership)
* Permissions fixed for `/var/lib/mysql`
* MariaDB service started successfully
* Database server restored
* Nautilus application can reconnect to the database

---

## 💡 Real-World Relevance

Service failures like this are common in production environments.
Typical troubleshooting workflow:

```bash
systemctl status <service>
journalctl -xeu <service>
```

These commands help quickly identify **configuration, permission, or dependency issues**.

---
