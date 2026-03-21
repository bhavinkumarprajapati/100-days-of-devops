# 📅 Day 14 – Fix Apache Service Unavailable on App Server (Port Conflict + Multi-Host)

## 🎯 Task
Monitoring tools reported **Apache service unavailability** on one of the app servers in **Stratos DC**.

Goal:
* Identify which app host has the faulty Apache service
* Fix the root cause without modifying application files
* Ensure Apache is **up and running on all app servers**
* Ensure Apache is listening on **port 8082** on all app servers

---

## 🧠 Understanding the Problem

A running system can still have services failing silently due to:

* Port conflicts with other services
* Service not enabled (won't survive reboot)
* Another process already occupying the required port

In this case, the issue was a **port conflict** — `sendmail` had claimed port `8082` before Apache could bind to it.

---

## 🔎 Step-by-Step Debugging Approach

### 1️⃣ SSH Into App Server 1

```bash
ssh tony@stapp01
```

---

### 2️⃣ Check Apache Service Status

```bash
systemctl status httpd
```

Found:

```
failed (Result: exit-code)
(98)Address already in use: AH00072: make_sock: could not bind to address
no listening sockets available, shutting down
```

👉 Apache could not start because **port 8082 was already occupied**.

---

### 3️⃣ Identify Which Process Owns the Port

```bash
sudo ss -tulnp
```

Output:

```
tcp  LISTEN  127.0.0.1:8082   users:(("sendmail", pid=21173, fd=4))
```

👉 `sendmail` was bound to port `8082` — blocking Apache from starting.

> ⚠️ Note: sendmail was bound to `127.0.0.1` (loopback only), meaning it wasn't even serving external traffic — just sitting on the port and blocking Apache.

---

### 4️⃣ Stop and Disable the Conflicting Service

```bash
sudo systemctl stop sendmail
sudo systemctl disable sendmail
```

Verify the port is now free:

```bash
sudo ss -tulnp | grep 8082
```

Output: *(empty — port is free)* ✅

---

### 5️⃣ Start and Enable Apache

```bash
sudo systemctl start httpd
sudo systemctl enable httpd
```

> `enable` is critical — without it, Apache won't auto-start after a reboot.

---

### 6️⃣ Verify Apache is Running on Port 8082

```bash
systemctl status httpd
```

Output:

```
Active: active (running)
Status: "Started, listening on: port 8082"
```

✅ Apache is up and serving on port 8082.

---

### 7️⃣ Repeat for stapp02 and stapp03

The task requires **all app servers** to be fixed. SSH into each remaining host and run the same checks:

```bash
ssh steve@stapp02
ssh banner@stapp03
```

On each host:

```bash
systemctl status httpd
sudo ss -tulnp | grep 8082
sudo systemctl stop <conflicting-service>
sudo systemctl disable <conflicting-service>
sudo systemctl start httpd
sudo systemctl enable httpd
```

---

## 🏁 Final Result

| Host    | Apache Running | Port 8082 | Enabled on Boot |
| ------- | -------------- | --------- | --------------- |
| stapp01 | ✅              | ✅         | ✅               |
| stapp02 | ✅              | ✅         | ✅               |
| stapp03 | ✅              | ✅         | ✅               |

---

# 🧠 Key Concepts Learned

---

## 🔥 Golden Debug Flow

```text
1. Is the service running?
2. Is there a port conflict?
3. Which process owns the port?
4. Stop the conflicting process
5. Start and ENABLE the target service
6. Verify on ALL hosts (not just one)
```

---

## 🔍 Layer-wise Breakdown

### 🟢 1. Service Layer

Check if Apache is running:

```bash
systemctl status httpd
```

Key failure messages to look for:

| Message                        | Meaning                         |
| ------------------------------ | ------------------------------- |
| `Address already in use`       | Port conflict with another process |
| `no listening sockets available` | Apache gave up trying to bind  |
| `Unable to open logs`          | Startup aborted entirely        |

---

### 🟡 2. Port Conflict Layer

Find who is using the port:

```bash
sudo ss -tulnp | grep <port>
```

| Column        | Meaning                        |
| ------------- | ------------------------------ |
| `Netid`       | Protocol (tcp/udp)             |
| `Local Address:Port` | IP and port being used  |
| `Process`     | Name and PID of the owner      |

---

### 🔵 3. Binding Layer

Where a service is bound matters:

| Binding       | Meaning                          |
| ------------- | -------------------------------- |
| `127.0.0.1`   | Loopback only — local access ❌  |
| `0.0.0.0` / `*` | All interfaces — external access ✅ |

> In this task, sendmail was bound to `127.0.0.1:8082` — not actually doing anything useful externally, yet still blocking Apache.

---

### 🔴 4. Service Persistence Layer

Starting a service is not enough on its own:

| Command                        | Effect                          |
| ------------------------------ | ------------------------------- |
| `systemctl start httpd`        | Starts now, stops on reboot     |
| `systemctl enable httpd`       | Auto-starts on every reboot     |
| `systemctl enable --now httpd` | Both at once (shortcut)         |

---

## 💡 Key Takeaways

* **Port conflicts** are a common reason services fail silently — always check `ss -tulnp`
* A service occupying a port on `127.0.0.1` still blocks others from binding to it
* Always `enable` a service after starting it — otherwise a reboot wipes your fix
* In multi-host environments, **always verify every host**, not just the one that triggered the alert
* The monitoring alert pointed to one server, but the fix needs to be consistent across the entire fleet
