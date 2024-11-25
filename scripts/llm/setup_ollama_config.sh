#!/usr/bin/env bash
# setup_ollama_config.sh - Create configuration for Ollama integration

set -euo pipefail

create_ollama_config() {
    local project_dir="$1"
    local project_name="$2"
    
    # Create config directory if it doesn't exist
    mkdir -p "$project_dir/configs"
    
    # Create Ollama configuration file
    cat > "$project_dir/configs/ollama.json" << ENDOFFILE
{
    "default_model": "${ollama_model}",
    "models": {
        "${ollama_model}": {
            "temperature": 0.7,
            "num_ctx": 4096,
            "system_prompt": "You are a helpful AI assistant specialized in programming and technical tasks.",
            "template": null
        }
    },
    "api": {
        "base_url": "http://localhost:11434",
        "timeout": 300
    }
}
ENDOFFILE

    # Create configuration loader module
    cat > "$project_dir/src/$project_name/config.py" << ENDOFFILE
"""Configuration management for Ollama integration."""

import json
from pathlib import Path
from typing import Dict, Any, Optional

def load_ollama_config(config_path: Optional[str] = None) -> Dict[str, Any]:
    """Load Ollama configuration from JSON file.
    
    Args:
        config_path: Path to config file, defaults to configs/ollama.json
        
    Returns:
        Configuration dictionary
    """
    if config_path is None:
        config_path = Path(__file__).parent.parent.parent / "configs" / "ollama.json"
    
    with open(config_path) as f:
        return json.load(f)

def get_model_config(
    model_name: Optional[str] = None,
    config: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Get configuration for specific model.
    
    Args:
        model_name: Name of the model to get config for
        config: Existing config dict, loads from file if None
        
    Returns:
        Model configuration dictionary
    """
    config = config or load_ollama_config()
    model_name = model_name or config["default_model"]
    
    return config["models"][model_name]
ENDOFFILE

    # Create example configuration usage
    cat > "$project_dir/src/$project_name/models/config_example.py" << ENDOFFILE
"""Example usage of Ollama configuration."""

from ..config import load_ollama_config, get_model_config
from ..ollama.client import OllamaClient

def main():
    """Run configuration example."""
    # Load configuration
    config = load_ollama_config()
    
    # Get default model configuration
    model_config = get_model_config()
    
    # Create client with configuration
    client = OllamaClient(
        base_url=config["api"]["base_url"],
        model=config["default_model"],
        timeout=config["api"]["timeout"],
    )
    
    # Use model configuration
    response = client.generate(
        prompt="Hello!",
        system=model_config["system_prompt"],
        options={
            "temperature": model_config["temperature"],
            "num_ctx": model_config["num_ctx"],
        },
    )
    
    print(f"Response: {response}")

if __name__ == "__main__":
    main()
ENDOFFILE

    # Add Ollama commands to Makefile
    if ! grep -q "ollama:" "$project_dir/Makefile"; then
        cat >> "$project_dir/Makefile" << ENDOFFILE

# Ollama commands
ollama-start:
	ollama serve

ollama-pull:
	ollama pull ${ollama_model}

ollama-run:
	poetry run python -m ${project_name}.models.run_ollama

ollama-example:
	poetry run python -m ${project_name}.models.config_example
ENDOFFILE
    fi
    
    log "SUCCESS" "Ollama setup complete"
}

# Execute only if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ "$#" -lt 3 ]]; then
        echo "Usage: $0 PROJECT_DIR PROJECT_NAME OLLAMA_MODEL"
        exit 1
    fi
    setup_ollama "$@"
fi
