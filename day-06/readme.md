# 📅 Day 06 – Setup Cron Job on App Servers

## 🎯 Task

On **all App Servers (stapp01, stapp02, stapp03)**:

1. Install the **cronie** package
2. Start the **crond** service
3. Add a cron job for **root user**:

```bash
*/5 * * * * echo hello > /tmp/cron_text
```

---

## 🧠 Understanding the Task

* **Cron** is used to schedule recurring tasks in Linux
* `cronie` → package that provides cron service
* `crond` → daemon that runs scheduled jobs

Cron format:

```
* * * * *  command
│ │ │ │ │
│ │ │ │ └── Day of week
│ │ │ └──── Month
│ │ └────── Day of month
│ └──────── Hour
└────────── Minute
```

`*/5` → runs every 5 minutes

---

## ⚙️ Solution

Perform the following steps on **each app server**

---

### Step 1: Connect to Server

```bash
ssh tony@stapp01
```

Repeat for:

```bash
ssh steve@stapp02
ssh banner@stapp03
```

---

### Step 2: Install cronie

```bash
sudo yum install -y cronie
```

---

### Step 3: Start and Enable Service

```bash
sudo systemctl start crond
sudo systemctl enable crond
```

---

### Step 4: Add Cron Job for Root

```bash
sudo crontab -e
```

Add:

```bash
*/5 * * * * echo hello > /tmp/cron_text
```

Save and exit.

---

## ✅ Verification

### Check cron entry:

```bash
sudo crontab -l
```

---

### Check service:

```bash
systemctl status crond
```

---

### Check output after 5 minutes:

```bash
cat /tmp/cron_text
```

Expected:

```
hello
```

---

## ❗ Common Mistakes

* Adding cron for normal user instead of **root**
* Forgetting to start `crond` service
* Running on only one server instead of all three
* Typo in cron syntax

---

## 🏁 Result

* `cronie` installed on all app servers
* `crond` service running
* Cron job executes every 5 minutes
* Output written to `/tmp/cron_text`

---

## 💡 Real-World Relevance

Cron jobs are widely used for:

* Backups
* Log rotation
* Monitoring scripts
* Automation tasks

---
