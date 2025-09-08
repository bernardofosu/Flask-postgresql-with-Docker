# ---------- Base image (shared)
FROM python:3.9-slim AS base
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
WORKDIR /app

# ---------- Builder: compile/install deps once
FROM base AS builder
# (only if you have packages needing compilation)
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential gcc && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
# install into a virtualenv inside /opt/venv
RUN python -m venv /opt/venv && \
    /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

# ---------- Runtime: minimal image
FROM base AS runtime
# use the venv from the builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# app code
COPY . .

EXPOSE 5000
# set FLASK_APP if your app entry isn’t auto-detected
# ENV FLASK_APP=app.py
CMD ["flask", "run", "--host=0.0.0.0"]
