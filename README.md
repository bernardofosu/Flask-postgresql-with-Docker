## ▶️ Build & Start with Compose

From your **project root** (where `docker-compose.yml` lives):

```bash
docker compose up --build
# older Docker installs:
# docker-compose up --build
```

You’ll see logs for **db** and **web**. When Flask prints something like:


```sh
Creating flask-postgresql-with-docker_db_1 ... error

ERROR: for flask-postgresql-with-docker_db_1  Cannot start service db: driver failed programming external connectivity on endpoint flask-postgresql-with-docker_db_1 (5242c21dfa4a396d17189afcea2f5bda4d08fa58302e7226e25109784171bd9b): failed to bind port 0.0.0.0:5432/tcp: Error starting userland proxy: listen tcp4 0.0.0.0:5432: bind: address already in use

ERROR: for db  Cannot start service db: driver failed programming external connectivity on endpoint flask-postgresql-with-docker_db_1 (5242c21dfa4a396d17189afcea2f5bda4d08fa58302e7226e25109784171bd9b): failed to bind port 0.0.0.0:5432/tcp: Error starting userland proxy: listen tcp4 0.0.0.0:5432: bind: address already in use
ERROR: Encountered errors while bringing up the project.
```

1) See who’s using 5432
```sh
sudo ss -lntp | grep 5432
# or
sudo lsof -iTCP:5432 -sTCP:LISTEN -P -n
# also check running containers
docker ps --format 'table {{.ID}}\t{{.Image}}\t{{.Ports}}\t{{.Names}}' | grep 5432
```
1) Common causes & fixes
A) Local PostgreSQL service running

Ubuntu service name is postgresql (not postgres):
```sh
sudo systemctl status postgresql
sudo systemctl stop postgresql
sudo systemctl disable postgresql
```

If installed via Snap:
```sh
sudo snap services
sudo snap stop postgresql

B) Another Docker container holding 5432
docker ps | grep 5432
docker stop <container>
docker rm <container>
```
C) Just free the port quickly (dev)
sudo fuser -k 5432/tcp


(If it respawns, it’s a service—use A/B above.)

3) Quick workaround: change the host port

If you don’t need 5432 specifically on the host, change your docker-compose.yml:
```sh
services:
  db:
    image: postgres:13
    ports:
      - "5433:5432"   # host:container
```
Then connect from your host to localhost:5433.
Other containers in the same Compose network should still use the service name db:5432.

4) Bring the stack up
```sh
docker compose up --build

```text
 * Running on http://0.0.0.0:5000
```
```

---

## 🌐 Access the App

- **Local machine:** http://localhost:5000  
- **Remote VM:** `http://<server-public-ip>:5000`  
  - Ensure your cloud firewall / **security group** allows inbound **TCP 5000**.

---

## 🔁 Optional: Live Code Editing (dev only)

To reflect code changes **without** rebuilding, add a bind mount and enable debugger:

```yaml
  web:
    build: .
    command: flask run --host=0.0.0.0 --debug
    ports:
      - "5000:5000"
    volumes:
      - .:/app                 # mounts your source into the container (dev-only)
    environment:
      FLASK_APP: app.py
      FLASK_ENV: development
      SQLALCHEMY_DATABASE_URI: postgresql://postgres:postgres@db/library_management
    depends_on:
      - db
```

> 🧠 In dev, `--debug` gives hot reload and better error pages. Remove it for prod.

---

## 🛠️ Quick Troubleshooting

**Port already in use (5000/5432):**
```bash
sudo ss -lntp | grep -E '5000|5432'
# change host port mapping if needed, e.g. "5001:5000" or "5433:5432"
```

**Flask not found / app won’t start:**  
- Ensure `requirements.txt` includes **Flask** (and any extensions).  
- Confirm your Dockerfile installs it and sets `WORKDIR /app`.  
- Set `FLASK_APP=app.py` (or adjust to your entry module).

**DB connection errors at boot (race condition):**  
- The app may start **before** Postgres is ready. For dev, just retry.  
- Or add a simple **wait‑for‑postgres** script before launching Flask.  
- For production, implement robust **retry logic** in your DB client / ORM.

**View logs per service:**
```bash
docker compose logs -f web
docker compose logs -f db
```

**Stop everything:**
```bash
docker compose down
```

---

## ✅ Summary

- **`ports: "5000:5000"`** exposes Flask on your host.  
- **`FLASK_APP: app.py`** ensures `flask run` picks up the right module.  
- **`db`** is your Postgres **hostname** inside the Compose network.  
- **`depends_on`** sequences startup only — fine for dev; add retries or checks for prod.  
- Use a **bind mount** for live editing during development.  

Happy hacking! 🐍⚡🐘


## Postgres container
Option 1: run psql directly (recommended)
```sh
# from the host, not inside any container
docker exec -it flask-postgresql-with-docker_db_1 \
  psql -U postgres -d library_management
```

Option 2: open a shell, then psql
```sh
docker exec -it flask-postgresql-with-docker_db_1 bash
psql -U postgres -d library_management


-U postgres uses the default superuser you set in compose.
-d library_management matches your URI: postgresql://postgres:postgres@db/library_management.
```

Handy psql commands
```sh
\l            -- list databases
\c dbname     -- connect to a database
\dn           -- list schemas
\dt           -- list tables in current schema
\d table_name -- describe table
\du           -- list roles/users
SELECT * FROM table_name LIMIT 10;
\q            -- quit
```
Using docker compose (alias)

If you’re in the project directory:
```sh
docker compose exec db psql -U postgres -d library_management
```