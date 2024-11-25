#!/usr/bin/env bash
# create_genai_project.sh - Main script for creating GenAI project structure

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utility scripts
source "${SCRIPT_DIR}/scripts/utils/logging.sh"

# Default values
PROJECT_NAME=""
TEMPLATE="basic"
USE_DOCKER="false"
PYTHON_VERSION="3.11"
USE_SPHINX="false"
USE_GITHUB_ACTIONS="false"
USE_GITLAB_CI="false"
USE_CONDA="false"
LLM_FRAMEWORK="llamaindex"
USE_OLLAMA="false"
OLLAMA_MODEL="llama2"
USE_DVC="false"
DVC_REMOTE="s3"

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
EOF
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

# Create project directory
PROJECT_DIR="$PWD/$PROJECT_NAME"
if [ -d "$PROJECT_DIR" ]; then
    log "ERROR" "Directory $PROJECT_DIR already exists"
    exit 1
fi

# Create basic directory structure
log "INFO" "Creating basic project structure..."
mkdir -p "$PROJECT_DIR"/{src,tests,data/{raw,processed},docs,scripts,configs,notebooks}
mkdir -p "$PROJECT_DIR/src/$PROJECT_NAME"

# Create initial files
touch "$PROJECT_DIR/src/$PROJECT_NAME/__init__.py"
touch "$PROJECT_DIR/src/$PROJECT_NAME/main.py"
touch "$PROJECT_DIR/tests/__init__.py"
touch "$PROJECT_DIR/tests/test_main.py"

# Create configuration files
bash "${SCRIPT_DIR}/scripts/config/create_pyproject.sh" "$PROJECT_DIR" "$PROJECT_NAME" "$PYTHON_VERSION" "$LLM_FRAMEWORK" "$USE_OLLAMA" "$USE_DVC" "$DVC_REMOTE"
bash "${SCRIPT_DIR}/scripts/config/create_makefile.sh" "$PROJECT_DIR" "$PROJECT_NAME" "$USE_DVC" "$USE_OLLAMA" "$OLLAMA_MODEL"
bash "${SCRIPT_DIR}/scripts/config/create_pre_commit.sh" "$PROJECT_DIR"
bash "${SCRIPT_DIR}/scripts/config/create_gitignore.sh" "$PROJECT_DIR" "$USE_DVC"

# Create documentation
bash "${SCRIPT_DIR}/scripts/docs/create_readme.sh" "$PROJECT_DIR" "$PROJECT_NAME" "$LLM_FRAMEWORK"

# Set up additional features based on flags
if [ "$USE_DOCKER" = "true" ]; then
    bash "${SCRIPT_DIR}/scripts/docker/setup_docker.sh" "$PROJECT_DIR" "$PROJECT_NAME" "$PYTHON_VERSION" "$USE_OLLAMA"
fi

if [ "$USE_SPHINX" = "true" ]; then
    bash "${SCRIPT_DIR}/scripts/docs/setup_sphinx.sh" "$PROJECT_DIR" "$PROJECT_NAME"
fi

if [ "$USE_GITHUB_ACTIONS" = "true" ]; then
    bash "${SCRIPT_DIR}/scripts/ci/setup_github.sh" "$PROJECT_DIR" "$PYTHON_VERSION"
fi

if [ "$USE_GITLAB_CI" = "true" ]; then
    bash "${SCRIPT_DIR}/scripts/ci/setup_gitlab.sh" "$PROJECT_DIR" "$PYTHON_VERSION"
fi

if [ "$USE_OLLAMA" = "true" ]; then
    bash "${SCRIPT_DIR}/scripts/llm/setup_ollama.sh" "$PROJECT_DIR" "$PROJECT_NAME" "$OLLAMA_MODEL"
fi

if [ "$USE_DVC" = "true" ]; then
    bash "${SCRIPT_DIR}/scripts/versioning/setup_dvc.sh" "$PROJECT_DIR" "$DVC_REMOTE"
fi

# Initialize git repository
cd "$PROJECT_DIR" || exit 1
git init
git add .
git commit -m "Initial commit: Project scaffolding"

# Print success message and next steps
log "SUCCESS" "Project $PROJECT_NAME created successfully!"
log "INFO" "Next steps:"

# Initialize step counter
step=1

# Base steps
echo "${step}. cd $PROJECT_NAME"
step=$((step + 1))
echo "${step}. poetry install"
step=$((step + 1))
echo "${step}. make setup-pre-commit"
step=$((step + 1))

# Sphinx documentation
if [ "$USE_SPHINX" = "true" ]; then
    echo "${step}. make docs"
    step=$((step + 1))
fi

# Ollama setup
if [ "$USE_OLLAMA" = "true" ]; then
    echo "${step}. make ollama-start"
    step=$((step + 1))
    echo "${step}. In a new terminal:"
    echo "   cd $PROJECT_NAME"
    echo "   make ollama-pull"
    step=$((step + 1))
fi

# DVC setup
if [ "$USE_DVC" = "true" ]; then
    echo "${step}. Configure DVC remote storage in .dvc/config"
fi
