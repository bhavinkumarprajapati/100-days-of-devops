# 📅 Day 03 – Disable Direct Root SSH Login

## 🎯 Task

Disable direct SSH root login on **all app servers** in the Stratos Datacenter:

* `stapp01`
* `stapp02`
* `stapp03`

---

## 🧠 Understanding the Task

Allowing direct root login via SSH is a security risk because:

* It exposes the most privileged account
* Makes brute-force attacks more dangerous
* Reduces accountability (no user traceability)

Best practice:

* Disable root SSH login
* Use normal users + `sudo`

---

## ⚙️ Solution

Perform the following steps on **each app server**.

---

### Step 1: Connect to Server

Example (repeat for all servers):

```bash
ssh tony@stapp01
```

---

### Step 2: Edit SSH Configuration

```bash
sudo vi /etc/ssh/sshd_config
```

Find the following line:

```
PermitRootLogin yes
```

Change it to:

```
PermitRootLogin no
```

> If the line is commented (`#PermitRootLogin yes`), uncomment and set to `no`.

---

### Step 3: Restart SSH Service

```
sudo systemctl restart sshd
```

---

### Step 4: Repeat for Other Servers

```bash
ssh steve@stapp02
ssh banner@stapp03
```

Repeat the same steps.

---

## ✅ Verification

On each server:

```bash
grep PermitRootLogin /etc/ssh/sshd_config
```

Expected:

```
PermitRootLogin no
```

---

## 🏁 Result

* Root SSH login disabled on all app servers
* Improved system security
* Enforced least-privilege access

---
