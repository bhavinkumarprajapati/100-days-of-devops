# 📅 Day 16 – Configure Nginx as a Load Balancer on LBR Server

## 🎯 Task
Configure the **LBR (Load Balancer)** server (`stlb01`) using Nginx to distribute incoming HTTP traffic across all three **App Servers** (`stapp01`, `stapp02`, `stapp03`) in the Nautilus Stratos DC infrastructure.

**Goal:**
- Confirm Nginx is installed on `stlb01` (install if missing)
- Configure Nginx as a reverse proxy load balancer using the `http` context
- Edit **only** `/etc/nginx/nginx.conf` — no additional config files
- Keep Apache running untouched on all app servers
- Verify the website is reachable via `curl http://stlb01:80`

---

## 🧠 Understanding the Problem

As traffic to a website grows, a single server can no longer handle the load efficiently — response times increase and the service degrades. The solution is **horizontal scaling** with a **load balancer** sitting in front of multiple application servers.

In this task, Nginx on `stlb01` acts as the single entry point. It accepts all incoming requests on port `80` and forwards them in round-robin fashion to Apache-backed app servers running on port `3001`.

Key challenges:
- Running nginx/systemctl commands requires `sudo` as the `loki` user
- The `proxy_pass` directive must reference the upstream block by name
- Apache ports on app servers must **not** be changed — only referenced
- All config must live in the main `nginx.conf`, not in `conf.d/`

---

## 🔎 Step-by-Step Setup Approach

### 1️⃣ SSH into the LBR Server

```bash
ssh loki@stlb01
```

---

### 2️⃣ Check if Nginx is Installed

```bash
nginx -v
```

If not installed:

```bash
sudo yum install nginx -y
```

👉 In this task, Nginx was **already installed** but required `sudo` to run properly. Running it as a non-root user caused permission errors on `/var/log/nginx/` and `/run/nginx.pid`.

---

### 3️⃣ Verify Apache is Running on All App Servers

Before configuring the load balancer, confirm Apache is active and check its port on each app server:

```bash
ssh tony@stapp01   "sudo grep -i listen /etc/httpd/conf/httpd.conf && sudo systemctl status httpd --no-pager"
ssh steve@stapp02  "sudo grep -i listen /etc/httpd/conf/httpd.conf && sudo systemctl status httpd --no-pager"
ssh banner@stapp03 "sudo grep -i listen /etc/httpd/conf/httpd.conf && sudo systemctl status httpd --no-pager"
```

If Apache is stopped on any server, start it:

```bash
ssh tony@stapp01 "sudo systemctl start httpd && sudo systemctl enable httpd"
```

👉 In this task, Apache was listening on port **3001** on all three app servers.

---

### 4️⃣ Edit the Main Nginx Configuration

```bash
sudo vi /etc/nginx/nginx.conf
```

Add the `upstream` block inside the `http` context, and add `proxy_pass` inside the `location /` block of the `server` block:

```nginx
http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 4096;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    include /etc/nginx/conf.d/*.conf;

    # -----------------------------------------------
    # Upstream block — all three App Servers
    # Port must match Apache's existing Listen port
    # -----------------------------------------------
    upstream nautilus_app {
        server stapp01:3001;
        server stapp02:3001;
        server stapp03:3001;
    }

    server {
        listen       80;
        listen       [::]:80;
        server_name  stlb01;
        root         /usr/share/nginx/html;

        include /etc/nginx/default.d/*.conf;

        # ← THIS is the critical missing piece — proxy traffic to upstream
        location / {
            proxy_pass http://nautilus_app;
        }

        error_page 404 /404.html;
        location = /404.html {
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
        }
    }
}
```

👉 The `upstream` block defines the pool of backend servers. The `proxy_pass` directive inside `location /` is what actually enables proxying — without it, Nginx just serves its own default HTML page.

---

### 5️⃣ Test Configuration Syntax

```bash
sudo nginx -t
```

Expected output:
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

