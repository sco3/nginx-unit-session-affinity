# Build stage: Build nginx unit from source with Python support
FROM ubuntu:24.04 AS builder

RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    python3.12 \
    python3.12-dev \
    libssl-dev \
    libpcre3-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Download and build nginx unit
RUN curl -fsSL https://github.com/nginx/unit/releases/download/1.35.0/unit-1.35.0.tar.gz | tar xz \
    && cd unit-1.35.0 \
    && ./configure --prefix=/usr/local/unit --with-python=python3.12 \
    && make \
    && make install

# Python dependencies builder
FROM ubuntu:24.04 AS python-builder

RUN apt-get update && apt-get install -y \
    python3.12 \
    python3.12-venv \
    python3-pip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install uv using pip with system override (safe in container)
RUN pip install --break-system-packages uv

WORKDIR /app

COPY pyproject.toml ./
RUN uv venv /app/venv && \
    /app/venv/bin/python -m uv pip install -e .

# Runtime stage: Create minimal runtime image
FROM ubuntu:24.04

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    python3.12 \
    curl \
    libssl3 \
    libpcre3 \
    zlib1g \
    && rm -rf /var/lib/apt/lists/*

# Copy built nginx unit from builder
COPY --from=builder /usr/local/unit /usr/local/unit

# Copy Python packages from python-builder
COPY --from=python-builder /app/venv /app/venv

# Create unitd user
RUN useradd -r -d /var/empty -s /bin/false unitd

WORKDIR /app

# Create necessary directories
RUN mkdir -p /var/lib/unit /var/run/unit && \
    chown -R unitd:unitd /var/lib/unit /var/run/unit

COPY pyproject.toml main.py unit_config.json start.sh ./

RUN chmod +x /app/start.sh

# Set PATH to include nginx unit and Python packages
ENV PATH="/usr/local/unit/sbin:/app/venv/bin:$PATH"
ENV PYTHONPATH="/app/venv/lib/python3.12/site-packages:$PYTHONPATH"

EXPOSE 8080

CMD ["/app/start.sh"]
