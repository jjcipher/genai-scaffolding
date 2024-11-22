#!/usr/bin/env bash
# uninstall.sh - Uninstall the GenAI project scaffolding tool

set -euo pipefail

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Installation directories
INSTALL_DIR="${HOME}/.local/bin"
SCRIPT_DIR="${HOME}/.local/share/genai-scaffold"

# Detect shell
SHELL_TYPE="bash"
if [[ -n "${ZSH_VERSION:-}" ]]; then
    SHELL_TYPE="zsh"
elif [[ -n "${BASH_VERSION:-}" ]]; then
    SHELL_TYPE="bash"
fi

# Remove shell-specific configurations
cleanup_shell_config() {
    local shell_type="$1"
    
    case "$shell_type" in
        "zsh")
            local zshrc="${HOME}/.zshrc"
            if [[ -f "$zshrc" ]]; then
                sed -i '/genai-scaffold/d' "$zshrc"
                sed -i '/genai_scaffold_completion/d' "$zshrc"
            fi
            # Clean up ZSH completion
            rm -f "${HOME}/.zsh/completion/_create-genai-project"
            ;;
            
        "bash")
            local bashrc="${HOME}/.bashrc"
            if [[ -f "$bashrc" ]]; then
                sed -i '/genai-scaffold/d' "$bashrc"
                sed -i '/genai_scaffold_completion/d' "$bashrc"
            fi
            # Clean up Bash completion
            rm -f "${HOME}/.bash_completion.d/create-genai-project"
            ;;
    esac
}

# Remove installed files
rm -f "${INSTALL_DIR}/create-genai-project"
rm -rf "${SCRIPT_DIR}"

# Clean up shell configurations
cleanup_shell_config "bash"
cleanup_shell_config "zsh"

echo -e "${GREEN}Uninstallation complete!${NC}"
echo -e "${BLUE}Please restart your shell or run: source ~/.${SHELL_TYPE}rc${NC}"
