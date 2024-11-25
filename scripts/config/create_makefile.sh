#!/usr/bin/env bash
# create_makefile.sh - Create Makefile with project commands

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../scripts/utils/logging.sh"

create_makefile() {
    local project_dir="$1"
    local project_name="$2"
    local use_dvc="$3"
    local use_ollama="$4"
    local ollama_model="$5"
    
    log "INFO" "Creating Makefile..."
    
    # Create basic Makefile content
    cat > "$project_dir/Makefile" << ENDOFFILE
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
ENDOFFILE

    # Add DVC commands if enabled
    if [ "$use_dvc" = "true" ]; then
        cat >> "$project_dir/Makefile" << ENDOFFILE

dvc-init:
	dvc init
	dvc remote add -d myremote \${DVC_REMOTE}://my-bucket/path

dvc-push:
	dvc push

dvc-pull:
	dvc pull
ENDOFFILE
    fi
    
    log "SUCCESS" "Created Makefile"
}

# Execute only if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ "$#" -lt 5 ]]; then
        echo "Usage: $0 PROJECT_DIR PROJECT_NAME USE_DVC USE_OLLAMA OLLAMA_MODEL"
        exit 1
    fi
    create_makefile "$@"
fi
