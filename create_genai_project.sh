#!/usr/bin/env bash
# create_genai_project.sh
# Main script for creating GenAI project structure with all features

set -euo pipefail

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Default values
PROJECT_NAME=""
TEMPLATE="basic"
USE_DOCKER="false"
PYTHON_VERSION="3.11"
USE_SPHINX="false"
USE_GITHUB_ACTIONS="false"
USE_GITLAB_CI="false"
USE_CONDA="false"
LLM_FRAMEWORK="llamaindex"  # llamaindex, langchain, or both
USE_OLLAMA="false"
OLLAMA_MODEL="llama2"
USE_DVC="false"
DVC_REMOTE="s3"  # s3, gcs, azure, or local

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to print usage information
print_usage() {
    cat << EOF
Usage: $(basename "$0") -n PROJECT_NAME [options]

Required:
    -n    Project name

Optional:
    -t    Template type (basic or advanced, default: basic)
    -d    Include Docker setup
    -p    Python version (default: 3.11)
    -s    Include Sphinx documentation
    -g    Include GitHub Actions
    -l    Include GitLab CI
    -c    Use conda environment
    -f    LLM framework (llamaindex, langchain, or both)
    -o    Include Ollama support
    -m    Ollama model (default: llama2)
    -v    Include DVC support
    -r    DVC remote type (s3, gcs, azure, local)

Examples:
    $(basename "$0") -n my_project
    $(basename "$0") -n my_project -d -o -m llama2
    $(basename "$0") -n my_project -t advanced -d -p 3.11 -s -g -o -v -r s3
EOF
}

# Function to log messages
log() {
    local level=$1
    shift
    local message=$*
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")
            echo -e "${BLUE}[${timestamp}] [INFO] ${message}${NC}"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[${timestamp}] [SUCCESS] ${message}${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}[${timestamp}] [WARNING] ${message}${NC}"
            ;;
        "ERROR")
            echo -e "${RED}[${timestamp}] [ERROR] ${message}${NC}"
            ;;
    esac
}

# Function to validate Python version
validate_python_version() {
    local version=$1
    if ! [[ $version =~ ^3\.(8|9|10|11)$ ]]; then
        log "ERROR" "Invalid Python version: $version. Supported versions: 3.8, 3.9, 3.10, 3.11"
        exit 1
    fi
}

