# 🔒 Day 13 – Secure Apache Port with iptables (Nautilus Stratos DC)

---

## 📅 Day 12 Context — Why This Matters

Before jumping into Day 13, it's important to understand what happened in **Day 12**, because both tasks are connected.

### 📋 Day 12 Task — Debug Apache Service Not Reachable

> Apache service on App Server 1 (`stapp01`) was not reachable on port `5003` from the jump host.
> Goal: Identify the root cause and fix it without modifying application files.

### 🔎 What Was Found (Chain of Issues)

Even if a service is running, it can still be unreachable. Day 12 taught that it's never just one problem — it's usually a **chain**.

**1. Test from jump host**
```bash
curl http://stapp01:5003
# Error: No route to host  → firewall/network issue, not app issue
```

**2. Check Apache service**
```bash
systemctl status httpd
# failed: Address already in use  → Apache couldn't even start
```

**3. Find the port conflict**
```bash
sudo ss -tulnp | grep 5003
# sendmail was occupying port 5003
```

**4. Kill the conflict**
```bash
sudo systemctl stop sendmail
sudo systemctl disable sendmail
```

**5. Start Apache**
```bash
sudo systemctl start httpd
sudo systemctl enable httpd
```

**6. Verify Apache is listening**
```bash
sudo ss -tulnp | grep 5003
# *:5003  → listening on all interfaces ✅
```

**7. Test locally**
```bash
curl http://localhost:5003   # ✅ Works
```

**8. But still blocked from outside — check firewall**
```bash
sudo iptables -L -n
# Found: REJECT all ... reject-with icmp-host-prohibited
# Port 5003 not explicitly allowed → blocked externally ❌
```

**9. Allow port 5003 temporarily**
```bash
sudo iptables -I INPUT 1 -p tcp --dport 5003 -j ACCEPT
```

**10. Test from jump host**
```bash
curl http://stapp01:5003   # ✅ Works
```

### 🏁 Day 12 Result
Apache was running, port 5003 accessible, reachable from jump host.

---

### 🧠 Networking Debugging — Golden Flow (Learned from Day 12)

This is the most important takeaway. Always debug layer by layer:

```
1. Is the service running?       → systemctl status <service>
2. Is the port listening?        → ss -tulnp | grep <port>
3. Is it bound correctly?        → 0.0.0.0 = all interfaces ✅ | 127.0.0.1 = local only ❌
4. Is the firewall blocking?     → iptables -L -n
5. Is it reachable from remote?  → curl http://server:port
```

**Error Meaning Cheat Sheet**

| Error | Meaning |
|---|---|
| `Connection refused` | Service not running |
| `No route to host` | Firewall blocking |
| `Timeout` | Network drop (silent block) |

**iptables Rule Types**

| Rule | Behaviour |
|---|---|
| `ACCEPT` | Traffic allowed through |
| `REJECT` | Blocked, sender gets an error back |
| `DROP` | Silently blocked, sender gets nothing |

> ⚠️ iptables reads rules **top to bottom** and stops at the first match. Order matters.

---
---

## 📋 Day 13 Task — Block Port 5003 for Everyone Except LBR

> We have one of our websites up and running on our Nautilus infrastructure in Stratos DC. Our security team has raised a concern that right now Apache's port i.e `5003` is open for all since there is no firewall installed on these hosts. So we have decided to add some security layer for these hosts and after discussions and recommendations we have come up with the following requirements:
>
> 1. Install `iptables` and all its dependencies on each app host.
> 2. Block incoming port `5003` on all apps for everyone **except** the LBR host.
> 3. Make sure the rules remain, even after system reboot.

---

## 🏗️ Infrastructure

| Host | Role | User |
|------|------|------|
| `stapp01` | App Server 1 | `tony` |
| `stapp02` | App Server 2 | `steve` |
| `stapp03` | App Server 3 | `banner` |
| `stlb01` | Load Balancer (LBR) | `loki` |

---

## 🗂️ Repository Structure

```
.
├── setup_iptables.sh   # Run this on each app server
└── README.md           # This file
```

---

## 🚀 How to Run

**Copy script to each app server:**
```bash
scp setup_iptables.sh tony@stapp01:~/
scp setup_iptables.sh steve@stapp02:~/
scp setup_iptables.sh banner@stapp03:~/
```

