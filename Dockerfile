# Использовать Ubuntu 24.04 (Noble)
FROM ubuntu:24.04

# Отключаем интерактивные вопросы
ENV DEBIAN_FRONTEND=noninteractive

# 1. Устанавливаем ВСЁ одной пачкой из стандартных репозиториев Ubuntu.
# В Ubuntu 24.04 пакет 'unit' и 'unit-python3.12' есть в официальных апстрим-репозиториях.
RUN apt-get update && apt-get install -y --no-install-recommends \
    unit \
    unit-python3.12 \
    python3.12 \
    python3.12-venv \
    python3-pip \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 2. Создаем виртуальное окружение и ставим зависимости
COPY pyproject.toml ./
RUN python3.12 -m venv /app/venv && \
    /app/venv/bin/pip install --no-cache-dir --upgrade pip && \
    /app/venv/bin/pip install --no-cache-dir .

# 3. Копируем код
COPY . .

# 4. Настраиваем права (Unit в Ubuntu работает под пользователем 'unit')
RUN mkdir -p /var/lib/unit /var/run/unit && \
    chown -R unit:unit /app /var/lib/unit /var/run/unit && \
    chmod +x /app/start.sh

# Твои переменные для будущего[cite: 1]
ENV PATH="/app/venv/bin:$PATH"
ENV UNIT_LOG_LEVEL="info"

EXPOSE 8080

# Запускаем от пользователя unit
USER unit

CMD ["/app/start.sh"]