# Function to validate project name
validate_project_name() {
    local name=$1
    if ! [[ $name =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
        log "ERROR" "Invalid project name. Must start with a letter and contain only letters, numbers, underscores, or hyphens."
        exit 1
    fi
}

# Function to create basic project structure
create_basic_structure() {
    local project_dir=$1
    
    log "INFO" "Creating basic project structure..."
    
    # Create directory structure
    mkdir -p "$project_dir"/{src,tests,data/{raw,processed},docs,scripts,configs,notebooks}
    mkdir -p "$project_dir/src/$PROJECT_NAME"
    
    # Create initial files
    touch "$project_dir/src/$PROJECT_NAME/__init__.py"
    touch "$project_dir/src/$PROJECT_NAME/main.py"
    touch "$project_dir/tests/__init__.py"
    touch "$project_dir/tests/test_main.py"
    
    # Create README.md
    cat > "$project_dir/README.md" << EOF
# $PROJECT_NAME

## Overview
GenAI project using ${LLM_FRAMEWORK^}.

## Setup
1. Install dependencies: \`make install\`
2. Set up pre-commit hooks: \`make setup-pre-commit\`
3. Run tests: \`make test\`

## Project Structure
\`\`\`
├── src/              # Source code
├── tests/            # Test files
├── data/             # Data files
├── docs/             # Documentation
├── scripts/          # Utility scripts
├── configs/          # Configuration files
└── notebooks/        # Jupyter notebooks
\`\`\`
EOF
    
    create_pyproject_toml "$project_dir"
    create_makefile "$project_dir"
    create_pre_commit_config "$project_dir"
    create_gitignore "$project_dir"
    
    log "SUCCESS" "Basic project structure created"
}

# Function to create pyproject.toml
create_pyproject_toml() {
    local project_dir=$1
    
    log "INFO" "Creating pyproject.toml..."
    
    cat > "$project_dir/pyproject.toml" << EOF
[tool.poetry]
name = "$PROJECT_NAME"
version = "0.1.0"
description = "GenAI project using ${LLM_FRAMEWORK^}"
authors = ["Your Name <your.email@example.com>"]

[tool.poetry.dependencies]
python = "^$PYTHON_VERSION"
pandas = "^2.0.0"
numpy = "^1.24.0"
EOF
    
    # Add framework-specific dependencies
    if [[ "$LLM_FRAMEWORK" == "llamaindex" || "$LLM_FRAMEWORK" == "both" ]]; then
        cat >> "$project_dir/pyproject.toml" << EOF
llama-index = "^0.9.0"
EOF
    fi
    
    if [[ "$LLM_FRAMEWORK" == "langchain" || "$LLM_FRAMEWORK" == "both" ]]; then
        cat >> "$project_dir/pyproject.toml" << EOF
langchain = "^0.1.0"
EOF
    fi
    
    # Add optional dependencies based on flags
    if [ "$USE_OLLAMA" = "true" ]; then
        echo 'httpx = "^0.24.0"' >> "$project_dir/pyproject.toml"
    fi
    
    if [ "$USE_DVC" = "true" ]; then
        echo 'dvc = "^3.0.0"' >> "$project_dir/pyproject.toml"
        case "$DVC_REMOTE" in
            "s3") echo 'dvc-s3 = "^2.0.0"' >> "$project_dir/pyproject.toml" ;;
            "gcs") echo 'dvc-gs = "^2.0.0"' >> "$project_dir/pyproject.toml" ;;
            "azure") echo 'dvc-azure = "^2.0.0"' >> "$project_dir/pyproject.toml" ;;
        esac
    fi
    
    # Add development dependencies
    cat >> "$project_dir/pyproject.toml" << EOF

[tool.poetry.group.dev.dependencies]
pytest = "^7.4.0"
black = "^23.0.0"
isort = "^5.12.0"
mypy = "^1.5.0"
pylint = "^2.17.0"
pytest-cov = "^4.1.0"
pre-commit = "^3.3.0"

[build-system]
requires = ["poetry-core>=1.0.0"]
build-backend = "poetry.core.masonry.api"

[tool.black]
line-length = 88
target-version = ['py311']

[tool.isort]
profile = "black"
multi_line_output = 3

[tool.mypy]
python_version = "$PYTHON_VERSION"
strict = true
ignore_missing_imports = true

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
addopts = "-v --cov=src --cov-report=term-missing"
EOF
    
    log "SUCCESS" "Created pyproject.toml"
}

# Function to create Makefile
create_makefile() {
    local project_dir=$1
    
    log "INFO" "Creating Makefile..."
    
    cat > "$project_dir/Makefile" << EOF
.PHONY: install test lint format clean setup-pre-commit

install:
	poetry install

test:
	poetry run pytest tests/ --cov=src/ --cov-report=term-missing

lint:
	poetry run black src/ tests/ --check
	poetry run isort src/ tests/ --check
	poetry run pylint src/ tests/
	poetry run mypy src/ tests/

format:
	poetry run black src/ tests/
	poetry run isort src/ tests/

clean:
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type f -name "*.pyd" -delete
	find . -type f -name ".coverage" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	find . -type d -name "*.egg" -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	find . -type d -name ".mypy_cache" -exec rm -rf {} +

setup-pre-commit:
	poetry run pre-commit install
EOF
    
    # Add DVC commands if enabled
    if [ "$USE_DVC" = "true" ]; then
        cat >> "$project_dir/Makefile" << EOF

dvc-init:
	dvc init
	dvc remote add -d myremote ${DVC_REMOTE}://my-bucket/path

dvc-push:
	dvc push

dvc-pull:
	dvc pull
EOF
    fi
    
    # Add Ollama commands if enabled
    if [ "$USE_OLLAMA" = "true" ]; then
        cat >> "$project_dir/Makefile" << EOF

ollama-start:
	ollama serve

ollama-pull:
	ollama pull ${OLLAMA_MODEL}

ollama-run:
	python src/${PROJECT_NAME}/models/run_ollama.py
EOF
    fi
    
    log "SUCCESS" "Created Makefile"
}

# Function to create pre-commit config
create_pre_commit_config() {
    local project_dir=$1
    
    log "INFO" "Creating pre-commit config..."
    
    cat > "$project_dir/.pre-commit-config.yaml" << EOF
repos:
-   repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
    -   id: trailing-whitespace
    -   id: end-of-file-fixer
    -   id: check-yaml
    -   id: check-added-large-files

-   repo: https://github.com/psf/black
    rev: 23.3.0
    hooks:
    -   id: black

-   repo: https://github.com/PyCQA/isort
    rev: 5.12.0
    hooks:
    -   id: isort

-   repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.3.0
    hooks:
    -   id: mypy
        additional_dependencies: [types-all]

-   repo: https://github.com/PyCQA/pylint
    rev: v2.17.4
    hooks:
    -   id: pylint
EOF
    
    log "SUCCESS" "Created pre-commit config"
}

# Function to create .gitignore
create_gitignore() {
    local project_dir=$1
    
    log "INFO" "Creating .gitignore..."
    
    cat > "$project_dir/.gitignore" << EOF
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

# Distribution
dist/
build/

# Misc
.DS_Store
*.log
EOF
    
    # Add DVC-specific ignores
    if [ "$USE_DVC" = "true" ]; then
        cat >> "$project_dir/.gitignore" << EOF

# DVC
/data
/models
*.dvc
.dvc/cache
.dvc/tmp
.dvc/plots
EOF
    fi
    
    log "SUCCESS" "Created .gitignore"
}

# Function to set up Docker if enabled
setup_docker() {
    local project_dir=$1
    
    log "INFO" "Setting up Docker..."
    
    # Create Dockerfile
    cat > "$project_dir/Dockerfile" << EOF
FROM python:${PYTHON_VERSION}-slim

WORKDIR /app

# Install poetry
RUN pip install poetry

# Copy poetry files
COPY pyproject.toml poetry.lock ./

# Install dependencies
RUN poetry config virtualenvs.create false \
    && poetry install --no-dev --no-interaction --no-ansi

# Copy project files
COPY src/ ./src/
COPY configs/ ./configs/

# Set environment variables
ENV PYTHONPATH=/app/src
ENV PYTHONUNBUFFERED=1

# Run the application
CMD ["python", "-m", "$PROJECT_NAME.main"]
EOF
    
    # Create docker-compose.yml
    cat > "$project_dir/docker-compose.yml" << EOF
version: '3.8'

services:
  app:
    build: .
    volumes:
      - ./data:/app/data
      - ./configs:/app/configs
    env_file:
      - .env
EOF
    
    # Add Ollama service if enabled
    if [ "$USE_OLLAMA" = "true" ]; then
        cat >> "$project_dir/docker-compose.yml" << EOF
    depends_on:
      - ollama

  ollama:
    image: ollama/ollama:latest
    volumes:
      - ollama-models:/root/.ollama
    ports:
      - "11434:11434"

volumes:
  ollama-models:
EOF
    fi
    
    log "SUCCESS" "Docker setup complete"
}

# Parse command line arguments
while getopts "n:t:dp:sglcf:om:vr:" opt; do
    case $opt in
        n) PROJECT_NAME="$OPTARG";;
        t) TEMPLATE="$OPTARG";;
        d) USE_DOCKER="true";;
        p) PYTHON_VERSION="$OPTARG";;
        s) USE_SPHINX="true";;
        g) USE_GITHUB_ACTIONS="true";;
        l) USE_GITLAB_CI="true";;
        c) USE_CONDA="true";;
        f) LLM_FRAMEWORK="$OPTARG";;
        o) USE_OLLAMA="true";;
        m) OLLAMA_MODEL="$OPTARG";;
        v) USE_DVC="true";;
        r) DVC_REMOTE="$OPTARG";;
        ?) print_usage; exit 1;;
    esac
done

# Validate required arguments
if [ -z "$PROJECT_NAME" ]; then
    log "ERROR" "Project name is required"
    print_usage
    exit 1
fi

# Validate project name
validate_project_name "$PROJECT_NAME"

# Validate Python version
validate_python_version "$PYTHON_VERSION"

# Create project
log "INFO" "Creating project: $PROJECT_NAME"

# Create basic structure
create_basic_structure "$PROJECT_NAME"

# Set up Docker if enabled
if [ "$USE_DOCKER" = "true" ]; then
    setup_docker "$PROJECT_NAME"
fi

# Set up Sphinx documentation if enabled
if [ "$USE_SPHINX" = "true" ]; then
    setup_sphinx "$PROJECT_NAME"
fi

# Set up GitHub Actions if enabled
if [ "$USE_GITHUB_ACTIONS" = "true" ]; then
    setup_github_actions "$PROJECT_NAME"
fi

# Set up GitLab CI if enabled
if [ "$USE_GITLAB_CI" = "true" ]; then
    setup_gitlab_ci "$PROJECT_NAME"
fi

# Set up Ollama if enabled
if [ "$USE_OLLAMA" = "true" ]; then
    setup_ollama "$PROJECT_NAME" "$OLLAMA_MODEL"
fi

# Set up DVC if enabled
if [ "$USE_DVC" = "true" ]; then
    setup_dvc "$PROJECT_NAME" "$DVC_REMOTE"
fi

# Function to set up Sphinx documentation
setup_sphinx() {
    local project_dir=$1
    
    log "INFO" "Setting up Sphinx documentation..."
    
    mkdir -p "$project_dir/docs/source"
    
    # Create conf.py
    cat > "$project_dir/docs/source/conf.py" << EOF
project = '$PROJECT_NAME'
copyright = '$(date +%Y), Your Name'
author = 'Your Name'

extensions = [
    'sphinx.ext.autodoc',
    'sphinx.ext.napoleon',
    'sphinx.ext.viewcode',
    'sphinx.ext.githubpages',
]

templates_path = ['_templates']
exclude_patterns = []
html_theme = 'sphinx_rtd_theme'
EOF
    
    # Create index.rst
    cat > "$project_dir/docs/source/index.rst" << EOF
Welcome to $PROJECT_NAME's documentation!
=======================================

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   api
   tutorials
   examples

Indices and tables
==================

* :ref:\`genindex\`
* :ref:\`modindex\`
* :ref:\`search\`
EOF
    
    # Add docs building to Makefile
    echo '
docs:
	cd docs && make html' >> "$project_dir/Makefile"
    
    log "SUCCESS" "Sphinx documentation setup complete"
}

# Function to set up GitHub Actions
setup_github_actions() {
    local project_dir=$1
    
    log "INFO" "Setting up GitHub Actions..."
    
    mkdir -p "$project_dir/.github/workflows"
    
    cat > "$project_dir/.github/workflows/ci.yml" << EOF
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ['$PYTHON_VERSION']

    steps:
    - uses: actions/checkout@v2
    - name: Set up Python \${{ matrix.python-version }}
      uses: actions/setup-python@v2
      with:
        python-version: \${{ matrix.python-version }}
    
    - name: Install Poetry
      run: |
        curl -sSL https://install.python-poetry.org | python3 -
    
    - name: Install dependencies
      run: poetry install
    
    - name: Run tests
      run: poetry run pytest tests/
    
    - name: Run linting
      run: |
        poetry run black --check src/ tests/
        poetry run isort --check-only src/ tests/
        poetry run pylint src/ tests/
        poetry run mypy src/ tests/
EOF
    
    log "SUCCESS" "GitHub Actions setup complete"
}

# Function to set up GitLab CI
setup_gitlab_ci() {
    local project_dir=$1
    
    log "INFO" "Setting up GitLab CI..."
    
    cat > "$project_dir/.gitlab-ci.yml" << EOF
image: python:$PYTHON_VERSION

stages:
  - test
  - lint
  - build

before_script:
  - curl -sSL https://install.python-poetry.org | python3 -
  - poetry install

test:
  stage: test
  script:
    - poetry run pytest tests/ --cov=src/

lint:
  stage: lint
  script:
    - poetry run black --check src/ tests/
    - poetry run isort --check-only src/ tests/
    - poetry run pylint src/ tests/
    - poetry run mypy src/ tests/

build:
  stage: build
  script:
    - poetry build
  artifacts:
    paths:
      - dist/
EOF
    
    log "SUCCESS" "GitLab CI setup complete"
}

# Function to set up Ollama
setup_ollama() {
    local project_dir=$1
    local model=$2
    
    log "INFO" "Setting up Ollama integration..."
    
    mkdir -p "$project_dir/src/$PROJECT_NAME/ollama"
    
    # Create Ollama client utility
    cat > "$project_dir/src/$PROJECT_NAME/ollama/client.py" << EOF
"""Ollama client utilities."""
from typing import Dict, List, Optional, Union
import httpx

class OllamaClient:
    """Client for interacting with Ollama API."""
    
    def __init__(self, base_url: str = "http://localhost:11434", model: str = "$model"):
        """Initialize Ollama client.
        
        Args:
            base_url: Ollama API base URL
            model: Model name to use
        """
        self.base_url = base_url.rstrip("/")
        self.model = model
    
    def generate(
        self,
        prompt: str,
        system: Optional[str] = None,
        template: Optional[str] = None,
        context: Optional[List[int]] = None,
        options: Optional[Dict] = None,
    ) -> str:
        """Generate completion from Ollama.
        
        Args:
            prompt: Input prompt
            system: System prompt
            template: Custom prompt template
            context: Previous context
            options: Additional model options
            
        Returns:
            Generated text
        """
        url = f"{self.base_url}/api/generate"
        
        payload = {
            "model": self.model,
            "prompt": prompt,
        }
        
        if system:
            payload["system"] = system
        if template:
            payload["template"] = template
        if context:
            payload["context"] = context
        if options:
            payload["options"] = options
            
        response = httpx.post(url, json=payload)
        response.raise_for_status()
        
        return response.json()["response"]

EOF
    
    # Create example usage script
    cat > "$project_dir/src/$PROJECT_NAME/models/run_ollama.py" << EOF
"""Example usage of Ollama client."""
from ..ollama.client import OllamaClient

def main():
    """Run example Ollama interaction."""
    client = OllamaClient(model="$model")
    
    response = client.generate(
        prompt="Hello, how are you?",
        system="You are a helpful assistant."
    )
    
    print(f"Response: {response}")

if __name__ == "__main__":
    main()
EOF
    
    log "SUCCESS" "Ollama integration setup complete"
}

# Function to set up DVC
setup_dvc() {
    local project_dir=$1
    local remote_type=$2
    
    log "INFO" "Setting up DVC..."
    
    # Initialize DVC
    (cd "$project_dir" && dvc init -q)
    
    # Configure remote storage
    case "$remote_type" in
        "s3")
            echo 'dvc remote add -d myremote s3://my-bucket/path' >> "$project_dir/.dvc/config"
            ;;
        "gcs")
            echo 'dvc remote add -d myremote gs://my-bucket/path' >> "$project_dir/.dvc/config"
            ;;
        "azure")
            echo 'dvc remote add -d myremote azure://container/path' >> "$project_dir/.dvc/config"
            ;;
        "local")
            echo 'dvc remote add -d myremote /path/to/remote' >> "$project_dir/.dvc/config"
            ;;
    esac
    
    # Create example DVC pipeline
    cat > "$project_dir/dvc.yaml" << EOF
stages:
  prepare:
    cmd: python src/$PROJECT_NAME/data/prepare.py
    deps:
      - data/raw
    outs:
      - data/processed
  
  train:
    cmd: python src/$PROJECT_NAME/models/train.py
    deps:
      - data/processed
    outs:
      - models/model.pkl
    metrics:
      - metrics/training_metrics.json:
          cache: false
EOF
    
    log "SUCCESS" "DVC setup complete"
}

# Print success message and next steps
log "SUCCESS" "Project $PROJECT_NAME created successfully!"
echo -e "${BLUE}Next steps:${NC}"
echo "1. cd $PROJECT_NAME"
echo "2. git init"
echo "3. poetry install"
echo "4. make setup-pre-commit"
if [ "$USE_SPHINX" = "true" ]; then
    echo "5. make docs"
fi
if [ "$USE_OLLAMA" = "true" ]; then
    echo "6. make ollama-pull"
fi
if [ "$USE_DVC" = "true" ]; then
    echo "7. Configure DVC remote storage in .dvc/config"
fi