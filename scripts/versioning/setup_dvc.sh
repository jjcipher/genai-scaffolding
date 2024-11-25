#!/usr/bin/env bash
# setup_dvc.sh - Set up DVC for data versioning

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../scripts/utils/logging.sh"

setup_dvc() {
    local project_dir="$1"
    local remote_type="$2"
    
    log "INFO" "Setting up DVC..."
    
    # Initialize DVC
    (cd "$project_dir" && dvc init -q)
    
    # Create DVC configuration
    log "INFO" "Creating DVC configuration..."
    
    case "$remote_type" in
        "s3")
            cat > "$project_dir/.dvc/config" << ENDOFFILE
[core]
    remote = s3-remote
['remote "s3-remote"']
    url = s3://my-bucket/dvc-store
    # Uncomment and modify as needed:
    # region = us-east-1
    # profile = default
    # endpointurl = https://my-endpoint.com
ENDOFFILE
            ;;
        "gcs")
            cat > "$project_dir/.dvc/config" << ENDOFFILE
[core]
    remote = gcs-remote
['remote "gcs-remote"']
    url = gs://my-bucket/dvc-store
    # Uncomment and modify as needed:
    # projectname = my-project
    # credentialpath = path/to/credentials.json
ENDOFFILE
            ;;
        "azure")
            cat > "$project_dir/.dvc/config" << ENDOFFILE
[core]
    remote = azure-remote
['remote "azure-remote"']
    url = azure://my-container/dvc-store
    # Uncomment and modify as needed:
    # account_name = my-account
    # connection_string = my-connection-string
ENDOFFILE
            ;;
        "local")
            cat > "$project_dir/.dvc/config" << ENDOFFILE
[core]
    remote = local-remote
['remote "local-remote"']
    url = /path/to/dvc-store
ENDOFFILE
            ;;
        *)
            log "ERROR" "Invalid remote type: $remote_type"
            exit 1
            ;;
    esac
    
    # Create data directories
    mkdir -p "$project_dir/data/"{raw,processed,external}
    mkdir -p "$project_dir/models"
    
    # Create example DVC pipeline
    cat > "$project_dir/dvc.yaml" << ENDOFFILE
