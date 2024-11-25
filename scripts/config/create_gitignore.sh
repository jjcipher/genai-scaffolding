#!/usr/bin/env bash
# create_gitignore.sh - Create .gitignore file for the project

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../scripts/utils/logging.sh"

create_gitignore() {
    local project_dir="$1"
    local use_dvc="$2"
    
    log "INFO" "Creating .gitignore..."
    
    # Create basic .gitignore content
    cat > "$project_dir/.gitignore" << 'ENDOFFILE'
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
ENDOFFILE
    
    # Add DVC-specific ignores if enabled
    if [ "$use_dvc" = "true" ]; then
        cat >> "$project_dir/.gitignore" << ENDOFFILE

# DVC
/data
/models
*.dvc
.dvc/cache
.dvc/tmp
.dvc/plots
ENDOFFILE
    fi
    
    log "SUCCESS" "Created .gitignore"
}

# Execute only if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ "$#" -lt 2 ]]; then
        echo "Usage: $0 PROJECT_DIR USE_DVC"
        exit 1
    fi
    create_gitignore "$@"
fi
