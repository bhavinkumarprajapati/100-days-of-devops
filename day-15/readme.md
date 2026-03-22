# 📅 Day 15 – Deploy Nginx with SSL on App Server 2

## 🎯 Task
Deploy and configure **Nginx** on App Server 2 (`stapp02`) with HTTPS support using a self-signed SSL certificate.

**Goal:**
- Install Nginx (mainline version) from the official nginx repo
- Deploy a self-signed SSL certificate and key
- Serve a basic HTML page over HTTPS
- Verify the setup is reachable from the jump host via `curl`

---

## 🧠 Understanding the Problem

Standing up a production-ready Nginx server involves more than just installing the package. You need to handle:
- Package repository configuration (stable vs mainline)
- SSL certificate placement and permissions
- Nginx server block configuration
- Service startup and enablement
- End-to-end verification from a remote host

---

## 🔎 Step-by-Step Setup Approach

### 1️⃣ Install yum-utils & Configure Nginx Repo

```bash
sudo yum install yum-utils
sudo nano /etc/yum.repos.d/nginx.repo
```

Contents of `nginx.repo`:

```ini
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/$releasever/$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
```

👉 Mainline is disabled by default — enable it explicitly.

---

### 2️⃣ Enable Mainline & Install Nginx

```bash
sudo yum-config-manager --enable nginx-mainline
sudo yum install nginx
```

👉 Installs **nginx 1.29.6** (mainline) along with updated OpenSSL dependencies.

---

### 3️⃣ Move SSL Certificate & Key to Secure Location

```bash
sudo mkdir -p /etc/nginx/ssl
sudo mv /tmp/nautilus.crt /etc/nginx/ssl/
sudo mv /tmp/nautilus.key /etc/nginx/ssl/
sudo chmod 600 /etc/nginx/ssl/nautilus.key
```

👉 `/tmp` is not a safe place for secrets — always move certs to `/etc/nginx/ssl/` or `/etc/ssl/`.

---

### 4️⃣ Create SSL Nginx Server Block

```bash
sudo tee /etc/nginx/conf.d/ssl.conf > /dev/null <<'EOF'
server {
    listen 443 ssl;
    server_name stapp02;

    ssl_certificate     /etc/nginx/ssl/nautilus.crt;
    ssl_certificate_key /etc/nginx/ssl/nautilus.key;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}

server {
    listen 80;
    server_name stapp02;
    return 301 https://$host$request_uri;
}
EOF
```

👉 HTTP (port 80) redirects to HTTPS (port 443) — best practice.

---

### 5️⃣ Create index.html Under Document Root

```bash
echo "Welcome!" | sudo tee /usr/share/nginx/html/index.html
```

---

### 6️⃣ Validate Config, Enable & Start Nginx

```bash
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl start nginx
```

Expected output:
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

👉 Always run `nginx -t` before starting — catches config errors before they break the service.

---

### 7️⃣ Test from Jump Host

```bash
curl -Ik https://stapp02/
```

Expected output:
```
HTTP/1.1 200 OK
Server: nginx/1.29.6
Content-Type: text/html
Content-Length: 9
```

👉 `-I` fetches headers only. `-k` skips certificate verification (expected for self-signed certs). ✅

---

## 🏁 Final Result

| Item | Status |
|---|---|
| Nginx installed (mainline) | ✅ |
| SSL cert deployed securely | ✅ |
| HTTPS server block configured | ✅ |
| HTTP → HTTPS redirect active | ✅ |
| index.html serving correctly | ✅ |
| Reachable from jump host | ✅ |

---

## 🧠 Nginx SSL Setup – Key Concepts

### 🔥 Golden Setup Flow

```
1. Install Nginx with correct repo
2. Move certs to a secure location
3. Configure server block with SSL paths
4. Validate config with nginx -t
5. Enable & start service
6. Verify from remote host
```

---

### 📁 Directory Layout

| Path | Purpose |
|---|---|
| `/etc/nginx/conf.d/` | Drop-in server block configs |
| `/etc/nginx/ssl/` | SSL certificate storage |
| `/usr/share/nginx/html/` | Default document root |
| `/etc/yum.repos.d/nginx.repo` | Nginx package repository |

---

### 🔐 SSL Permission Best Practices

| File | Recommended Permission | Why |
|---|---|---|
| `.crt` (certificate) | `644` | Public — readable by all |
| `.key` (private key) | `600` | Private — readable by root only |

---

### 🧠 curl Flag Cheat Sheet

| Flag | Meaning |
|---|---|
| `-I` | Fetch headers only (HEAD request) |
| `-k` | Skip SSL certificate verification |
| `-v` | Verbose — shows full TLS handshake |
| `-L` | Follow redirects |

---

## 💡 Key Concepts Learned

- Nginx official repo setup on RHEL/CentOS 9
- Difference between stable and mainline channels
- Proper SSL certificate directory structure and file permissions
- Writing `conf.d/` drop-in configs vs editing `nginx.conf` directly
- HTTP to HTTPS redirect using `return 301`
- Using `nginx -t` to catch configuration errors before service startup
- Self-signed certs and why `-k` is needed in `curl` for testing
