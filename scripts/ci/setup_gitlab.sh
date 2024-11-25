#!/usr/bin/env bash
# setup_gitlab.sh - Set up GitLab CI configuration

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../scripts/utils/logging.sh"

setup_gitlab_ci() {
    local project_dir="$1"
    local python_version="$2"
    
    log "INFO" "Setting up GitLab CI..."
    
    cat > "$project_dir/.gitlab-ci.yml" << ENDOFFILE
image: python:${python_version}

variables:
  PIP_CACHE_DIR: "\$CI_PROJECT_DIR/.pip-cache"
  POETRY_VERSION: "1.7.1"

cache:
  paths:
    - .pip-cache/
    - .venv/
    - .coverage
    - coverage.xml

stages:
  - setup
  - test
  - lint
  - security
  - build
  - deploy

before_script:
  - pip install poetry==\$POETRY_VERSION
  - poetry config virtualenvs.in-project true
  - poetry install

# Setup stage
setup:
  stage: setup
  script:
    - poetry install
  artifacts:
    paths:
      - .venv/
    expire_in: 1 hour

# Test stage
test:
  stage: test
  coverage: '/TOTAL.+ ([0-9]{1,3}%)/'
  script:
    - poetry run pytest tests/ --cov=src/ --cov-report=term-missing --cov-report=xml
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
    paths:
      - coverage.xml

# Lint stage
lint:
  stage: lint
  script:
    - poetry run black --check src/ tests/
    - poetry run isort --check-only src/ tests/
    - poetry run pylint src/ tests/
    - poetry run mypy src/ tests/

# Security stage
security:
  stage: security
  script:
    - pip install bandit safety
    - poetry run bandit -r src/
    - poetry run safety check

# Build stage
build:
  stage: build
  script:
    - poetry build
  artifacts:
    paths:
      - dist/
    expire_in: 1 week

# Deploy stage (example for PyPI)
deploy:
  stage: deploy
  script:
    - poetry config pypi-token.pypi \$PYPI_TOKEN
    - poetry publish
  only:
    - tags
  when: manual

# Pages for documentation
pages:
  stage: deploy
  script:
    - poetry install
    - cd docs && poetry run make html
    - mv build/html/ ../public/
  artifacts:
    paths:
      - public
  only:
    - main

include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
ENDOFFILE

    # Create GitLab CI configuration directory
    mkdir -p "$project_dir/.gitlab"
    
    # Create merge request template
    cat > "$project_dir/.gitlab/merge_request_templates/default.md" << ENDOFFILE
## What does this MR do?

<!-- Briefly describe what this MR is about -->

## Related issues

<!-- Link related issues below. -->

## Checklist

- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] I have added necessary documentation
- [ ] I have run \`make test\` and all tests pass
- [ ] I have run \`make lint\` and there are no issues
- [ ] I have run \`make format\` to format the code
ENDOFFILE

    log "SUCCESS" "Created GitLab CI configuration"
}

# Execute only if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ "$#" -lt 2 ]]; then
        echo "Usage: $0 PROJECT_DIR PYTHON_VERSION"
        exit 1
    fi
    setup_gitlab_ci "$@"
fi
