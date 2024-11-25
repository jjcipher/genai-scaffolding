# GenAI Project Scaffolding Tool

A comprehensive scaffolding tool for creating GenAI (Generative AI) projects. Sets up complete project structures with LlamaIndex, LangChain, Ollama integration, and advanced MLOps features including DVC for experiment tracking.

## Features

### 🚀 Core Features
- **Multiple Framework Support**
  - LlamaIndex integration
  - LangChain setup
  - Ollama integration
  - Arize Phoenix integration (To be added)

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
  - Pipeline definitions (To be added)
  - Remote storage configuration (S3, GCS, Azure)
  - Metric tracking and comparison (To be added)

- **Docker Support**
  - Development containers
  - Production-ready configurations
  - Multi-service setup with docker-compose

### 🧪 Testing & Quality Assurance
- pytest setup
- Coverage reporting (To be added)
- Test data management
- CI/CD configurations

## Installation

Clone the repository and make the script executable:
```bash
git clone <repository-url>
cd genai-scaffolding
chmod +x create_genai_project.sh
```

## Usage

### Basic Usage
```bash
# Create a basic project
bash create_genai_project.sh -n my_project

# Create a project with Docker and Ollama support
bash create_genai_project.sh -n my_project -d -o -m llama2
```

### Advanced Usage
```bash
# Create a full-featured project
bash create_genai_project.sh -n my_project \
    -t advanced \          # Advanced template
    -d \                  # Include Docker
    -p 3.11 \            # Python version
    -s \                  # Include Sphinx docs
    -g \                  # GitHub Actions
    -l \                  # GitLab CI
    -f langchain \       # LLM framework
    -o \                  # Include Ollama
    -m llama2 \          # Ollama model
    -v \                  # Include DVC
    -r s3                # DVC remote type
```

### Command Line Options
```
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
├── models/              # Model files and configurations
├── .github/             # GitHub Actions (optional)
├── .gitlab-ci.yml       # GitLab CI (optional)
├── Dockerfile           # Docker configuration (optional)
├── docker-compose.yml   # Docker services (optional)
├── pyproject.toml       # Poetry configuration
├── .pre-commit-config.yaml  # Pre-commit hooks
└── README.md            # Project documentation
```

## MLOps Features

### DVC Integration (To be added)
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

# Pull model
make ollama-pull

# Run example
make ollama-run

# Train model (To be added)
make ollama-train model=llama2

# Evaluate model (To be added)
make ollama-evaluate
```

## Development Workflow

### Initial Setup
```bash
# Create new project
bash create_genai_project.sh -n my_project -d -o -m llama2

# Navigate to project
cd my_project

# Install dependencies
poetry install

# Setup pre-commit hooks
make setup-pre-commit

# If using Ollama:
make ollama-start        # In terminal 1
make ollama-pull         # In terminal 2
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

# Build documentation (To be added)
make docs
```

## Docker Support

The project includes both development and production Docker configurations.

### Development Environment
```bash
# Build development image
make docker-build

# Start development environment
make docker-run

# Run tests in container
make docker-test

# Clean up containers and volumes
make docker-clean
```

Features:
- Live code reloading with volume mounts
- Development dependencies included
- Remote debugging support (port 5678)
- Poetry cache persistence
- Ollama integration (if enabled)

### Production Environment
The production setup provides a minimal container with only runtime dependencies.

Configuration:
- Base image: python:{version}-slim
- Poetry for dependency management
- Production-only dependencies
- Health checks configured
- Port 8000 exposed

Files:
- `Dockerfile` - Production configuration
- `Dockerfile.dev` - Development configuration
- `docker-compose.yml` - Production services
- `docker-compose.dev.yml` - Development services
- `.dockerignore` - Optimized context loading
- `scripts/docker/` - Helper scripts for Docker operations

Docker-related make commands:
```bash
make docker-build      # Build both development and production images
make docker-run        # Start development environment
make docker-test       # Run tests in development container
make docker-clean      # Clean up containers and volumes
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
