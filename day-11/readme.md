# 📅 Day 11 – Deploy Java Application on Apache Tomcat

## 🎯 Task

Deploy a Java-based application on **App Server 2 (`stapp02`)** using Apache Tomcat.

### Requirements:

* Install Tomcat server
* Configure Tomcat to run on **port 3002**
* Deploy `ROOT.war` (available on Jump Host at `/tmp`)
* Application should be accessible at:

```
http://stapp02:3002
```

---

## 🧠 Understanding the Task

Apache Tomcat is a **Java application server** used to deploy `.war` files.

Key concepts:

* `.war` → Web Application Archive
* `ROOT.war` → deployed at base URL `/`
* Default Tomcat port → `8080` (changed to `3002`)

---

## ⚙️ Solution

### Step 1: Connect to App Server 2

```bash
ssh steve@stapp02
```

---

### Step 2: Create Tomcat User

```bash
sudo groupadd tomcat
sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat
```

---

### Step 3: Create Directory

```bash
sudo mkdir -p /opt/tomcat
```

---

### Step 4: Download Tomcat

```bash
cd /tmp
wget https://archive.apache.org/dist/tomcat/tomcat-10/v10.1.34/bin/apache-tomcat-10.1.34.tar.gz
```

---

### Step 5: Extract Tomcat

```bash
sudo tar -xzf apache-tomcat-10.1.34.tar.gz -C /opt/tomcat --strip-components=1
```

---

### Step 6: Set Permissions

```bash
sudo chown -R tomcat:tomcat /opt/tomcat
sudo chmod -R 755 /opt/tomcat
```

---

### Step 7: Configure Port

Edit Tomcat config:

```bash
sudo vi /opt/tomcat/conf/server.xml
```

Find:

```
Connector port="8080"
```

Change to:

```
Connector port="3002"
```

---

### Step 8: Copy Application from Jump Host

Run on **jump host**:

```bash
scp /tmp/ROOT.war steve@stapp02:/tmp/
```

---

### Step 9: Remove Default Application (Important)

```bash
sudo rm -rf /opt/tomcat/webapps/ROOT
sudo rm -f /opt/tomcat/webapps/ROOT.war
```

---

### Step 10: Deploy Application

```bash
sudo cp /tmp/ROOT.war /opt/tomcat/webapps/
```

---

### Step 11: Start Tomcat

```bash
sudo /opt/tomcat/bin/startup.sh
```

---

## ✅ Verification

```bash
curl http://stapp02:3002
```

Expected:

* Application output (NOT Tomcat default page)

---

## ❗ Common Mistakes

* Downloading `.sha512` instead of `.tar.gz`
* Not removing default `ROOT` app
* Using wrong package manager (`apt` instead of `yum`)
* Not changing port
* Copying WAR before removing ROOT

---

## 🏁 Result

* Tomcat installed successfully
* Running on port **3002**
* Application deployed using `ROOT.war`
* Accessible via base URL

---

## 💡 Real-World Relevance

This setup is commonly used for:

* Java web applications
* Microservices deployment
* Internal enterprise tools
* CI/CD pipelines

---

