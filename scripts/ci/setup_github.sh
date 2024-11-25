#!/usr/bin/env bash
# setup_github.sh - Set up GitHub Actions workflows

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../scripts/utils/logging.sh"

setup_github_actions() {
    local project_dir="$1"
    local python_version="$2"
    
    log "INFO" "Setting up GitHub Actions..."
    
    # Create GitHub Actions directory
    mkdir -p "$project_dir/.github/workflows"
    
    # Create main CI workflow
    cat > "$project_dir/.github/workflows/ci.yml" << ENDOFFILE
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
        python-version: ['$python_version']

    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python \${{ matrix.python-version }}
      uses: actions/setup-python@v4
      with:
        python-version: \${{ matrix.python-version }}
    
    - name: Install Poetry
      uses: snok/install-poetry@v1
      with:
        version: 1.7.1
        virtualenvs-create: true
        virtualenvs-in-project: true
    
    - name: Load cached venv
      id: cached-poetry-dependencies
      uses: actions/cache@v3
      with:
        path: .venv
        key: venv-\${{ runner.os }}-\${{ hashFiles('**/poetry.lock') }}
    
    - name: Install dependencies
      if: steps.cached-poetry-dependencies.outputs.cache-hit != 'true'
      run: poetry install --no-interaction --no-root
    
    - name: Install project
      run: poetry install --no-interaction
    
    - name: Run tests
      run: poetry run pytest tests/ --cov=src/ --cov-report=xml
    
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.xml
        fail_ci_if_error: true
ENDOFFILE

    # Create dependency review workflow
    cat > "$project_dir/.github/workflows/dependency-review.yml" << ENDOFFILE
name: Dependency Review
on: [pull_request]

permissions:
  contents: read

jobs:
  dependency-review:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v3
      
      - name: Dependency Review
        uses: actions/dependency-review-action@v3
ENDOFFILE

    # Create security scanning workflow
    cat > "$project_dir/.github/workflows/security.yml" << ENDOFFILE
name: Security Scan

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 0 * * 0'  # Run weekly

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '$python_version'
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install bandit safety
    
    - name: Run Bandit
      run: bandit -r src/ -c pyproject.toml
    
    - name: Run Safety
      run: safety check
ENDOFFILE

    # Create release workflow
    cat > "$project_dir/.github/workflows/release.yml" << ENDOFFILE
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '$python_version'
    
    - name: Install Poetry
      uses: snok/install-poetry@v1
      with:
        version: 1.7.1
    
    - name: Build project
      run: poetry build
    
    - name: Create Release
      uses: softprops/action-gh-release@v1
      with:
        files: |
          dist/*.whl
          dist/*.tar.gz
        generate_release_notes: true
      env:
        GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
ENDOFFILE

    log "SUCCESS" "Created GitHub Actions workflows"
}

# Execute only if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ "$#" -lt 2 ]]; then
        echo "Usage: $0 PROJECT_DIR PYTHON_VERSION"
        exit 1
    fi
    setup_github_actions "$@"
fi
