FROM ubuntu:24.04

# Отключаем интерактивность
ENV DEBIAN_FRONTEND=noninteractive

# Устанавливаем базу и добавляем репозиторий NGINX Unit вручную
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gnupg2 \
    lsb-release \
    && mkdir -p /usr/share/keyrings \
    # Качаем ключ во временный файл
    && curl -fLs https://unit.nginx.org/keys/nginx_signing.key -o /tmp/nginx.key \
    # Конвертируем ключ
    && gpg --dearmor -o /usr/share/keyrings/nginx-keyring.gpg /tmp/key.asc 2>/dev/null || gpg --dearmor -o /usr/share/keyrings/nginx-keyring.gpg /tmp/nginx.key \
    # Добавляем репозиторий
    && echo "deb [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/ubuntu/ noble unit" > /etc/apt/sources.list.d/unit.list \
    # Теперь ставим сам Unit
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    unit \
    unit-python3.12 \
    python3.12 \
    python3.12-venv \
    python3-pip \
    && rm -rf /var/lib/apt/lists/* /tmp/nginx.key

WORKDIR /app

# Настройка Python окружения
COPY pyproject.toml ./
RUN python3.12 -m venv /app/venv && \
    /app/venv/bin/pip install --no-cache-dir --upgrade pip && \
    /app/venv/bin/pip install --no-cache-dir .

# Переменные, которые ты хотел сохранить для ссылок[cite: 1]
ENV PATH="/app/venv/bin:$PATH"
ENV PYTHONPATH="/app/venv/lib/python3.12/site-packages"

COPY . .

# Права доступа
RUN mkdir -p /var/lib/unit /var/run/unit && \
    chown -R unit:unit /app /var/lib/unit /var/run/unit && \
    chmod +x /app/start.sh

EXPOSE 8080

USER unit

CMD ["/app/start.sh"]