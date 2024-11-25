#!/usr/bin/env bash
# logging.sh - Logging utilities for GenAI project scaffolding

# Ensure script fails on error
set -euo pipefail

# Color codes for output
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'  # No Color

# Logging function
# Usage: log "LEVEL" "message"
# Levels: INFO, SUCCESS, WARNING, ERROR
log() {
    if [[ "$#" -lt 2 ]]; then
        echo "Usage: log LEVEL MESSAGE"
        return 1
    fi

    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")
            echo -e "${BLUE}[${timestamp}] [INFO] ${message}${NC}"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[${timestamp}] [SUCCESS] ${message}${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}[${timestamp}] [WARNING] ${message}${NC}"
            ;;
        "ERROR")
            echo -e "${RED}[${timestamp}] [ERROR] ${message}${NC}"
            ;;
        *)
            echo -e "${RED}[${timestamp}] [ERROR] Invalid log level: ${level}${NC}" >&2
            return 1
            ;;
    esac
}

# Function to print a horizontal line
print_line() {
    local char=${1:-"-"}
    local length=${2:-80}
    printf '%*s\n' "$length" '' | tr ' ' "$char"
}

# Function to print section header
print_section() {
    local title="$1"
    echo ""
    print_line "="
    echo -e "${BLUE}${title}${NC}"
    print_line "="
    echo ""
}

# Function to print debug information
# Only prints if DEBUG environment variable is set
debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        local timestamp
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo -e "${YELLOW}[${timestamp}] [DEBUG] $*${NC}" >&2
    fi
}

# Example usage function
log_examples() {
    cat << EOF
Logging Utility Usage Examples:

log "INFO" "Starting process..."
log "SUCCESS" "Process completed successfully"
log "WARNING" "Resource usage is high"
log "ERROR" "Process failed"

print_section "Configuration Setup"

# Enable debug output:
DEBUG=true debug "Detailed information"

# Print separator line:
print_line "=" 50
EOF
}

# If the script is run directly, show example usage
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_examples
fi

# Export functions to be used in other scripts
export -f log
export -f print_line
export -f print_section
export -f debug
