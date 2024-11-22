#!/usr/bin/env bash
# install.sh - Install the GenAI project scaffolding tool with shell detection

set -euo pipefail

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Default installation directory
INSTALL_DIR="${HOME}/.local/bin"
SCRIPT_DIR="${HOME}/.local/share/genai-scaffold"
SHELL_TYPE="bash"  # Default shell

# Detect shell
detect_shell() {
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        SHELL_TYPE="zsh"
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        SHELL_TYPE="bash"
    else
        echo -e "${RED}Warning: Unable to detect shell type. Defaulting to bash.${NC}"
    fi
    echo -e "${BLUE}Detected shell: $SHELL_TYPE${NC}"
}

# Get default shell from user settings
get_default_shell() {
    local user_shell
    user_shell=$(basename "$SHELL")
    if [[ "$user_shell" == "zsh" || "$user_shell" == "bash" ]]; then
        SHELL_TYPE="$user_shell"
    fi
}

# Setup shell configuration
setup_shell_config() {
    local shell_type="$1"
    local path_export="export PATH=\"\${PATH}:${INSTALL_DIR}\""
    local source_line="source \"${SCRIPT_DIR}/genai_scaffold_completion.${shell_type}\""
    
    case "$shell_type" in
        "zsh")
            local zshrc="${HOME}/.zshrc"
            local zshenv="${HOME}/.zshenv"
            
            # Create .zshrc if it doesn't exist
            touch "$zshrc"
            
            # Add PATH if not present
            if ! grep -q "${INSTALL_DIR}" "$zshrc"; then
                echo "$path_export" >> "$zshrc"
            fi
            
            # Add completion source if not present
            if ! grep -q "genai_scaffold_completion" "$zshrc"; then
                echo "$source_line" >> "$zshrc"
            fi
            
            # Setup ZSH completion directory
            mkdir -p "${HOME}/.zsh/completion"
            ;;
            
        "bash")
            local bashrc="${HOME}/.bashrc"
            local bash_completion_dir="${HOME}/.bash_completion.d"
            
            # Create .bashrc if it doesn't exist
            touch "$bashrc"
            
            # Add PATH if not present
            if ! grep -q "${INSTALL_DIR}" "$bashrc"; then
                echo "$path_export" >> "$bashrc"
            fi
            
            # Setup bash completion directory
            mkdir -p "$bash_completion_dir"
            
            # Add completion source if not present
            if ! grep -q "genai_scaffold_completion" "$bashrc"; then
                echo "$source_line" >> "$bashrc"
            fi
            ;;
    esac
}

# Create shell completions
create_shell_completions() {
    # Create bash completion
    cat > "${SCRIPT_DIR}/genai_scaffold_completion.bash" << 'EOF'
#!/usr/bin/env bash

_genai_scaffold_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    opts="-n -t -d -p -s -g -l -c -f -o -m -v -r"
    
    case "${prev}" in
        -t)
            COMPREPLY=( $(compgen -W "basic advanced" -- "${cur}") )
            return 0
            ;;
        -f)
            COMPREPLY=( $(compgen -W "llamaindex langchain both" -- "${cur}") )
            return 0
            ;;
        -r)
            COMPREPLY=( $(compgen -W "s3 gcs azure local" -- "${cur}") )
            return 0
            ;;
        -m)
            COMPREPLY=( $(compgen -W "llama2 codellama mistral" -- "${cur}") )
            return 0
            ;;
        -p)
            COMPREPLY=( $(compgen -W "3.8 3.9 3.10 3.11" -- "${cur}") )
            return 0
            ;;
        *)
            ;;
    esac
    
    if [[ ${cur} == -* ]] ; then
        COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
        return 0
    fi
}

complete -F _genai_scaffold_completion create-genai-project
EOF

    # Create zsh completion
    cat > "${SCRIPT_DIR}/genai_scaffold_completion.zsh" << 'EOF'
#compdef create-genai-project

_create_genai_project() {
    local -a opts
    opts=(
        '-n[Project name (required)]:project name'
        '-t[Template type]:template:(basic advanced)'
        '-d[Include Docker setup]'
        '-p[Python version]:version:(3.8 3.9 3.10 3.11)'
        '-s[Include Sphinx documentation]'
        '-g[Include GitHub Actions]'
        '-l[Include GitLab CI]'
        '-c[Use conda environment]'
        '-f[LLM framework]:framework:(llamaindex langchain both)'
        '-o[Include Ollama support]'
        '-m[Ollama model]:model:(llama2 codellama mistral)'
        '-v[Include DVC support]'
        '-r[DVC remote type]:remote:(s3 gcs azure local)'
    )
    
    _arguments -s $opts
}

compdef _create_genai_project create-genai-project
EOF

    # Make completion scripts executable
    chmod +x "${SCRIPT_DIR}/genai_scaffold_completion.bash"
    chmod +x "${SCRIPT_DIR}/genai_scaffold_completion.zsh"
}

# Ensure installation directories exist
mkdir -p "${INSTALL_DIR}"
mkdir -p "${SCRIPT_DIR}"

# Detect shell type
detect_shell
get_default_shell

# Copy all necessary files to script directory
cp create_genai_project.sh "${SCRIPT_DIR}/"
cp -r templates "${SCRIPT_DIR}/"

# Create wrapper script in INSTALL_DIR
cat > "${INSTALL_DIR}/create-genai-project" << EOF
#!/usr/bin/env bash
# Wrapper script for GenAI project scaffolding

# Get the directory where this script is installed
SCRIPT_DIR="${SCRIPT_DIR}"

# Execute the main script with all arguments
"${SCRIPT_DIR}/create_genai_project.sh" "\$@"
EOF

# Make scripts executable
chmod +x "${INSTALL_DIR}/create-genai-project"
chmod +x "${SCRIPT_DIR}/create_genai_project.sh"

# Create shell completions
create_shell_completions

# Setup shell configuration
setup_shell_config "$SHELL_TYPE"

echo -e "${GREEN}Installation complete!${NC}"
echo -e "${BLUE}Shell completions have been set up for ${SHELL_TYPE}${NC}"
echo -e "${BLUE}You can now use 'create-genai-project' from anywhere.${NC}"
echo -e "${BLUE}Please restart your shell or run: source ~/.${SHELL_TYPE}rc${NC}"
