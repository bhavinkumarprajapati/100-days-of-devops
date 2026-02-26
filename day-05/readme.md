# 📅 Day 05 – Install and Disable SELinux

## 🎯 Task

On **App Server 2**, perform the following:

* Install required **SELinux packages**
* **Permanently disable SELinux**
* No reboot required now (changes should apply after scheduled reboot)

---

## 🧠 Understanding the Task

SELinux (Security-Enhanced Linux) is a security module that enforces access control policies.

Modes:

* `enforcing` → actively enforces policies
* `permissive` → logs violations but allows actions
* `disabled` → completely turned off

In this task:

* We install SELinux tools
* Then **disable it permanently** via configuration

---

## ⚙️ Solution

### Step 1: Connect to App Server 2

```bash
ssh steve@stapp02
```

---

### Step 2: Install SELinux Packages

For RHEL/CentOS-based systems:

```bash
sudo yum install -y selinux-policy selinux-policy-targeted policycoreutils
```

---

### Step 3: Disable SELinux Permanently

Edit the config file:

```bash
sudo vi /etc/selinux/config
```

Find:

```
SELINUX=enforcing
```

Change to:

```
SELINUX=disabled
```

---

### Step 4: Verify Configuration

```bash
cat /etc/selinux/config | grep SELINUX
```

Expected:

```
SELINUX=disabled
```

---

## ❗ Important Notes

* No reboot required now (as per task)
* Changes will take effect **after next reboot**
* Current runtime status may still show:

  ```bash
  getenforce
  ```

  → Ignore this (as instructed)

---

## ❗ Common Mistakes

* Forgetting to install SELinux packages
* Setting `permissive` instead of `disabled`
* Checking runtime status instead of config file
* Editing wrong file

---

## 🏁 Result

* SELinux packages installed
* SELinux permanently set to **disabled**
* Configuration ready for next reboot

---

## 💡 Real-World Relevance

This is useful when:

* Testing applications incompatible with SELinux
* Debugging permission-related issues
* Gradually introducing security policies

---
