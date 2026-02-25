# 📅 Day 04 – Grant Executable Permissions to Script

## 🎯 Task

Grant executable permissions to the script `/tmp/xfusioncorp.sh` on **App Server 2**.
Ensure that **all users** have permission to execute the script.

---

## 🧠 Understanding the Task

In Linux, scripts must have **execute permission** to run.

Permission types:

* `r` → read
* `w` → write
* `x` → execute

To allow **all users to execute**, we typically assign:

```
755 → rwxr-xr-x
```

---

## ⚙️ Solution

### Step 1: Connect to App Server 2

```bash
ssh steve@stapp02
```

---

### Step 2: Navigate to Script Location

```bash
cd /tmp
```

---

### Step 3: Grant Executable Permissions

```bash
sudo chmod 755 xfusioncorp.sh
```

---

### Step 4: Verify Permissions

```bash
ls -l /tmp/xfusioncorp.sh
```

Expected output:

```
-rwxr-xr-x
```

---

## ❗ Common Mistakes

* Using `chmod +x` only → may result in missing read permissions
* Not using `sudo` (file is owned by root)
* Running command on wrong server
* Forgetting to verify permissions

---

## 🏁 Result

* Script is executable
* All users can execute it
* Proper permissions (`755`) applied
---
