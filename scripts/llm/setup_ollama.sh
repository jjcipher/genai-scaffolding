#!/usr/bin/env bash
# setup_ollama.sh - Set up Ollama integration for GenAI projects

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../scripts/utils/logging.sh"

setup_ollama() {
    local project_dir="$1"
    local project_name="$2"
    local ollama_model="$3"
    
    log "INFO" "Setting up Ollama integration..."
    
    # Create Ollama directory structure
    mkdir -p "$project_dir/src/$project_name/ollama"
    mkdir -p "$project_dir/src/$project_name/models"
    mkdir -p "$project_dir/tests/ollama"
    
    # Create Ollama client module
    cat > "$project_dir/src/$project_name/ollama/client.py" << ENDOFFILE
"""Ollama client for LLM interactions."""

from typing import Dict, List, Optional, Any, Union, AsyncIterator, Iterator
import httpx
from pathlib import Path
import json

class OllamaClient:
    """Client for interacting with Ollama API."""
    
    def __init__(
        self,
        base_url: str = "http://localhost:11434",
        model: str = "$ollama_model",
        timeout: int = 300,
    ):
        """Initialize Ollama client.
        
        Args:
            base_url: Base URL for Ollama API
            model: Model name to use
            timeout: Request timeout in seconds
        """
        self.base_url = base_url.rstrip("/")
        self.model = model
        self.timeout = timeout
        self._client = httpx.Client(timeout=timeout)
    
    def generate(
        self,
        prompt: str,
        system: Optional[str] = None,
        template: Optional[str] = None,
        context: Optional[List[int]] = None,
        options: Optional[Dict[str, Any]] = None,
        stream: bool = False,
    ) -> Union[str, Iterator[str]]:
        """Generate completion from Ollama.
        
        Args:
            prompt: Input prompt
            system: System prompt
            template: Custom prompt template
            context: Previous context
            options: Additional model options
            stream: Whether to stream the response
            
        Returns:
            Generated text or stream of generated text
        """
        url = f"{self.base_url}/api/generate"
        
        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": stream,
        }
        
        if system:
            payload["system"] = system
        if template:
            payload["template"] = template
        if context:
            payload["context"] = context
        if options:
            payload["options"] = options
            
        if stream:
            return self._stream_response(url, payload)
        
        response = self._client.post(url, json=payload)
        response.raise_for_status()
        
        return response.json()["response"]
    
    def _stream_response(self, url: str, payload: Dict[str, Any]) -> Iterator[str]:
        """Stream response from Ollama.
        
        Args:
            url: API endpoint
            payload: Request payload
            
        Yields:
            Generated text chunks
        """
        with self._client.stream("POST", url, json=payload) as response:
            response.raise_for_status()
            for line in response.iter_lines():
                if line:
                    data = json.loads(line)
                    if "error" in data:
                        raise Exception(data["error"])
                    if "response" in data:
                        yield data["response"]
    
    def embeddings(
        self,
        texts: List[str],
        batch_size: int = 32,
    ) -> List[List[float]]:
        """Get embeddings for texts.
        
        Args:
            texts: List of texts to embed
            batch_size: Number of texts to process at once
            
        Returns:
            List of embeddings
        """
        url = f"{self.base_url}/api/embeddings"
        embeddings = []
        
        for i in range(0, len(texts), batch_size):
            batch = texts[i:i + batch_size]
            response = self._client.post(
                url,
                json={
                    "model": self.model,
                    "prompt": batch[0] if len(batch) == 1 else batch,
                },
            )
            response.raise_for_status()
            data = response.json()
            if len(batch) == 1:
                embeddings.append(data["embedding"])
            else:
                embeddings.extend(data["embeddings"])
        
        return embeddings

    async def agenerate(
        self,
        prompt: str,
        system: Optional[str] = None,
        template: Optional[str] = None,
        context: Optional[List[int]] = None,
        options: Optional[Dict[str, Any]] = None,
        stream: bool = False,
    ) -> Union[str, AsyncIterator[str]]:
        """Async version of generate method."""
        url = f"{self.base_url}/api/generate"
        
        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": stream,
        }
        
        if system:
            payload["system"] = system
        if template:
            payload["template"] = template
        if context:
            payload["context"] = context
        if options:
            payload["options"] = options
        
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            if stream:
                return self._astream_response(client, url, payload)
            
            response = await client.post(url, json=payload)
            response.raise_for_status()
            return response.json()["response"]
    
    async def _astream_response(
        self,
        client: httpx.AsyncClient,
        url: str,
        payload: Dict[str, Any],
    ) -> AsyncIterator[str]:
        """Async stream response from Ollama."""
        async with client.stream("POST", url, json=payload) as response:
            response.raise_for_status()
            async for line in response.aiter_lines():
                if line:
                    data = json.loads(line)
                    if "error" in data:
                        raise Exception(data["error"])
                    if "response" in data:
                        yield data["response"]

    def save_model_file(self, model_file: Path) -> None:
        """Save Modelfile for custom model configurations.
        
        Args:
            model_file: Path to Modelfile
        """
        url = f"{self.base_url}/api/create"
        
        with open(model_file, "r") as f:
            model_content = f.read()
        
        response = self._client.post(
            url,
            json={
                "name": self.model,
                "modelfile": model_content,
            },
        )
        response.raise_for_status()
