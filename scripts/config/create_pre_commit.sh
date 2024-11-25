#!/usr/bin/env bash
# create_pre_commit.sh - Create pre-commit configuration file

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../scripts/utils/logging.sh"

create_pre_commit() {
    local project_dir="$1"
    
    log "INFO" "Creating pre-commit config..."
    
    cat > "$project_dir/.pre-commit-config.yaml" << ENDOFFILE
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
ENDOFFILE
    
    log "SUCCESS" "Created pre-commit config"
}

# Execute only if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ "$#" -lt 1 ]]; then
        echo "Usage: $0 PROJECT_DIR"
        exit 1
    fi
    create_pre_commit "$@"
fi
