FROM ubuntu:24.04

# Отключаем интерактив
ENV DEBIAN_FRONTEND=noninteractive

# 1. Устанавливаем базу (curl нужен для ключа, ca-certificates для HTTPS)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 2. Скачиваем ключ напрямую в keyring (как в инструкции)
RUN curl --output /usr/share/keyrings/nginx-keyring.gpg \
    https://unit.nginx.org/keys/nginx-keyring.gpg

# 3. Настраиваем репозиторий
RUN echo "deb [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/ubuntu/ noble unit" > /etc/apt/sources.list.d/unit.list && \
    echo "deb-src [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/ubuntu/ noble unit" >> /etc/apt/sources.list.d/unit.list

# 4. Обновляем списки и ставим Unit + Python 3.12
RUN apt-get update && apt-get install -y --no-install-recommends \
    unit \
    unit-python3.12 \
    python3.12-venv \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 5. Твои переменные для будущего[cite: 1]
ENV PATH="/app/venv/bin:$PATH"
ENV UNIT_VERSION="1.32.1"

# 6. Настройка Python окружения
COPY pyproject.toml ./
RUN python3.12 -m venv /app/venv && \
    /app/venv/bin/pip install --no-cache-dir --upgrade pip && \
    /app/venv/bin/pip install --no-cache-dir .

COPY . .

# 7. Права (в Docker не нужен systemctl, но нужны папки и права)
RUN mkdir -p /var/lib/unit /var/run/unit && \
    chown -R unit:unit /app /var/lib/unit /var/run/unit && \
    chmod +x /app/start.sh

EXPOSE 8080

USER unit

CMD ["/app/start.sh"]