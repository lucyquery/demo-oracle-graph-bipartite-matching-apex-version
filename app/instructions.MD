# Full Setup Instructions

This guide explains how to set up the full environment required to run the Bipartite Matching APEX application.

## Overview

The setup consists of three main components:

1. Oracle Database (container)
2. Oracle APEX (installed inside the database)
3. ORDS (running on the host)

## Credentials

This guide uses a default password for simplicity:

```
Matching12345!
```

⚠️ You may change it, but ensure consistency across all steps.


## 1. Start Oracle Database (Container)

```bash
podman run -d \
  --name oracle23aifree \
  -p 1521:1521 \
  -e ORACLE_PWD=Matching12345! \
  container-registry.oracle.com/database/free:latest
```

## 2. Access Container

```bash
podman exec -it oracle23aifree bash
cd /home/oracle
```

## 3. Install Oracle APEX

```bash
curl -O https://download.oracle.com/otn_software/apex/apex-latest.zip

unzip apex-latest.zip

cd apex
```

```bash
sqlplus / as sysdba
```

```sql
ALTER SESSION SET CONTAINER = FREEPDB1;

@apexins.sql SYSAUX SYSAUX TEMP /i/

@apxchpwd.sql
```

Set credentials:

* Username: ADMIN
* Password: Matching12345!

## 4. Install ORDS (Outside Container)

Exit the container first:

```bash
exit
```

Download and unzip:

```bash
curl -O https://download.oracle.com/otn_software/java/ords/ords-latest.zip

unzip ords-latest.zip
```

Create required folders:

```bash
mkdir -p ~/ords-config
mkdir -p ~/apex-images
```

## 5. Copy APEX Static Files

```bash
podman cp oracle23aifree:/home/oracle/apex/images ~/apex-images/
```

## 6. Install ORDS

```bash
./bin/ords --config ~/ords-config install
```

Provide:

* Connection Type: Basic
* Host: localhost
* Port: 1521
* Service: FREEPDB1
* Admin User: SYS
* Password: Matching12345!

When prompted for ORDS runtime user password:

➡️ Choose option to set password manually
➡️ Use: `Matching12345!`

## 7. Configure Static Files (/i/)

```bash
./bin/ords --config ~/ords-config config set standalone.static.path /home/user/apex-images/images
./bin/ords --config ~/ords-config config set standalone.static.context.path /i
```


## 8. Start ORDS

```bash
./bin/ords --config ~/ords-config serve --port 8080
```


## 9. Verify Static Files

```bash
curl -I http://localhost:8080/i/apex_version.js
```

Expected:

```
HTTP/1.1 200 OK
```


## 10. Access APEX

Open:

```
http://localhost:8080/ords/apex
```

Login:

* Workspace: INTERNAL
* Username: ADMIN
* Password: Matching12345!


## 11. Prepare Application Schema

Copy script into container:

```bash
podman cp hopcroftkarp.sql oracle23aifree:/home/oracle/
```

Enter container:

```bash
podman exec -it oracle23aifree bash
sqlplus / as sysdba
```

```sql
ALTER SESSION SET CONTAINER = FREEPDB1;

CREATE USER matching_app IDENTIFIED BY "Matching12345!";

GRANT CREATE SESSION TO matching_app;
GRANT CREATE TABLE TO matching_app;
GRANT CREATE TYPE TO matching_app;
GRANT CREATE PROCEDURE TO matching_app;
GRANT CREATE SEQUENCE TO matching_app;
GRANT CREATE VIEW TO matching_app;
GRANT CREATE TRIGGER TO matching_app;
GRANT UNLIMITED TABLESPACE TO matching_app;
```

## 12. Run Algorithm Script

```bash
sqlplus matching_app/Matching12345\!@FREEPDB1
```

```sql
@/home/oracle/hopcroftkarp.sql
```

## 13. Import APEX Application

* Open App Builder
* Import application
* Upload the exported file (`f100.sql`)

---

## Troubleshooting

### ORA-01017 (Invalid Credentials)

Ensure passwords match:

* SYS
* ORDS_PUBLIC_USER
* Schema user

### ORA-28000 (Account Locked)

```sql
ALTER USER APEX_PUBLIC_USER ACCOUNT UNLOCK;
ALTER USER ORDS_PUBLIC_USER ACCOUNT UNLOCK;
```

---
