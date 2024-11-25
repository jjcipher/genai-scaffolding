#!/usr/bin/env bash
# setup_docker.sh - Set up Docker configuration for GenAI projects

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../scripts/utils/logging.sh"

setup_docker() {
    local project_dir="$1"
    local project_name="$2"
    local python_version="$3"
    local use_ollama="$4"
    
    log "INFO" "Setting up Docker configuration..."
    
    # Create Dockerfile
    cat > "$project_dir/Dockerfile" << ENDOFFILE
# syntax=docker/dockerfile:1.4
FROM python:${python_version}-slim as base

# Setup env
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONFAULTHANDLER 1
ENV PYTHONUNBUFFERED 1
ENV PYTHONPATH /app/src

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \\
    build-essential \\
    curl \\
    git \\
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
ENV POETRY_VERSION=1.7.1
ENV POETRY_HOME=/opt/poetry
ENV POETRY_VENV=/opt/poetry-venv
ENV POETRY_CACHE_DIR=/opt/.cache

# Install poetry separated from system interpreter
RUN python -m venv \$POETRY_VENV \\
    && \$POETRY_VENV/bin/pip install -U pip setuptools \\
    && \$POETRY_VENV/bin/pip install poetry==\$POETRY_VERSION

# Add poetry to PATH
ENV PATH="\${POETRY_VENV}/bin:\${PATH}"

# Set working directory
WORKDIR /app

# Install dependencies
COPY poetry.lock pyproject.toml ./
RUN poetry config virtualenvs.create false \\
    && poetry install --no-interaction --no-ansi --no-root

# Copy project files
COPY src/ ./src/
COPY configs/ ./configs/

# Run the application
CMD ["python", "-m", "${project_name}.main"]
ENDOFFILE

    # Create development Dockerfile
    cat > "$project_dir/Dockerfile.dev" << ENDOFFILE
# syntax=docker/dockerfile:1.4
FROM python:${python_version}-slim as dev

# Setup env
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONFAULTHANDLER 1
ENV PYTHONUNBUFFERED 1
ENV PYTHONPATH /app/src

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \\
    build-essential \\
    curl \\
    git \\
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
ENV POETRY_VERSION=1.7.1
ENV POETRY_HOME=/opt/poetry
ENV POETRY_VENV=/opt/poetry-venv
ENV POETRY_CACHE_DIR=/opt/.cache

# Install poetry separated from system interpreter
RUN python -m venv \$POETRY_VENV \\
    && \$POETRY_VENV/bin/pip install -U pip setuptools \\
    && \$POETRY_VENV/bin/pip install poetry==\$POETRY_VERSION

# Add poetry to PATH
ENV PATH="\${POETRY_VENV}/bin:\${PATH}"

# Set working directory
WORKDIR /app

# Install dependencies including dev dependencies
COPY poetry.lock pyproject.toml ./
RUN poetry config virtualenvs.create false \\
    && poetry install --no-interaction --no-ansi --no-root

# Copy project files
COPY . .

# Start development server
CMD ["poetry", "run", "python", "-m", "${project_name}.main"]
ENDOFFILE

    # Create docker-compose.yml
    cat > "$project_dir/docker-compose.yml" << ENDOFFILE
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - ./data:/app/data
      - ./configs:/app/configs
    env_file:
      - .env
    ports:
      - "8000:8000"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
ENDOFFILE

    # Add Ollama service if enabled
    if [ "$use_ollama" = "true" ]; then
        cat >> "$project_dir/docker-compose.yml" << ENDOFFILE
    depends_on:
      - ollama

  ollama:
    image: ollama/ollama:latest
    volumes:
      - ollama-models:/root/.ollama
    ports:
      - "11434:11434"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11434/api/version"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  ollama-models:
ENDOFFILE
    fi

    # Create docker-compose.dev.yml
    cat > "$project_dir/docker-compose.dev.yml" << ENDOFFILE
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    volumes:
      - .:/app
      - poetry-cache:/opt/.cache
    env_file:
      - .env
    ports:
      - "8000:8000"
      - "5678:5678"  # For debugger
    environment:
      - PYTHONBREAKPOINT=remote-pdb.set_trace
      - REMOTE_PDB_HOST=0.0.0.0
      - REMOTE_PDB_PORT=5678
    command: poetry run python -m ${project_name}.main
ENDOFFILE

    if [ "$use_ollama" = "true" ]; then
        cat >> "$project_dir/docker-compose.dev.yml" << ENDOFFILE
    depends_on:
      - ollama

  ollama:
    image: ollama/ollama:latest
    volumes:
      - ollama-models:/root/.ollama
    ports:
      - "11434:11434"

volumes:
  poetry-cache:
  ollama-models:
ENDOFFILE
    else
        cat >> "$project_dir/docker-compose.dev.yml" << ENDOFFILE

volumes:
  poetry-cache:
ENDOFFILE
    fi

    # Create .dockerignore
    cat > "$project_dir/.dockerignore" << 'ENDOFFILE'
# Git
.git
.gitignore
.github
.gitlab

# Docker
.docker
Dockerfile
Dockerfile.dev
docker-compose.yml
docker-compose.dev.yml

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual Environment
.env
.venv
env/
venv/
ENV/

# IDE
.idea/
.vscode/
*.swp
*.swo

# Testing
.coverage
.pytest_cache/
htmlcov/
.mypy_cache/

# Project specific
data/
!data/.gitkeep
logs/
!logs/.gitkeep
notebooks/
docs/
tests/

# DVC
.dvc/
ENDOFFILE

    # Create scripts for Docker operations
    mkdir -p "$project_dir/scripts/docker"

    # Create build script
    cat > "$project_dir/scripts/docker/build.sh" << ENDOFFILE
#!/usr/bin/env bash
set -euo pipefail

# Build development image
docker-compose -f docker-compose.dev.yml build

# Build production image
docker-compose build
ENDOFFILE

    # Create run script
    cat > "$project_dir/scripts/docker/run.sh" << ENDOFFILE
#!/usr/bin/env bash
set -euo pipefail

# Run development environment
docker-compose -f docker-compose.dev.yml up
ENDOFFILE

    # Create test script
    cat > "$project_dir/scripts/docker/test.sh" << ENDOFFILE
#!/usr/bin/env bash
set -euo pipefail

# Run tests in development container
docker-compose -f docker-compose.dev.yml run --rm app poetry run pytest tests/
ENDOFFILE

    # Make scripts executable
    chmod +x "$project_dir/scripts/docker/build.sh"
    chmod +x "$project_dir/scripts/docker/run.sh"
    chmod +x "$project_dir/scripts/docker/test.sh"

    # Add Docker commands to Makefile
    cat >> "$project_dir/Makefile" << ENDOFFILE

# Docker commands
docker-build:
	./scripts/docker/build.sh

docker-run:
	./scripts/docker/run.sh

docker-test:
	./scripts/docker/test.sh

docker-clean:
	docker-compose down -v
	docker-compose -f docker-compose.dev.yml down -v
ENDOFFILE

    log "SUCCESS" "Docker configuration complete"
}

# Execute only if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ "$#" -lt 4 ]]; then
        echo "Usage: $0 PROJECT_DIR PROJECT_NAME PYTHON_VERSION USE_OLLAMA"
        exit 1
    fi
    setup_docker "$@"
fi
