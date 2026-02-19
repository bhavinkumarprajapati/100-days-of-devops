# 📅 Day 01 – Create User with Non-Interactive Shell

## 🎯 Task

Create a user named `jim` with a **non-interactive shell** on **App Server 1**.

---

## 🧠 Understanding the Task

A non-interactive shell prevents a user from logging into the system.

Common shells used:
- `/sbin/nologin`
- `/usr/sbin/nologin`

This is useful for:
- Service accounts
- Backup agents
- Security restrictions

---

## ⚙️ Solution

### Step 1: Connect to App Server 1
```bash
ssh tony@stapp01
```

### Step 2: Create User
```bash
sudo useradd -s /sbin/nologin jim
```

### Step 3: Verify
```bash
sudo useradd -s /sbin/nologin jim
```
#### Expected output:
```bash
jim:x:...:/home/jim:/sbin/nologin
```

## ⚙️ Result

- User jim created
- Non-interactive shell assigned
- Login disabled


