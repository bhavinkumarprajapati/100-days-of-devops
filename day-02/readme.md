# 📅 Day 02 – Create User with Expiry Date

## 🎯 Task

Create a user named `ammar` on **App Server 1** with an **expiry date of 2027-03-28**.

---

## 🧠 Understanding the Task

Temporary users are often required in real-world systems (e.g., contractors or short-term developers).
Linux allows setting an **account expiry date**, after which the user will no longer be able to log in.

---

## ⚙️ Solution

### Step 1: Connect to App Server 1

```bash
ssh tony@stapp01
```

---

### Step 2: Create User with Expiry Date

```bash
sudo useradd -e 2027-03-28 ammar
```

---

### Step 3: Verify

```bash
sudo chage -l ammar
```

Expected output should include:

```
Account expires : Mar 28, 2027
```
---

## 🏁 Result

* User `ammar` created successfully
* Expiry date set to **2027-03-28**
* Access automatically expires after the set date

---

