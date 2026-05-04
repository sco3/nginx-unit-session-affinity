# --- Stage 1: Python Dependency Builder ---
FROM ubuntu:24.04 AS python-builder

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

# Install minimal build tools for Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.12 \
    python3.12-venv \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment and install dependencies
COPY pyproject.toml ./
RUN python3.12 -m venv /app/venv && \
    /app/venv/bin/python -m pip install --no-cache-dir --upgrade pip uv && \
    /app/venv/bin/uv pip install .

# --- Stage 2: Runtime Stage ---
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

# Install NGINX Unit from official repo with robust GPG handling
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates gnupg2 lsb-release && \
    mkdir -p /usr/share/keyrings && \
    curl -fLs https://unit.nginx.org/keys/nginx_signing.key | \
    gpg --dearmor --yes -o /usr/share/keyrings/nginx-keyring.gpg && \
    [ -s /usr/share/keyrings/nginx-keyring.gpg ] && \
    echo "deb [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/ubuntu/ $(lsb_release -cs) unit" > /etc/apt/sources.list.d/unit.list && \
    apt-get update && apt-get install -y --no-install-recommends \
    unit \
    unit-python3.12 \
    python3.12-minimal \
    libssl3 && \
    # Cleanup to keep the image lean
    apt-get purge -y --auto-remove gnupg2 lsb-release && \
    rm -rf /var/lib/apt/lists/*

# Install unitctl (cli tool)
RUN curl -L -o /usr/local/bin/unitctl https://github.com/nginx/unit/releases/download/1.35.0/unitctl-1.35.0-x86_64-unknown-linux-gnu && \
    chmod +x /usr/local/bin/unitctl

# Copy the Python virtual environment from the builder stage
COPY --from=python-builder /app/venv /app/venv

# Copy application files
COPY main.py unit_config.json start.sh ./
RUN chmod +x /app/start.sh

# Set up permissions for the 'unit' user
RUN mkdir -p /var/lib/unit /var/run/unit && \
    chown -R unit:unit /var/lib/unit /var/run/unit /app

# Environment variables for Python and future references
ENV PATH="/app/venv/bin:$PATH"
ENV PYTHONPATH="/app/venv/lib/python3.12/site-packages"
# Example of a variable for future reference
ENV APP_VERSION="1.0.0" 

EXPOSE 8080

# Switch to non-privileged user for security
USER unit

CMD ["/app/start.sh"]