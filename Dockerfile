FROM nginx/unit:1.35.0-python3.12

WORKDIR /app

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml requirements.txt main.py unit_config.json start.sh ./
RUN python3 -m pip install --no-cache-dir -r requirements.txt

RUN chmod +x /app/start.sh

EXPOSE 8080

CMD ["/app/start.sh"]
