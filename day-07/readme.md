# 📅 Day 07 – Configure Passwordless SSH from Jump Host

## 🎯 Task

Configure **passwordless SSH authentication** from user `thor` on **jump host** to all app servers using their respective sudo users.

Targets:

* `stapp01` → user `tony`
* `stapp02` → user `steve`
* `stapp03` → user `banner`

After configuration, `thor` should be able to SSH into all app servers **without entering a password**.

---

## 🧠 Understanding the Task

Passwordless SSH authentication works using **SSH key pairs**:

* **Private key** → stays on the client (jump host)
* **Public key** → copied to the remote server

When connecting, the server verifies the key instead of asking for a password.

This method is widely used for:

* Automation scripts
* Ansible
* CI/CD pipelines
* Remote operations

---

## ⚙️ Solution

### Step 1: Login to Jump Host

```bash
ssh thor@jump_host
```

---

### Step 2: Generate SSH Key (if not already present)

```bash
ssh-keygen -t rsa
```

Press **Enter** for all prompts.

This creates:

```
~/.ssh/id_rsa
~/.ssh/id_rsa.pub
```

---

### Step 3: Copy Key to App Server 1

```bash
ssh-copy-id tony@stapp01
```

Enter password when prompted.

---

### Step 4: Copy Key to App Server 2

```bash
ssh-copy-id steve@stapp02
```

---

### Step 5: Copy Key to App Server 3

```bash
ssh-copy-id banner@stapp03
```

---

## ✅ Verification

Test passwordless login:

```bash
ssh tony@stapp01
ssh steve@stapp02
ssh banner@stapp03
```

If configured correctly:

* SSH login will **not ask for a password**.

---

## ❗ Common Mistakes

* Generating SSH key as the wrong user (must be `thor`)
* Copying key to wrong user
* Forgetting to verify login
* Running commands on wrong host

---

## 🏁 Result

* SSH key pair created for `thor`
* Public key deployed to all app servers
* Passwordless SSH authentication enabled

---

## 💡 Real-World Relevance

Passwordless SSH is essential for:

* Infrastructure automation
* Deployment pipelines
* Configuration management tools (Ansible, Puppet, Chef)
* Scheduled remote scripts

---
