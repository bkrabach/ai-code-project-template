#!/usr/bin/env bash

# Claude Code make check hook script
# Intelligently finds and runs 'make check' from the appropriate directory

# Ensure proper environment for make to find /bin/sh
export PATH="/bin:/usr/bin:$PATH"
export SHELL="/bin/bash"
#
# Expected JSON input format from stdin:
# {
#   "session_id": "abc123",
#   "transcript_path": "/path/to/transcript.jsonl",
#   "cwd": "/path/to/project/subdir",
#   "hook_event_name": "PostToolUse",
#   "tool_name": "Write",
#   "tool_input": {
#     "file_path": "/path/to/file.txt",
#     "content": "..."
#   },
#   "tool_response": {
#     "filePath": "/path/to/file.txt",
#     "success": true
#   }
# }

set -euo pipefail

# Read JSON from stdin
JSON_INPUT=$(cat)

# Debug: Log the JSON input to a file (comment out in production)
# echo "DEBUG: JSON received at $(date):" >> /tmp/make-check-debug.log
# echo "$JSON_INPUT" >> /tmp/make-check-debug.log

# Parse fields from JSON (using simple grep/sed for portability)
CWD=$(echo "$JSON_INPUT" | grep -o '"cwd"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
TOOL_NAME=$(echo "$JSON_INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "")

# Check if tool operation was successful
SUCCESS=$(echo "$JSON_INPUT" | grep -o '"success"[[:space:]]*:[[:space:]]*[^,}]*' | sed 's/.*"success"[[:space:]]*:[[:space:]]*\([^,}]*\).*/\1/' || echo "")

# Extract file_path from tool_input if available
FILE_PATH=$(echo "$JSON_INPUT" | grep -o '"tool_input"[[:space:]]*:[[:space:]]*{[^}]*}' | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || true)

# If tool operation failed, exit early
if [[ "${SUCCESS:-}" == "false" ]]; then
    echo "Skipping 'make check' - tool operation failed"
    exit 0
fi

# Log what tool was used
if [[ -n "${TOOL_NAME:-}" ]]; then
    echo "Post-hook for $TOOL_NAME tool"
fi

# Determine the starting directory
# Priority: 1) Directory of edited file, 2) CWD, 3) Current directory
START_DIR=""
if [[ -n "${FILE_PATH:-}" ]]; then
    # Use directory of the edited file
    FILE_DIR=$(dirname "$FILE_PATH")
    if [[ -d "$FILE_DIR" ]]; then
        START_DIR="$FILE_DIR"
        echo "Using directory of edited file: $FILE_DIR"
    fi
fi

if [[ -z "$START_DIR" ]] && [[ -n "${CWD:-}" ]]; then
    START_DIR="$CWD"
elif [[ -z "$START_DIR" ]]; then
    START_DIR=$(pwd)
fi

# Function to find project root (looks for .git or Makefile going up the tree)
find_project_root() {
    local dir="$1"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/Makefile" ]] || [[ -d "$dir/.git" ]]; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    return 1
}

# Function to check if make target exists
make_target_exists() {
    local dir="$1"
    local target="$2"
    if [[ -f "$dir/Makefile" ]]; then
        # Check if target exists in Makefile
        make -C "$dir" -n "$target" &>/dev/null
        return $?
    fi
    return 1
}

# Start from the determined directory
cd "$START_DIR"

# Check if there's a local Makefile with 'check' target
if make_target_exists "." "check"; then
    echo "Running 'make check' in directory: $START_DIR"
    make check
else
    # Find the project root
    PROJECT_ROOT=$(find_project_root "$START_DIR")
    
    if [[ -n "$PROJECT_ROOT" ]] && make_target_exists "$PROJECT_ROOT" "check"; then
        echo "Running 'make check' from project root: $PROJECT_ROOT"
        cd "$PROJECT_ROOT"
        make check
    else
        echo "Error: No Makefile with 'check' target found in current directory or project root"
        exit 1
    fi
fi