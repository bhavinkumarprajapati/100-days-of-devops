# 📅 Day 08 – Install Ansible Using pip3

## 🎯 Task

Install **Ansible version 4.8.0** on the **Jump Host** using **pip3 only**.

Requirements:

* Install **Ansible 4.8.0**
* Use **pip3** (not yum/apt)
* Ensure the **ansible binary is globally available**, so all users can run Ansible commands.

---

## 🧠 Understanding the Task

Ansible is an **agentless configuration management tool** widely used in DevOps for:

* Server provisioning
* Configuration management
* Application deployment
* Automation

Since the team wants to test automation, the **jump host will act as the Ansible controller**.

Installing via **pip3** ensures we can install a **specific version** easily.

---

## ⚙️ Solution

### Step 1: Connect to Jump Host

```bash
ssh thor@jump_host
```

---

### Step 2: Install Ansible with pip3

Install the required version globally:

```bash
sudo pip3 install ansible==4.8.0
```

---

### Step 3: Verify Installation

```bash
ansible --version
```

Expected output should include:

```
ansible [core 2.11.x]
ansible 4.8.0
```

---

## ✅ Verification

Check Ansible binary location:

```bash
which ansible
```

Example output:

```
/usr/local/bin/ansible
```

Since `/usr/local/bin` is part of the global PATH, all users can run Ansible.

---

## ❗ Common Mistakes

* Installing Ansible using `yum` instead of **pip3**
* Installing without `sudo` (not globally accessible)
* Installing incorrect version
* Not verifying installation

---

## 🏁 Result

* Ansible **4.8.0** installed using **pip3**
* Installed globally
* Jump host ready to act as **Ansible controller**

---

## 💡 Real-World Relevance

Ansible is commonly used for:

* Infrastructure automation
* Configuration management
* Kubernetes cluster setup
* CI/CD pipelines

---
👉 https://engineer.kodekloud.com/practice

Thanks to KodeKloud for providing real-world DevOps practice environments.
