# GenAI Project Scaffolding Tool

A comprehensive scaffolding tool for creating GenAI (Generative AI) projects. Sets up complete project structures with LlamaIndex, LangChain, Ollama integration, and advanced MLOps features including DVC for experiment tracking.

## Features

### 🚀 Core Features
- **Multiple Framework Support**
  - LlamaIndex integration
  - LangChain setup
  - Ollama integration
  - Arize Phoenix integration

### 📁 Project Structure
- Standardized directory layout
- Source code organization
- Test framework setup
- Documentation templates
- Configuration management
- Data versioning structure

### 🛠 Development Tools
- **Package Management**
  - Poetry for dependency management
  - Virtual environment handling
  - Lock file management

- **Code Quality**
  - Pre-commit hooks configuration
  - Black code formatting
  - isort import sorting
  - pylint code analysis
  - mypy type checking

### 🔄 MLOps Integration
- **Data Version Control (DVC)**
  - Experiment tracking
  - Pipeline definitions
  - Remote storage configuration (S3, GCS, Azure)
  - Metric tracking and comparison

- **Docker Support**
  - Development containers
  - Production-ready configurations
  - Multi-service setup with docker-compose

### 🧪 Testing & Quality Assurance
- pytest setup
- Coverage reporting
- Test data management
- CI/CD configurations

## Installation

### Manual Installation
```bash
# Make the script executable
chmod +x create_genai_project.sh

# Optional: Add to your PATH
export PATH="$PATH:/path/to/genai-scaffold"
```

## Usage

### Basic Usage
```bash
# Create a new project with default settings
create-genai-project -n my_project

# Create a project with Docker support
create-genai-project -n my_project -d

# Create a project with Ollama integration
create-genai-project -n my_project -o -m llama2
```

### Advanced Usage
```bash
# Create a full-featured project
create-genai-project -n my_project \
    -t advanced \            # Advanced template
    -d \                    # Include Docker
    -p 3.11 \              # Python version
    -s \                    # Include Sphinx docs
    -g \                    # GitHub Actions
    -l \                    # GitLab CI
    -c \                    # Use conda
    -f langchain \         # LLM framework
    -o \                    # Include Ollama
    -m llama2 \            # Ollama model
    -v \                    # Include DVC
    -r s3                  # DVC remote type
```

### Command Line Options
```
Options:
  -n: Project name (required)
  -t: Template type (basic or advanced, default: basic)
  -d: Include Docker setup
  -p: Python version (default: 3.11)
  -s: Include Sphinx documentation
  -g: Include GitHub Actions
  -l: Include GitLab CI
  -c: Use conda environment
  -f: LLM framework (llamaindex, langchain, or both)
  -o: Include Ollama support
  -m: Ollama model (default: llama2)
  -v: Include DVC support
  -r: DVC remote type (s3, gcs, azure, local)
```

## Project Structure

The generated project follows this structure:
```
my_project/
├── src/                    # Source code
│   └── my_project/        # Main package
├── tests/                 # Test files
├── data/                  # Data directory
│   ├── raw/              # Raw data
│   └── processed/        # Processed data
├── docs/                 # Documentation
├── scripts/              # Utility scripts
├── configs/              # Configuration files
├── notebooks/           # Jupyter notebooks
├── .github/             # GitHub Actions (optional)
├── .gitlab-ci.yml       # GitLab CI (optional)
├── Dockerfile           # Docker configuration (optional)
├── docker-compose.yml   # Docker services (optional)
├── pyproject.toml       # Poetry configuration
├── .pre-commit-config.yaml  # Pre-commit hooks
└── README.md            # Project documentation
```

## MLOps Features

### DVC Integration
```bash
# Initialize DVC with remote storage
make dvc-init --remote-type=s3 --remote-url=s3://your-bucket

# Create and run experiments
make exp-create name=experiment1
make exp-run exp_id=experiment1_20240121_120000

# Compare experiments
make exp-compare exp_ids=exp1_id,exp2_id
```

### Ollama Integration
```bash
# Start Ollama server
make ollama-start

# Train model
make ollama-train model=llama2

# Evaluate model
make ollama-evaluate
```

## Development Workflow

### Initial Setup
```bash
# Create new project
create-genai-project -n my_project -d -o

# Navigate to project
cd my_project

# Initialize git
git init

# Install dependencies
make install

# Setup pre-commit hooks
make setup-pre-commit
```

### Common Tasks
```bash
# Run tests
make test

# Format code
make format

# Run linters
make lint

# Clean build artifacts
make clean

# Build documentation
make docs
```

## Docker Support

### Development Environment
```bash
# Start development environment
docker-compose up -d

# Run commands in container
docker-compose exec app make test
```

### Production Build
```bash
# Build production image
docker build -t my_project:latest .

# Run container
docker run -p 8000:8000 my_project:latest
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