stages:
  prepare:
    cmd: python src/${project_dir##*/}/data/prepare.py
    deps:
      - data/raw
      - src/${project_dir##*/}/data/prepare.py
    params:
      - params.yaml:
        - data.prepare
    outs:
      - data/processed
    metrics:
      - metrics/prepare.json:
          cache: false

  train:
    cmd: python src/${project_dir##*/}/models/train.py
    deps:
      - data/processed
      - src/${project_dir##*/}/models/train.py
    params:
      - params.yaml:
        - model.train
    outs:
      - models/model.pkl
    metrics:
      - metrics/train.json:
          cache: false
    plots:
      - plots/train_history.json:
          cache: false
          x: epoch
          y: loss

  evaluate:
    cmd: python src/${project_dir##*/}/models/evaluate.py
    deps:
      - data/processed
      - models/model.pkl
      - src/${project_dir##*/}/models/evaluate.py
    params:
      - params.yaml:
        - model.evaluate
    metrics:
      - metrics/evaluate.json:
          cache: false
    plots:
      - plots/confusion_matrix.json:
          cache: false
          template: confusion
          x: predicted
          y: actual
ENDOFFILE

    # Create parameters file
    cat > "$project_dir/params.yaml" << ENDOFFILE
data:
  prepare:
    test_size: 0.2
    random_state: 42
    
model:
  train:
    batch_size: 32
    epochs: 10
    learning_rate: 0.001
    optimizer: adam
  
  evaluate:
    batch_size: 32
    metrics:
      - accuracy
      - precision
      - recall
      - f1
ENDOFFILE

    # Create data processing script
    mkdir -p "$project_dir/src/${project_dir##*/}/data"
    cat > "$project_dir/src/${project_dir##*/}/data/prepare.py" << ENDOFFILE
"""Data preparation script for DVC pipeline."""

import json
from pathlib import Path
import yaml

def prepare_data():
    """Prepare data for training."""
    # Load parameters
    with open("params.yaml") as f:
        params = yaml.safe_load(f)["data"]["prepare"]
    
    # Create metrics directory
    metrics_dir = Path("metrics")
    metrics_dir.mkdir(exist_ok=True)
    
    # Save metrics
    metrics = {
        "num_samples": 1000,  # Replace with actual count
        "test_size": params["test_size"],
        "random_state": params["random_state"]
    }
    
    with open(metrics_dir / "prepare.json", "w") as f:
        json.dump(metrics, f, indent=4)

if __name__ == "__main__":
    prepare_data()
ENDOFFILE

    # Create training script
    mkdir -p "$project_dir/src/${project_dir##*/}/models"
    cat > "$project_dir/src/${project_dir##*/}/models/train.py" << ENDOFFILE
"""Model training script for DVC pipeline."""

import json
from pathlib import Path
import yaml
import pickle

def train_model():
    """Train the model."""
    # Load parameters
    with open("params.yaml") as f:
        params = yaml.safe_load(f)["model"]["train"]
    
    # Create directories
    metrics_dir = Path("metrics")
    plots_dir = Path("plots")
    models_dir = Path("models")
    
    metrics_dir.mkdir(exist_ok=True)
    plots_dir.mkdir(exist_ok=True)
    models_dir.mkdir(exist_ok=True)
    
    # Mock training history
    history = {
        "epoch": list(range(params["epochs"])),
        "loss": [0.5 - 0.4 * (i / params["epochs"]) for i in range(params["epochs"])]
    }
    
    # Save training metrics
    metrics = {
        "final_loss": history["loss"][-1],
        "epochs": params["epochs"],
        "batch_size": params["batch_size"]
    }
    
    with open(metrics_dir / "train.json", "w") as f:
        json.dump(metrics, f, indent=4)
    
    # Save training history plot
    with open(plots_dir / "train_history.json", "w") as f:
        json.dump(history, f, indent=4)
    
    # Save model
    model = {"type": "mock_model"}  # Replace with actual model
    with open(models_dir / "model.pkl", "wb") as f:
        pickle.dump(model, f)

if __name__ == "__main__":
    train_model()
ENDOFFILE

    # Create evaluation script
    cat > "$project_dir/src/${project_dir##*/}/models/evaluate.py" << ENDOFFILE
"""Model evaluation script for DVC pipeline."""

import json
from pathlib import Path
import yaml
import pickle

def evaluate_model():
    """Evaluate the model."""
    # Load parameters
    with open("params.yaml") as f:
        params = yaml.safe_load(f)["model"]["evaluate"]
    
    # Create directories
    metrics_dir = Path("metrics")
    plots_dir = Path("plots")
    metrics_dir.mkdir(exist_ok=True)
    plots_dir.mkdir(exist_ok=True)
    
    # Load model
    with open("models/model.pkl", "rb") as f:
        model = pickle.load(f)
    
    # Mock evaluation metrics
    metrics = {
        "accuracy": 0.85,
        "precision": 0.83,
        "recall": 0.86,
        "f1": 0.84
    }
    
    # Mock confusion matrix
    confusion_matrix = {
        "actual": ["class_0", "class_0", "class_1", "class_1"] * 25,
        "predicted": ["class_0", "class_1", "class_0", "class_1"] * 25,
        "count": [40, 10, 10, 40]
    }
    
    # Save evaluation metrics
    with open(metrics_dir / "evaluate.json", "w") as f:
        json.dump(metrics, f, indent=4)
    
    # Save confusion matrix plot
    with open(plots_dir / "confusion_matrix.json", "w") as f:
        json.dump(confusion_matrix, f, indent=4)

if __name__ == "__main__":
    evaluate_model()
ENDOFFILE

    # Create .dvcignore file
    cat > "$project_dir/.dvcignore" << ENDOFFILE
# Add patterns of files dvc should ignore, which is useful
# when your data directory contains files that should not be tracked.
*.tmp
*.temp
.ipynb_checkpoints
ENDOFFILE

    # Add DVC commands to Makefile if not already present
    if ! grep -q "dvc-init:" "$project_dir/Makefile"; then
        cat >> "$project_dir/Makefile" << ENDOFFILE

# DVC commands
dvc-init:
	dvc init
	dvc config core.remote ${remote_type}-remote

dvc-remote-setup:
ifeq (${remote_type},s3)
	@echo "Configure S3 remote with:"
	@echo "dvc remote modify s3-remote region YOUR_REGION"
	@echo "dvc remote modify s3-remote profile YOUR_PROFILE"
	@echo "dvc remote modify s3-remote url s3://YOUR_BUCKET/PATH"
else ifeq (${remote_type},gcs)
	@echo "Configure GCS remote with:"
	@echo "dvc remote modify gcs-remote projectname YOUR_PROJECT"
	@echo "dvc remote modify gcs-remote url gs://YOUR_BUCKET/PATH"
else ifeq (${remote_type},azure)
	@echo "Configure Azure remote with:"
	@echo "dvc remote modify azure-remote account_name YOUR_ACCOUNT"
	@echo "dvc remote modify azure-remote url azure://YOUR_CONTAINER/PATH"
else
	@echo "Configure local remote with:"
	@echo "dvc remote modify local-remote url /path/to/storage"
endif

dvc-add-data:
	dvc add data/raw data/external

dvc-run-pipeline:
	dvc repro

dvc-show-pipeline:
	dvc dag

dvc-push:
	dvc push

dvc-pull:
	dvc pull

dvc-show-metrics:
	dvc metrics show

dvc-show-plots:
	dvc plots show

dvc-clean:
	dvc remove --outs
	dvc gc -w
ENDOFFILE
    fi
    
    # Add DVC-specific entries to .gitignore if not already present
    if ! grep -q "/data" "$project_dir/.gitignore"; then
        cat >> "$project_dir/.gitignore" << ENDOFFILE

# DVC
/data
/models/*.pkl
/.dvc/cache
/.dvc/tmp
/.dvc/plots
*.dvc
ENDOFFILE
    fi
    
    log "SUCCESS" "DVC setup complete"
    log "INFO" "Next steps:"
    echo "1. Configure remote storage: make dvc-remote-setup"
    echo "2. Add your data: make dvc-add-data"
    echo "3. Run the pipeline: make dvc-run-pipeline"
    echo "4. Push to remote: make dvc-push"
    echo "5. View metrics: make dvc-show-metrics"
    echo "6. View plots: make dvc-show-plots"
}

# Execute only if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ "$#" -lt 2 ]]; then
        echo "Usage: $0 PROJECT_DIR REMOTE_TYPE"
        exit 1
    fi
    setup_dvc "$@"
fi
