# --- Stage 1: Python Dependency Builder ---
FROM ubuntu:24.04 AS python-builder

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

RUN apt-get update && apt-get install -y \
    python3.12 \
    python3.12-venv \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Use a virtual environment for clean dependency isolation
COPY pyproject.toml ./
RUN python3.12 -m venv /app/venv && \
    /app/venv/bin/python -m pip install --no-cache-dir --upgrade pip uv && \
    /app/venv/bin/uv pip install .

# --- Stage 2: Runtime Stage ---
FROM ubuntu:24.04

# Install NGINX Unit from official repo & Runtime dependencies
RUN apt-get update && apt-get install -y curl ca-certificates gnupg2 lsb-release && \
    curl -fLs https://unit.nginx.org/keys/nginx_signing.key | gpg --dearmor -o /usr/share/keyrings/nginx-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/ubuntu/ $(lsb_release -cs) unit" > /etc/apt/sources.list.d/unit.list && \
    apt-get update && apt-get install -y \
    unit \
    unit-python3.12 \
    python3.12-minimal \
    libssl3 \
    && apt-get purge -y --auto-remove gnupg2 lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Copy unitctl and built Python environment
# Note: unitctl 1.35.0 is downloaded here directly to avoid an extra build stage
RUN curl -L -o /usr/local/bin/unitctl https://github.com/nginx/unit/releases/download/1.35.0/unitctl-1.35.0-x86_64-unknown-linux-gnu && \
    chmod +x /usr/local/bin/unitctl

COPY --from=python-builder /app/venv /app/venv

# Set up application environment
WORKDIR /app
COPY pyproject.toml main.py unit_config.json start.sh ./
RUN chmod +x /app/start.sh

# Ensure Unit directories exist with proper permissions
# The 'unit' user is usually created automatically by the 'unit' package
RUN mkdir -p /var/lib/unit /var/run/unit && \
    chown -R unit:unit /var/lib/unit /var/run/unit /app

# Environment configuration
ENV PATH="/app/venv/bin:$PATH"
ENV PYTHONPATH="/app/venv/lib/python3.12/site-packages"

EXPOSE 8080

# Use the 'unit' user for runtime security
USER unit

CMD ["/app/start.sh"]