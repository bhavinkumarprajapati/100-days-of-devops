# 📅 Day 12 – Debug Apache Service Not Reachable (Networking + Firewall)

## 🎯 Task

Apache service on **App Server 1 (`stapp01`)** was not reachable on **port 5003** from the jump host.

Goal:

* Identify the root cause using tools like `curl`, `ss`, `netstat`
* Fix the issue without modifying application files
* Ensure service is reachable from jump host

---

## 🧠 Understanding the Problem

Even if a service is running, it may still be **unreachable** due to:

* Service failure
* Port conflicts
* Incorrect binding
* Firewall restrictions

In this case, the issue was **not a single problem**, but a chain of issues.

---

## 🔎 Step-by-Step Debugging Approach

### 1️⃣ Test from Jump Host

```bash
curl http://stapp01:5003
```

Error:

```
No route to host
```

👉 Indicates **network/firewall issue**, not application issue.

---

### 2️⃣ Check Apache Service

```bash
systemctl status httpd
```

Found:

```
failed (Address already in use)
```

👉 Apache could not start.

---

### 3️⃣ Identify Port Conflict

```bash
sudo ss -tulnp | grep 5003
```

Output:

```
sendmail using port 5003
```

---

### 4️⃣ Resolve Conflict

```bash
sudo systemctl stop sendmail
sudo systemctl disable sendmail
```

---

### 5️⃣ Start Apache

```bash
sudo systemctl start httpd
sudo systemctl enable httpd
```

---

### 6️⃣ Verify Port Binding

```bash
sudo ss -tulnp | grep 5003
```

Output:

```
*:5003
```

👉 Apache is listening on all interfaces (correct).

---

### 7️⃣ Test Locally

```bash
curl http://localhost:5003
```

👉 Works ✅

---

### 8️⃣ Check Firewall (iptables)

```bash
sudo iptables -L -n
```

Found:

```
REJECT all ... reject-with icmp-host-prohibited
```

👉 Port 5003 not allowed → blocked externally ❌

---

### 9️⃣ Allow Port 5003

```bash
sudo iptables -I INPUT 1 -p tcp --dport 5003 -j ACCEPT
```

---

### 🔟 Test from Jump Host

```bash
curl http://stapp01:5003
```

👉 Works ✅

---

## 🏁 Final Result

* Apache running successfully
* Port 5003 accessible
* Firewall correctly configured
* Application reachable from jump host

---

# 🧠 Networking Debugging – Systematic Approach

This is the **most important learning** from this task.

---

## 🔥 Golden Debug Flow

```text
1. Is service running?
2. Is port listening?
3. Is it bound correctly?
4. Is firewall blocking?
5. Is network reachable?
```

---

## 🔍 Layer-wise Breakdown

### 🟢 1. Service Layer

Check if service is running:

```bash
systemctl status httpd
```

If not → fix service first.

---

### 🟡 2. Port Layer

Check if port is listening:

```bash
ss -tulnp | grep <port>
```

If not → service misconfigured.

---

### 🔵 3. Binding Layer

Check binding:

| Binding     | Meaning          |
| ----------- | ---------------- |
| 127.0.0.1   | local only ❌     |
| 0.0.0.0 / * | all interfaces ✅ |

---

### 🔴 4. Firewall Layer

Check rules:

```bash
iptables -L -n
```

Key rule types:

* ACCEPT → allowed
* REJECT → blocked with error
* DROP → silently blocked

---

### 🟣 5. Network Layer

Test from remote:

```bash
curl http://server:port
```

---

## 🧠 Error Meaning Cheat Sheet

| Error              | Meaning             |
| ------------------ | ------------------- |
| Connection refused | service not running |
| No route to host   | firewall blocking   |
| Timeout            | network drop        |

---

## 💡 Key Concepts Learned

* Port conflicts (`Address already in use`)
* Service vs Network issues
* iptables rule order (top → down)
* Difference between local and remote access
* Systematic debugging approach

---

