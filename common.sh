#!/usr/bin/env sh

# --- UI & Colors ---
# Fallback to plain text if tput is missing or stdout is not a terminal
if command -v tput >/dev/null 2>&1 && [ -t 1 ]; then
    C_RED=$(tput setaf 1)
    C_GREEN=$(tput setaf 2)
    C_YELLOW=$(tput setaf 3)
    C_BLUE=$(tput setaf 4)
    C_RESET=$(tput sgr0)
    C_BOLD=$(tput bold)
else
    C_RED=""
    C_GREEN=""
    C_YELLOW=""
    C_BLUE=""
    C_RESET=""
fi

INFO_TXT=INFO
WARN_TXT=WARN
DIE_TXT=ERROR

# --- Logging Helper Functions ---
# Print to STDERR to ensure UI messages don't interfere with data streams
info() {
    echo "${C_BLUE}["$INFO_TXT"]${C_RESET} $*" >&2
}

warn() {
    echo "${C_YELLOW}["$WARN_TXT"]${C_RESET} $*" >&2
}

die() {
    echo "${C_RED}["$DIE_TXT"]${C_RESET} $*" >&2
    exit 1
}
