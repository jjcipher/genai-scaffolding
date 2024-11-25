#!/usr/bin/env bash
# create_pyproject.sh - Create Poetry configuration file

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../scripts/utils/logging.sh"

create_pyproject() {
    local project_dir="$1"
    local project_name="$2"
    local python_version="$3"
    local framework="$4"
    local use_ollama="$5"
    local use_dvc="$6"
    local dvc_remote="$7"

    log "INFO" "Creating pyproject.toml..."

    # Convert first letter of framework to uppercase
    framework_cap="$(tr '[:lower:]' '[:upper:]' <<< ${framework:0:1})${framework:1}"

    # Create temporary file for dependencies
    local temp_deps=$(mktemp)
    
    # Write base dependencies
    cat > "$temp_deps" << EOF
python = "^$python_version"
pandas = "^2.0.0"
numpy = "^1.24.0"
EOF

    # Add framework-specific dependencies
    if [[ "$framework" == "llamaindex" || "$framework" == "both" ]]; then
        echo 'llama-index = "^0.9.0"' >> "$temp_deps"
    fi

    if [[ "$framework" == "langchain" || "$framework" == "both" ]]; then
        echo 'langchain = "^0.1.0"' >> "$temp_deps"
    fi

    # Add optional dependencies
    if [ "$use_ollama" = "true" ]; then
        echo 'httpx = "^0.24.0"' >> "$temp_deps"
        echo 'pytest-asyncio = "^0.21.0"' >> "$temp_deps"
    fi

    if [ "$use_dvc" = "true" ]; then
        echo 'dvc = "^3.0.0"' >> "$temp_deps"
        case "$dvc_remote" in
            "s3") echo 'dvc-s3 = "^2.0.0"' >> "$temp_deps" ;;
            "gcs") echo 'dvc-gs = "^2.0.0"' >> "$temp_deps" ;;
            "azure") echo 'dvc-azure = "^2.0.0"' >> "$temp_deps" ;;
        esac
    fi

    # Create the complete pyproject.toml using dependencies from temp file
    cat > "$project_dir/pyproject.toml" << EOF
[tool.poetry]
name = "$project_name"
version = "0.1.0"
description = "GenAI project using $framework_cap"
authors = ["Your Name <your.email@example.com>"]

[tool.poetry.dependencies]
$(cat "$temp_deps")

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
python_version = "$python_version"
strict = true
ignore_missing_imports = true

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
addopts = "-v --cov=src --cov-report=term-missing"
EOF

    # Clean up temp file
    rm "$temp_deps"

    log "SUCCESS" "Created pyproject.toml"
}

# Execute only if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ "$#" -lt 7 ]]; then
        echo "Usage: $0 PROJECT_DIR PROJECT_NAME PYTHON_VERSION FRAMEWORK USE_OLLAMA USE_DVC DVC_REMOTE"
        exit 1
    fi
    create_pyproject "$@"
fi
