# 📅 Day 17 – Configure PostgreSQL Database and User on Database Server

## 🎯 Task
Set up a **PostgreSQL** database and user on the Nautilus database server (`stdb01`) in the Stratos DC infrastructure as a pre-requisite for a new application deployment by the Nautilus application development team.

**Goal:**
- Create a PostgreSQL database user `kodekloud_top` with password `YchZHRcLkL`
- Create a database `kodekloud_db5`
- Grant full privileges on `kodekloud_db5` to user `kodekloud_top`
- Do **not** restart the PostgreSQL service at any point

---

## 🧠 Understanding the Problem

New applications often require a dedicated database and a scoped user account rather than using a shared superuser. This task simulates a real-world DBA pre-deployment checklist — provisioning an isolated database and a user with just enough permissions to own it.

Key challenges:
- All `psql` commands must be run as the `postgres` system user via `sudo -u postgres`
- The task must be completed without restarting the PostgreSQL service
- SSH into `stdb01` from the jump host as `peter` before running commands

---

## 🔎 Step-by-Step Setup Approach

### 1️⃣ SSH into the Database Server

```bash
ssh peter@stdb01
```

---

### 2️⃣ Create the Database User

```bash
sudo -u postgres psql -c "CREATE USER kodekloud_top WITH PASSWORD 'YchZHRcLkL';"
```

Expected output:
```
CREATE ROLE
```

👉 In PostgreSQL, users and roles are the same concept — `CREATE USER` is shorthand for `CREATE ROLE` with login privileges.

---

### 3️⃣ Create the Database

```bash
sudo -u postgres psql -c "CREATE DATABASE kodekloud_db5;"
```

Expected output:
```
CREATE DATABASE
```

---

### 4️⃣ Grant Full Privileges

```bash
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE kodekloud_db5 TO kodekloud_top;"
```

Expected output:
```
GRANT
```

👉 `ALL PRIVILEGES` on a database grants CONNECT, CREATE, and TEMP. For full ownership of objects inside the DB, the user would also need to be made owner — but for this task, database-level privileges are sufficient.

---

### 5️⃣ Verify the Setup (Optional but Recommended)

```bash
sudo -u postgres psql -c "\du"           # list users/roles
sudo -u postgres psql -c "\l"            # list databases with access privileges
```

Confirm `kodekloud_top` appears in the role list and that `kodekloud_db5` shows the correct privileges.

---

## 🏁 Final Result

| Item | Status |
|---|---|
| SSH into `stdb01` as `peter` | ✅ |
| User `kodekloud_top` created | ✅ |
| Password set to `YchZHRcLkL` | ✅ |
| Database `kodekloud_db5` created | ✅ |
| Full privileges granted to `kodekloud_top` | ✅ |
| PostgreSQL service NOT restarted | ✅ |

---

## 🧠 PostgreSQL User & Database Setup – Key Concepts

### 🔥 Golden Setup Flow

```
1. SSH into the database server
2. Switch to postgres system user via sudo
3. Create the role/user with password
4. Create the target database
5. Grant ALL PRIVILEGES on the database to the user
6. Verify with \du and \l
```

---

### 📁 Relevant Paths & Commands

| Item | Detail |
|---|---|
| PostgreSQL superuser | `postgres` (system + DB user) |
| Run psql as superuser | `sudo -u postgres psql` |
| One-liner execution | `sudo -u postgres psql -c "<SQL>"` |
| List roles | `\du` |
| List databases | `\l` |

---

### ⚙️ How Privileges Flow in PostgreSQL

```
postgres (superuser)
        ↓
  CREATE USER kodekloud_top
        ↓
  CREATE DATABASE kodekloud_db5
        ↓
  GRANT ALL PRIVILEGES ON kodekloud_db5 → kodekloud_top
        ↓
  App connects as kodekloud_top to kodekloud_db5
```

---

### ⚠️ Common Mistakes to Avoid

| Mistake | Why It Breaks Things |
|---|---|
| Running `psql` without `sudo -u postgres` | Permission denied — only the postgres user can manage roles |
| Restarting PostgreSQL | Explicitly forbidden by the task requirements |
| Forgetting quotes around the password | Syntax error or password set incorrectly |
| Granting privileges before creating the database | Error — the target database must exist first |
| Skipping the `GRANT` step | User can log in but has no access to the database |

---

## 💡 Key Concepts Learned

- PostgreSQL users are roles — `CREATE USER` = `CREATE ROLE` with `LOGIN`
- All admin operations require running as the `postgres` system user via `sudo -u postgres`
- `GRANT ALL PRIVILEGES ON DATABASE` covers connection and schema-level access
- Order matters: create the user first, then the database, then grant privileges
- The service does **not** need a restart for user/database changes — they take effect immediately
