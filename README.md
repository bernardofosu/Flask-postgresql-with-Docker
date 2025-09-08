
Notes:

ports: "5000:5000" exposes Flask on host port 5000.

FLASK_APP: app.py ensures flask run picks up your app.

db is the service name, so @db is the hostname for Postgres inside the Compose network.

depends_on only sequences startup; it doesn’t wait for DB readiness (usually fine for dev).

3) Build and start with Compose

From the project root:

docker compose up --build
# older Docker installs: docker-compose up --build


You’ll see logs for db and web. When Flask prints something like:

 * Running on http://0.0.0.0:5000


you’re ready.

4) Access the app

Local machine: http://localhost:5000

Remote VM: http://<server-public-ip>:5000

(Ensure any cloud firewall/security group allows inbound TCP 5000.)

Optional: live code editing (dev only)

If you want code changes to reflect without rebuilding, add a bind mount:

  web:
    build: .
    command: flask run --host=0.0.0.0 --debug
    ports:
      - "5000:5000"
    volumes:
      - .:/app            # <— dev-only: mounts your source into the container
    environment:
      FLASK_APP: app.py
      FLASK_ENV: development
      SQLALCHEMY_DATABASE_URI: postgresql://postgres:postgres@db/library_management
    depends_on:
      - db

Quick troubleshooting

Port already in use (5000/5432):

sudo ss -lntp | grep -E '5000|5432'
# change host port mapping if needed, e.g. "5001:5000"


Flask not found / app doesn’t start: make sure requirements.txt has Flask, and your Dockerfile installs it; ensure FLASK_APP=app.py.

DB connection errors at boot: the app might race the DB. Retry or add a simple wait-for-postgres script for dev, or configure SQLAlchemy retries.

See logs per service:

docker compose logs -f web
docker compose logs -f db


Stop everything:

docker compose down