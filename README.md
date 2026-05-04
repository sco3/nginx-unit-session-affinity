# nginx-unit-session-affinity

## Overview

This simple Python app uses `litestar` as the framework and `msgspec` for JSON struct parsing.
It exposes a POST endpoint at `/hello` and validates the `session-id` request header.

The app is designed for deployment with NGINX Unit using `unit_config.json`.

## Files

- `main.py` - Litestar app with `/hello` endpoint
- `requirements.txt` - Python dependencies
- `unit_config.json` - NGINX Unit application configuration

## Endpoint

POST `/hello`

Request headers:
- `session-id`: required

Request body JSON:
```json
{
  "name": "Alice"
}
```

Response:
- `hello Alice`

Logs include the worker process ID and the `session-id` value.

## Run locally

1. Install dependencies with `uv`:
   ```bash
   uv install
   ```
2. Run the app with an ASGI server or configure NGINX Unit.

## NGINX Unit

Use `unit_config.json` to load the app into NGINX Unit. The application is configured for Python 3.11 with `main.app` as the callable.

## Docker Compose with Sticky Sessions

This repo includes a `docker-compose.yml` that launches:
- one backend service running NGINX Unit + the Python app
- one NGINX load balancer with session affinity based on the `session-id` header

The number of backend containers can be controlled with `UNIT_REPLICAS`, and the number of Unit worker processes per container can be controlled with `UNIT_WORKERS`.

Create a `.env` file to set defaults:

```env
UNIT_REPLICAS=3
UNIT_WORKERS=4
```

Start the full stack:

```bash
docker compose up --build --scale app=${UNIT_REPLICAS}
```

Use `just` for local workflows:

```bash
just build
just check
just run
```

Then call the app via:

```bash
curl -X POST http://localhost:8080/hello \
  -H "Content-Type: application/json" \
  -H "session-id: abc123" \
  -d '{"name": "Alice"}'
```

The NGINX load balancer uses the `session-id` header to keep requests for the same session on the same backend.