**Run it on each server:**
```bash
ssh tony@stapp01   "chmod +x setup_iptables.sh && bash setup_iptables.sh"
ssh steve@stapp02  "chmod +x setup_iptables.sh && bash setup_iptables.sh"
ssh banner@stapp03 "chmod +x setup_iptables.sh && bash setup_iptables.sh"
```

---

## 🔍 What the Script Does — Explained

### Step 1 — Install iptables
```bash
sudo yum install -y iptables iptables-services
```
- `iptables` — the actual firewall tool
- `iptables-services` — the package responsible for saving and restoring rules on reboot
- `-y` flag — auto-confirms so the script doesn't wait for user input

### Step 2 — Enable the service
```bash
sudo systemctl start iptables
sudo systemctl enable iptables
```
- `start` → runs it right now
- `enable` → makes it auto-start on every reboot

### Step 3 — Dynamically resolve LBR IP
```bash
LBR_IP=$(getent hosts stlb01 | awk '{print $1}')
```
- Uses `getent` to look up `stlb01` hostname instead of hardcoding an IP
- Means the script still works even if the LBR IP changes in the future
- Script aborts safely if `stlb01` can't be resolved

### Step 4 — Apply rules in the correct order
```bash
# Clean up any existing port 5003 rules first
sudo iptables -D INPUT -p tcp --dport 5003 -j DROP 2>/dev/null || true
sudo iptables -D INPUT -p tcp --dport 5003 -s "$LBR_IP" -j ACCEPT 2>/dev/null || true

# Add DROP first (goes to position 1)
sudo iptables -I INPUT -p tcp --dport 5003 -j DROP

# Add ACCEPT for LBR (pushes DROP to position 2, ACCEPT becomes position 1)
sudo iptables -I INPUT -p tcp --dport 5003 -s "$LBR_IP" -j ACCEPT
```

> 💡 **Why this order?**
> `-I` always inserts at position 1. So we insert DROP first, then insert ACCEPT — which pushes DROP down. Final result: ACCEPT is rule #1, DROP is rule #2. iptables hits ACCEPT for LBR first and stops. Everyone else falls through to DROP.

> 💡 **Why `2>/dev/null || true`?**
> The `-D` (delete) command errors if the rule doesn't exist yet. `2>/dev/null` hides the error, `|| true` prevents `set -e` from stopping the script. Clean slate every time.

### Step 5 — Save rules for persistence
```bash
sudo iptables-save | sudo tee /etc/sysconfig/iptables
```
- Writes current rules to `/etc/sysconfig/iptables`
- `iptables-services` automatically loads this file on every boot
- ⚠️ `service iptables save` is **not used** — it's unavailable on RHEL 9. This is the correct alternative.

---

## ✅ Expected Output After Running

```
Active rules for port 5003:
num  target  prot  source            destination
1    ACCEPT  tcp   10.x.x.x (LBR)   0.0.0.0/0    dpt:5003  ← LBR allowed ✅
2    DROP    tcp   0.0.0.0/0         0.0.0.0/0    dpt:5003  ← Everyone blocked ✅

Saved rules for port 5003:
-A INPUT -s 10.x.x.x/32 -p tcp -m tcp --dport 5003 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 5003 -j DROP
```

---

## 💾 How Persistence Works

```
script runs
    └─→ iptables-save writes to /etc/sysconfig/iptables
                                        │
                          on every boot │
                                        ▼
                          iptables-services reads the file
                          and restores all rules automatically
```

Verify saved rules anytime:
```bash
sudo cat /etc/sysconfig/iptables | grep 5003
```

---

## 📝 Key Concepts from Day 13

- **iptables rule order is critical** — ACCEPT for LBR must always be above the DROP rule
- **`-I` vs `-A`** — `-I` inserts at top, `-A` appends at bottom. Use `-I` when order matters
- **Idempotent script** — safe to run multiple times, always cleans up old rules first
- **Dynamic IP resolution** — never hardcode IPs in scripts if a hostname is available
- **Persistence on RHEL 9** — use `iptables-save > /etc/sysconfig/iptables`, not `service iptables save`