👉 Always run `nginx -t` before restarting — it catches typos and misconfigurations before they take the service down.

---

### 6️⃣ Start / Restart Nginx and Enable on Boot

```bash
sudo systemctl restart nginx
sudo systemctl enable nginx
sudo systemctl status nginx
```

Expected output:
```
● nginx.service - The nginx HTTP and reverse proxy server
     Active: active (running) since ...
```

---

### 7️⃣ Verify Load Balancing Works

From the jump host or LBR server:

```bash
curl http://stlb01:80
```

Run it multiple times — each request is forwarded to one of the three app servers in **round-robin** order (Nginx's default algorithm). You should see responses from the Apache-backed app servers.

---

## 🏁 Final Result

| Item | Status |
|---|---|
| Nginx installed on `stlb01` | ✅ |
| `upstream` block with all 3 app servers | ✅ |
| `proxy_pass` configured in `location /` | ✅ |
| Only `/etc/nginx/nginx.conf` modified | ✅ |
| Apache port unchanged on all app servers | ✅ |
| Apache running on `stapp01/02/03` | ✅ |
| `curl http://stlb01:80` returns app response | ✅ |

---

## 🧠 Nginx Load Balancer – Key Concepts

### 🔥 Golden Setup Flow

```
1. Verify nginx is installed on LBR server
2. Confirm Apache port and status on all app servers
3. Add upstream block with all app servers + correct port
4. Add proxy_pass inside location / block
5. Validate with nginx -t
6. Restart nginx and enable on boot
7. Test with curl from jump host
```

---

### 📁 Config Structure

| Path | Purpose |
|---|---|
| `/etc/nginx/nginx.conf` | Main config — the ONLY file edited in this task |
| `/etc/httpd/conf/httpd.conf` | Apache config on app servers — read-only, do NOT change |
| `/var/log/nginx/access.log` | Nginx request logs |
| `/var/log/nginx/error.log` | Nginx error logs |

---

### ⚙️ How Nginx Load Balancing Works

```
Client Request (port 80)
        ↓
   stlb01 (Nginx)
        ↓
   upstream nautilus_app
   ┌────────────────────┐
   │  stapp01:3001  (1) │  ← Round 1
   │  stapp02:3001  (2) │  ← Round 2
   │  stapp03:3001  (3) │  ← Round 3
   └────────────────────┘
   (repeats in sequence)
```

---

### 🔄 Nginx Load Balancing Algorithms

| Algorithm | Directive | Behavior |
|---|---|---|
| Round Robin | *(default, no directive needed)* | Requests distributed evenly in sequence |
| Least Connections | `least_conn;` | Sent to server with fewest active connections |
| IP Hash | `ip_hash;` | Same client IP always hits the same server |
| Weighted | `server stapp01:3001 weight=3;` | More requests sent to higher-weight servers |

---

### ⚠️ Common Mistakes to Avoid

| Mistake | Why It Breaks Things |
|---|---|
| Missing `proxy_pass` in `location /` | Nginx serves its own HTML instead of forwarding traffic |
| Wrong upstream port | Connection refused — Apache isn't listening there |
| Editing `conf.d/` instead of `nginx.conf` | Task requires changes only in `nginx.conf` |
| Changing Apache's `Listen` port | Breaks existing app server configuration |
| Not running `sudo` | Permission denied on logs, pid file, and config test |
| Skipping `nginx -t` before restart | Config errors take the service down unexpectedly |

---

## 💡 Key Concepts Learned

- How to configure Nginx as a **reverse proxy load balancer** using `upstream` and `proxy_pass`
- Difference between Nginx **serving content** vs **proxying** to backend servers
- The `upstream` block must be inside `http {}` but **outside** any `server {}` block
- Nginx's default load balancing is **round-robin** — no extra config needed
- Always verify backend services (Apache) are up **before** configuring the load balancer
- Using `sudo` is required for all nginx/systemctl operations as a non-root user
- `nginx -t` is a critical safety step before any service restart
