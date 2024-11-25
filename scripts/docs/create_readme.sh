#!/usr/bin/env bash
# create_readme.sh - Create README.md for GenAI projects

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../scripts/utils/logging.sh"

create_readme() {
    local project_dir="$1"
    local project_name="$2"
    local framework="$3"
    
    log "INFO" "Creating README.md..."
    
    # Convert first letter of framework to uppercase
    framework_cap="$(tr '[:lower:]' '[:upper:]' <<< ${framework:0:1})${framework:1}"
    
    cat > "$project_dir/README.md" << ENDOFFILE
# ${project_name}

![Python Version](https://img.shields.io/badge/python-3.8%20|%203.9%20|%203.10%20|%203.11-blue)
![Poetry](https://img.shields.io/badge/poetry-managed-blue)
[![Documentation](https://img.shields.io/badge/docs-sphinx-green.svg)](docs/)
[![Code style: black](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)
[![Imports: isort](https://img.shields.io/badge/%20imports-isort-%231674b1)](https://pycqa.github.io/isort/)
[![Security: bandit](https://img.shields.io/badge/security-bandit-yellow.svg)](https://github.com/PyCQA/bandit)
[![Pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Overview
GenAI project using ${framework_cap} for building intelligent applications.

## Features
- Poetry for dependency management
- Pre-commit hooks for code quality
- Pytest for testing with coverage reporting
- Type checking with mypy
- Code formatting with black and isort
- Linting with pylint
- Comprehensive documentation with Sphinx
ENDOFFILE

    # Add framework-specific information
    case "$framework" in
        "llamaindex")
            cat >> "$project_dir/README.md" << ENDOFFILE

## LlamaIndex Integration
This project leverages LlamaIndex for:
- Document processing and indexing
- Semantic search and retrieval
- Question-answering over documents
- Custom index structures and query engines
ENDOFFILE
            ;;
        "langchain")
            cat >> "$project_dir/README.md" << ENDOFFILE

## LangChain Integration
This project utilizes LangChain for:
- Building complex LLM pipelines
- Document processing and chunking
- Chains and agents implementation
- Memory management and state handling
ENDOFFILE
            ;;
        "both")
            cat >> "$project_dir/README.md" << ENDOFFILE

## Framework Integration
This project combines the power of both LlamaIndex and LangChain:

### LlamaIndex Features
- Document processing and indexing
- Semantic search and retrieval
- Question-answering over documents
- Custom index structures

### LangChain Features
- Complex LLM pipelines
- Agent-based interactions
- Memory management
- Chain composition
ENDOFFILE
            ;;
    esac

    # Add project structure
    cat >> "$project_dir/README.md" << ENDOFFILE

## Project Structure
\`\`\`
├── src/              # Source code
│   └── ${project_name}/    # Main package
├── tests/            # Test files
├── data/             # Data files
│   ├── raw/          # Raw data
│   └── processed/    # Processed data
├── docs/             # Documentation
├── scripts/          # Utility scripts
├── configs/          # Configuration files
└── notebooks/        # Jupyter notebooks
\`\`\`

## Installation

### Poetry (Recommended)

1. Install Poetry:
   \`\`\`bash
   curl -sSL https://install.python-poetry.org | python3 -
   \`\`\`

2. Install dependencies:
   \`\`\`bash
   poetry install
   \`\`\`

### Docker

1. Build the image:
   \`\`\`bash
   docker-compose build
   \`\`\`

2. Run the container:
   \`\`\`bash
   docker-compose up
   \`\`\`

## Development

1. Set up pre-commit hooks:
   \`\`\`bash
   make setup-pre-commit
   \`\`\`

2. Run tests:
   \`\`\`bash
   make test
   \`\`\`

3. Format code:
   \`\`\`bash
   make format
   \`\`\`

4. Run linting:
   \`\`\bash
   make lint
   \`\`\`

5. Build documentation:
   \`\`\`bash
   make docs-build
   \`\`\`

## Available Commands

\`\`\`bash
make install          # Install dependencies
make test            # Run tests
make format          # Format code
make lint            # Run linters
make clean           # Clean build artifacts
make docs-build      # Build documentation
make docs-serve      # Serve documentation locally
\`\`\`

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
ENDOFFILE

    log "SUCCESS" "Created README.md"
}

# Execute only if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ "$#" -lt 3 ]]; then
        echo "Usage: $0 PROJECT_DIR PROJECT_NAME FRAMEWORK"
        exit 1
    fi
    create_readme "$@"
fi
