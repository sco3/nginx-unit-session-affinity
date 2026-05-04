# --- Stage 1: Python Dependency Builder ---
FROM ubuntu:24.04 AS python-builder

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.12 \
    python3.12-venv \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml ./
RUN python3.12 -m venv /app/venv && \
    /app/venv/bin/python -m pip install --no-cache-dir --upgrade pip uv && \
    /app/venv/bin/uv pip install .

# --- Stage 2: Runtime Stage ---
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

# Robust GPG acquisition: Download to file first, then dearmor
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates gnupg2 lsb-release && \
    mkdir -p /usr/share/keyrings && \
    # Step 1: Download the key to a temporary file
    curl -fLs https://unit.nginx.org/keys/nginx_signing.key -o /tmp/nginx_signing.key && \
    # Step 2: Dearmor the file (not via pipe)
    gpg --dearmor --yes --output /usr/share/keyrings/nginx-keyring.gpg /tmp/nginx_signing.key && \
    # Step 3: Add the repo
    echo "deb [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/ubuntu/ $(lsb_release -cs) unit" > /etc/apt/sources.list.d/unit.list && \
    # Step 4: Install Unit
    apt-get update && apt-get install -y --no-install-recommends \
    unit \
    unit-python3.12 \
    python3.12-minimal \
    libssl3 && \
    # Step 5: Clean up
    rm /tmp/nginx_signing.key && \
    apt-get purge -y --auto-remove gnupg2 lsb-release && \
    rm -rf /var/lib/apt/lists/*

RUN curl -L -o /usr/local/bin/unitctl https://github.com/nginx/unit/releases/download/1.35.0/unitctl-1.35.0-x86_64-unknown-linux-gnu && \
    chmod +x /usr/local/bin/unitctl

COPY --from=python-builder /app/venv /app/venv
COPY main.py unit_config.json start.sh ./
RUN chmod +x /app/start.sh

RUN mkdir -p /var/lib/unit /var/run/unit && \
    chown -R unit:unit /var/lib/unit /var/run/unit /app

ENV PATH="/app/venv/bin:$PATH"
ENV PYTHONPATH="/app/venv/lib/python3.12/site-packages"
ENV APP_VERSION="1.0.0" 

EXPOSE 8080

USER unit

CMD ["/app/start.sh"]