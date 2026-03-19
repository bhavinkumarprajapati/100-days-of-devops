# 🌐 Networking & Service Debugging – Concepts & Reference

> Companion doc to **Day 12 – Debug Apache Service Not Reachable**
> Covers the underlying theory and a repeatable debug playbook for any port/service problem.

---

## 📖 Table of Contents

1. [How Network Communication Works](#how-network-communication-works)
2. [What Is a Port?](#what-is-a-port)
3. [TCP Connection Lifecycle](#tcp-connection-lifecycle)
4. [The 5 Layers That Can Break](#the-5-layers-that-can-break)
5. [Firewall Fundamentals (iptables)](#firewall-fundamentals-iptables)
6. [Command Reference](#command-reference)
   - [ss](#ss--socket-statistics)
   - [netstat](#netstat--network-statistics)
   - [ss vs netstat](#ss-vs-netstat)
   - [curl](#curl)
   - [nc / telnet](#nc--telnet)
   - [iptables](#iptables)
7. [Full Debug Playbook](#full-debug-playbook)
8. [Error Meaning Cheat Sheet](#error-meaning-cheat-sheet)

---

## How Network Communication Works

When a client (e.g., your jump host) sends a request to a server (e.g., `stapp01:5003`), the traffic passes through multiple layers:

```
Jump Host
   │
   │  TCP SYN packet → stapp01:5003
   ▼
Network (routers, switches)
   │
   ▼
stapp01 NIC (Network Interface Card)
   │
   ▼
OS Kernel → iptables/firewall rules
   │
   ▼
Socket (IP:Port bound by a process)
   │
   ▼
Application (httpd, nginx, etc.)
```

If **any layer** breaks, the connection fails — each with a different error message.

---

## What Is a Port?

A **port** is a logical endpoint attached to an IP address.  
Format: `IP:PORT` → e.g., `0.0.0.0:5003`

| Range         | Type              | Examples                      |
|---------------|-------------------|-------------------------------|
| 0 – 1023      | Well-known ports  | 80 (HTTP), 443 (HTTPS), 22 (SSH) |
| 1024 – 49151  | Registered ports  | 8080, 3306 (MySQL), 5432 (PG)  |
| 49152 – 65535 | Ephemeral/dynamic | Used by OS for client sockets  |

A process must **bind** to a port to accept connections.  
Only **one process** can bind to a given IP:PORT at a time → any conflict causes `Address already in use`.

### Binding Address Matters

| Bound to      | Accessible from       |
|---------------|-----------------------|
| `127.0.0.1`   | Localhost only ❌      |
| `0.0.0.0`     | All IPv4 interfaces ✅ |
| `::`          | All IPv6 interfaces ✅ |
| `*`           | All interfaces ✅      |

> Even if Apache is running and listening, if it binds to `127.0.0.1` only, remote hosts cannot reach it.

---

## TCP Connection Lifecycle

Understanding TCP states helps you interpret `ss`/`netstat` output.

```
Client                          Server
  │                               │
  │──── SYN ──────────────────►  │  SYN_SENT / SYN_RECEIVED
  │◄─── SYN-ACK ────────────────  │
  │──── ACK ──────────────────►  │  ESTABLISHED (both sides)
  │                               │
  │  (data exchange)              │  Server: LISTEN → ESTABLISHED
  │                               │
  │──── FIN ──────────────────►  │  FIN_WAIT1
  │◄─── ACK ────────────────────  │  CLOSE_WAIT
  │◄─── FIN ────────────────────  │
  │──── ACK ──────────────────►  │  TIME_WAIT (client waits ~2 min)
  │                               │  CLOSED
```

### TCP Socket States

| State         | Meaning                                                  |
|---------------|----------------------------------------------------------|
| `LISTEN`      | Port is open, waiting for incoming connections           |
| `ESTABLISHED` | Active two-way connection                                |
| `TIME_WAIT`   | Connection closed; OS holding port briefly               |
| `CLOSE_WAIT`  | Remote closed connection; local app hasn't closed yet    |
| `SYN_SENT`    | Client sent SYN, waiting for server SYN-ACK              |
| `FIN_WAIT1/2` | Local side initiated connection close                    |
| `CLOSED`      | No connection                                            |

---

## The 5 Layers That Can Break

Every service reachability problem maps to one (or more) of these:

```
┌──────────────────────────────────────────────┐
│  5. Network Layer      ping / traceroute      │
│     Is the host reachable at all?             │
├──────────────────────────────────────────────┤
│  4. Firewall Layer     iptables / firewalld   │
│     Is the port allowed through?              │
├──────────────────────────────────────────────┤
│  3. Binding Layer      ss / netstat           │
│     Is the process listening on 0.0.0.0?      │
├──────────────────────────────────────────────┤
│  2. Port Layer         ss / netstat / fuser   │
│     Is anything listening on the port?        │
├──────────────────────────────────────────────┤
│  1. Service Layer      systemctl              │
│     Is the service process running?           │
└──────────────────────────────────────────────┘
```

> **Always debug bottom-up.** No point checking firewall if the service isn't even running.

### Layer-by-Layer: What to Check

#### Layer 1 – Service

```bash
systemctl status httpd
journalctl -u httpd -n 50     # last 50 log lines
```

Red flags:
- `Active: failed` → crashed
- `Address already in use` → port conflict (jump to Layer 2)
- `Permission denied` → user/SELinux issue

---

#### Layer 2 – Port

```bash
sudo ss -tulnp | grep <port>
sudo netstat -tulnp | grep <port>
sudo fuser <port>/tcp          # who owns the port
```

Red flags:
- Nothing listening → service not started or wrong port config
- Different process listed → port conflict

---

#### Layer 3 – Binding

```bash
sudo ss -tulnp | grep <port>
# Look at the "Local Address" column
```

Red flags:
- `127.0.0.1:<port>` → service only accepts local connections, must reconfigure app

---

#### Layer 4 – Firewall

```bash
sudo iptables -L INPUT -n --line-numbers
sudo firewall-cmd --list-all        # if using firewalld
```

Red flags:
- `REJECT all` or `DROP all` rule present with no ACCEPT for your port
- Your ACCEPT rule comes **after** a REJECT rule (rules are top-down)

---

#### Layer 5 – Network

```bash
ping stapp01
traceroute stapp01
```

Red flags:
- `ping` fails → host unreachable, routing issue, or ICMP blocked
- `traceroute` shows drops at a specific hop → router/firewall between hosts

---

## Firewall Fundamentals (iptables)

`iptables` filters packets using **chains** of rules, evaluated **top to bottom**.  
First matching rule wins.

### Chains

| Chain     | When it applies                                 |
|-----------|-------------------------------------------------|
| `INPUT`   | Packets destined for this machine               |
| `OUTPUT`  | Packets originating from this machine           |
| `FORWARD` | Packets passing through (routing/NAT)           |

### Rule Targets

| Target    | Meaning                                              |
|-----------|------------------------------------------------------|
| `ACCEPT`  | Allow the packet through                             |
| `REJECT`  | Block and send error back to sender                  |
| `DROP`    | Block silently (sender gets no response → timeout)   |
| `LOG`     | Log the packet and continue to next rule             |

### Why Rule Order Matters

```
INPUT Chain (evaluated top → bottom, first match wins):

  Line 1:  ACCEPT  tcp  dport 5003    ← ✅ port 5003 hits this, allowed
  Line 2:  REJECT  all               ← everything else hits this
```

If you append your ACCEPT rule **after** a REJECT, it is never reached:

```
  Line 1:  REJECT  all               ← ❌ port 5003 hits this first, blocked
  Line 2:  ACCEPT  tcp  dport 5003    ← never evaluated
```

Always **insert** (`-I`) at the top rather than **append** (`-A`) at the bottom.

### Common iptables Commands

```bash
# List INPUT chain with line numbers
sudo iptables -L INPUT -n --line-numbers

# Insert ACCEPT rule at position 1 (top)
sudo iptables -I INPUT 1 -p tcp --dport 5003 -j ACCEPT

# Append rule at bottom (careful with order!)
sudo iptables -A INPUT -p tcp --dport 5003 -j ACCEPT

# Delete rule by line number
sudo iptables -D INPUT 3

# Flush all INPUT rules (⚠️ removes everything)
sudo iptables -F INPUT

# Save rules persistently (RHEL/CentOS)
sudo service iptables save

# Save rules persistently (Debian/Ubuntu)
sudo iptables-save > /etc/iptables/rules.v4
```

---

## Command Reference

---

### `ss` – Socket Statistics

Modern replacement for `netstat`. Uses Netlink socket directly → faster.

```bash
ss [options]
```

#### Flags

| Flag | Meaning                          |
|------|----------------------------------|
| `-t` | TCP sockets                      |
| `-u` | UDP sockets                      |
| `-l` | Listening only                   |
| `-n` | Numeric (no DNS/service resolve) |
| `-p` | Show owning process              |
| `-4` | IPv4 only                        |
| `-6` | IPv6 only                        |
| `-s` | Summary statistics               |

#### Common Commands

```bash
# Show all listening TCP+UDP with process
ss -tulnp

# Filter by port
ss -tulnp | grep 5003

# Show only established connections
ss -tn state established

# Count established connections
ss -tn state established | wc -l

# Show socket summary
ss -s
```

#### Reading `ss` Output

```
Netid  State   Recv-Q  Send-Q  Local Address:Port   Peer Address:Port  Process
tcp    LISTEN  0       128     0.0.0.0:5003          0.0.0.0:*          users:(("httpd",pid=1234,fd=4))
tcp    ESTAB   0       0       192.168.1.2:5003      10.0.0.5:43210     users:(("httpd",pid=1234,fd=8))
```

| Column            | Meaning                                      |
|-------------------|----------------------------------------------|
| `Netid`           | Protocol (tcp/udp/unix)                      |
| `State`           | LISTEN / ESTAB / TIME-WAIT etc.              |
| `Recv-Q`          | Bytes received, not yet read by app          |
| `Send-Q`          | Bytes sent, not yet acknowledged             |
| `Local Address`   | IP:Port the process is bound to              |
| `Peer Address`    | Remote IP:Port (`0.0.0.0:*` = any)           |
| `Process`         | Process name, PID, file descriptor           |

---

### `netstat` – Network Statistics

Classic tool. Reads from `/proc/net`. Requires `net-tools` package on modern systems.

```bash
# Install
sudo yum install net-tools      # RHEL/CentOS/Rocky
sudo apt install net-tools      # Debian/Ubuntu
```

```bash
netstat [options]
```

#### Flags

| Flag | Meaning                                 |
|------|-----------------------------------------|
| `-t` | TCP connections                         |
| `-u` | UDP connections                         |
| `-l` | Listening ports only                    |
| `-n` | Numeric output (no DNS resolution)      |
| `-p` | Show PID/program name                   |
| `-r` | Routing table                           |
| `-s` | Per-protocol statistics                 |
| `-a` | All sockets (listening + connected)     |
| `-c` | Continuous refresh                      |

#### Common Commands

```bash
# Show all listening ports with process
netstat -tulnp

# Filter by port
netstat -tulnp | grep 5003

# Show routing table
netstat -rn

# Show established connections only
netstat -tn | grep ESTABLISHED

# Count established connections
netstat -tn | grep ESTABLISHED | wc -l

# Per-protocol stats (packets, errors, resets)
netstat -s

# Watch connections live (refresh every 1s)
netstat -c
```

#### Reading `netstat` Output

```
Proto  Recv-Q  Send-Q  Local Address     Foreign Address    State        PID/Program
tcp    0       0       0.0.0.0:5003      0.0.0.0:*          LISTEN       1234/httpd
tcp    0       0       192.168.1.2:5003  10.0.0.5:43210     ESTABLISHED  1234/httpd
udp    0       0       0.0.0.0:68        0.0.0.0:*                       987/dhclient
```

| Column            | Meaning                                         |
|-------------------|-------------------------------------------------|
| `Proto`           | Protocol (tcp/udp)                              |
| `Recv-Q`          | Data received, not yet consumed by app          |
| `Send-Q`          | Data sent, not yet acknowledged by remote       |
| `Local Address`   | Local IP:Port                                   |
| `Foreign Address` | Remote IP:Port                                  |
| `State`           | Socket state                                    |
| `PID/Program`     | Process ID and name (`sudo` needed to see this) |

---

### `ss` vs `netstat`

| Feature              | `ss`                        | `netstat`                     |
|----------------------|-----------------------------|-------------------------------|
| Data source          | Netlink socket (kernel)     | `/proc/net` (virtual fs)      |
| Speed                | ✅ Fast                     | ❌ Slow on busy systems        |
| Package              | Built-in (`iproute2`)       | Requires `net-tools`          |
| Basic flags          | `-tulnp` works              | `-tulnp` works                |
| Extended filter      | ✅ `state`, `dport`, etc.   | Limited                       |
| Recommended          | ✅ Default choice           | Fallback for older systems     |

> Same `-tulnp` flags work on both. Default to `ss`; use `netstat` on older/legacy hosts.

---

### `curl`

Tests HTTP/HTTPS connectivity end-to-end.

```bash
# Basic request
curl http://stapp01:5003

# Show response headers only
curl -I http://stapp01:5003

# Full verbose output (headers + TLS handshake)
curl -v http://stapp01:5003

# Set connect timeout (don't hang forever)
curl --connect-timeout 5 http://stapp01:5003

# Follow HTTP redirects
curl -L http://stapp01:5003

# POST request with JSON body
curl -X POST http://stapp01:5003/api \
     -H "Content-Type: application/json" \
     -d '{"key":"value"}'
```

---

### `nc` / `telnet`

Test raw TCP connectivity without HTTP overhead.

```bash
# nc: test if port is open (zero I/O mode)
nc -zv stapp01 5003

# nc: scan a port range
nc -zv stapp01 5000-5010

# telnet: interactive TCP test
telnet stapp01 5003
```

| Result             | Meaning                               |
|--------------------|---------------------------------------|
| `Connection succeeded` | Port open, service listening      |
| `Connection refused`   | Port closed or service not running|
| Hangs / times out  | Firewall DROP rule blocking           |

---

## Full Debug Playbook

Use this checklist for **any** service reachability problem.

```
Problem: curl http://<host>:<port> fails
```

### Step 1 – Is the service running?

```bash
systemctl status <service>
journalctl -u <service> -n 50
```

- ✅ Active: running → go to Step 2
- ❌ Failed / inactive → check logs, fix service, restart

---

### Step 2 – Is the port listening?

```bash
sudo ss -tulnp | grep <port>
sudo netstat -tulnp | grep <port>
```

- ✅ Shows process on port → go to Step 3
- ❌ Nothing listening → service not started or wrong port in config
- ⚠️ Different process → port conflict → stop the other process first

---

### Step 3 – What process owns the port?

```bash
sudo fuser <port>/tcp
sudo ss -tulnp | grep <port>   # check the Process column
```

If it's not your service → kill or disable the conflicting process:

```bash
sudo systemctl stop <conflicting-service>
sudo systemctl disable <conflicting-service>
```

---

### Step 4 – Is binding correct?

```bash
sudo ss -tulnp | grep <port>
# Check Local Address column
```

- ✅ `0.0.0.0:<port>` or `*:<port>` → accessible externally
- ❌ `127.0.0.1:<port>` → only local → must change app config (`Listen` directive in Apache, `bind` in others)

---

### Step 5 – Test locally on the server

```bash
curl http://localhost:<port>
curl http://127.0.0.1:<port>
```

- ✅ Works locally → go to Step 6 (network/firewall issue)
- ❌ Fails locally → application-level issue (config, app crash, binding)

---

### Step 6 – Check firewall rules

```bash
sudo iptables -L INPUT -n --line-numbers
```

Look for:
- Any `REJECT` or `DROP` rule before an `ACCEPT` for your port
- Missing ACCEPT rule for your port

Fix:
```bash
sudo iptables -I INPUT 1 -p tcp --dport <port> -j ACCEPT
```

---

### Step 7 – Test from remote host

```bash
# From jump host
curl http://stapp01:<port>

# TCP only (no HTTP)
nc -zv stapp01 <port>
telnet stapp01 <port>
```

- ✅ Works → done
- ❌ Still failing → check network routing, VPC/security groups (if cloud)

---

### Step 8 – Check routing / network path

```bash
ping stapp01
traceroute stapp01
```

- If `ping` fails → host unreachable (routing or host-level firewall)
- If `traceroute` drops at a hop → firewall between the two hosts

---

## Error Meaning Cheat Sheet

| Error / Symptom          | Root Cause                                               | Where to look       |
|--------------------------|----------------------------------------------------------|---------------------|
| `Connection refused`     | Nothing listening on port / service crashed              | Layer 1, 2          |
| `No route to host`       | Firewall REJECT rule or host unreachable                 | Layer 4, 5          |
| `Connection timed out`   | Firewall DROP rule (silent block) or network drop        | Layer 4, 5          |
| `Address already in use` | Another process bound to the port                        | Layer 2             |
| Works locally, not remote| Bound to `127.0.0.1` only, or firewall blocking external | Layer 3, 4          |
| Service starts then dies | App crash, config error, missing dependency              | Layer 1 (journalctl)|
| `curl` hangs forever     | DROP rule (no response sent back)                        | Layer 4             |

---

## Quick Reference Card

```bash
# Service
systemctl status <svc>
systemctl start/stop/restart/enable/disable <svc>
journalctl -u <svc> -n 50

# Port / Binding
ss -tulnp | grep <port>
netstat -tulnp | grep <port>
fuser <port>/tcp

# Firewall
iptables -L INPUT -n --line-numbers
iptables -I INPUT 1 -p tcp --dport <port> -j ACCEPT
iptables -D INPUT <line>

# Connectivity tests
curl http://<host>:<port>
curl -v http://<host>:<port>         # verbose
nc -zv <host> <port>                 # TCP only
telnet <host> <port>                 # interactive TCP
ping <host>
traceroute <host>
```