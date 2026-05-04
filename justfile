set shell := ["bash", "-lc"]

# Display all available targets.
default:
    @just --list

# Install project dependencies and development tools.
build:
    uv install --with dev

# Run static type checking with pyrefly.
check:
    uv run pyrefly check main.py

# Run the application locally on port 8080.
run:
    uv run uvicorn main:app --host 0.0.0.0 --port 8080

# Build and run the Docker Compose stack.
docker:
    docker compose up --build --scale app=${UNIT_REPLICAS:-3}