ENDOFFILE

    # Create example usage module
    cat > "$project_dir/src/$project_name/models/run_ollama.py" << ENDOFFILE
"""Example usage of Ollama client."""

import asyncio
from typing import Optional
from ..ollama.client import OllamaClient

async def chat_example(client: Optional[OllamaClient] = None) -> None:
    """Run example chat interaction with Ollama."""
    client = client or OllamaClient(model="$ollama_model")
    
    # Example with system prompt
    response = await client.agenerate(
        prompt="What's the capital of France?",
        system="You are a helpful assistant that provides concise answers.",
    )
    print(f"Response: {response}")
    
    # Example with streaming
    print("\nStreaming example:")
    async for chunk in await client.agenerate(
        prompt="Write a short poem about coding.",
        stream=True,
    ):
        print(chunk, end="", flush=True)
    print("\n")

def main():
    """Run main example."""
    asyncio.run(chat_example())

if __name__ == "__main__":
    main()
ENDOFFILE

    # Create test file
    cat > "$project_dir/tests/ollama/test_client.py" << ENDOFFILE
"""Tests for Ollama client."""

import pytest
from typing import Generator
import httpx
from ${project_name}.ollama.client import OllamaClient

@pytest.fixture
def client() -> OllamaClient:
    """Create Ollama client for testing."""
    return OllamaClient(model="$ollama_model")

def test_generate(client: OllamaClient) -> None:
    """Test basic generation."""
    response = client.generate("Hello!")
    assert isinstance(response, str)
    assert len(response) > 0

def test_generate_with_system(client: OllamaClient) -> None:
    """Test generation with system prompt."""
    response = client.generate(
        prompt="Hello!",
        system="You are a helpful assistant.",
    )
    assert isinstance(response, str)
    assert len(response) > 0

def test_stream_generate(client: OllamaClient) -> None:
    """Test streaming generation."""
    stream = client.generate("Hello!", stream=True)
    assert isinstance(stream, Generator)
    chunks = list(stream)
    assert len(chunks) > 0
    assert all(isinstance(chunk, str) for chunk in chunks)

def test_embeddings(client: OllamaClient) -> None:
    """Test text embeddings."""
    texts = ["Hello, world!", "Another text"]
    embeddings = client.embeddings(texts)
    assert len(embeddings) == len(texts)
    assert all(isinstance(emb, list) for emb in embeddings)
    assert all(isinstance(x, float) for emb in embeddings for x in emb)

@pytest.mark.asyncio
async def test_agenerate(client: OllamaClient) -> None:
    """Test async generation."""
    response = await client.agenerate("Hello!")
    assert isinstance(response, str)
    assert len(response) > 0

def test_invalid_url() -> None:
    """Test client with invalid URL."""
    client = OllamaClient(base_url="http://invalid-url")
    with pytest.raises(httpx.RequestError):
        client.generate("Hello!")
ENDOFFILE

    # Create Modelfile example
    mkdir -p "$project_dir/models"
    cat > "$project_dir/models/Modelfile" << ENDOFFILE
# Modelfile example for custom model configuration
FROM $ollama_model

# Set parameters
PARAMETER temperature 0.7
PARAMETER num_ctx 4096

# Set system prompt
SYSTEM You are a helpful AI assistant specialized in programming and technical tasks.

# Custom template format
TEMPLATE """
{{- if .System }}
System: {{ .System }}
{{- end }}

User: {{ .Prompt }}

Assistant: {{ .Response }}
"""

# Custom model parameters
PARAMETER stop "Human:" "Assistant:"
PARAMETER repeat_penalty 1.1
PARAMETER top_k 40
PARAMETER top_p 0.9
PARAMETER seed 42
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

ollama-create:
	ollama create ${ollama_model} -f models/Modelfile

ollama-test:
	poetry run pytest tests/ollama
ENDOFFILE
    fi
    
    log "SUCCESS" "Ollama setup complete"
    log "INFO" "Next steps:"
    echo "1. Start Ollama server: make ollama-start"
    echo "2. Pull the model: make ollama-pull"
    echo "3. Create custom model: make ollama-create"
    echo "4. Run example: make ollama-run"
    echo "5. Run tests: make ollama-test"
}

# Execute only if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ "$#" -lt 3 ]]; then
        echo "Usage: $0 PROJECT_DIR PROJECT_NAME OLLAMA_MODEL"
        exit 1
    fi
    setup_ollama "$@"
fi