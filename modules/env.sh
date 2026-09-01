#!/usr/bin/env sh

# Change $PWD to module's location
cd "$(dirname "$0")" 


# Include common helper functions & variables
. "../common.sh"

INFO_TXT=ENV
WARN_TXT=ENV
DIE_TXT=ENV

description() {
    echo "Manages shell environment variables (http_proxy, etc.)"
}

enable() {
    local url=""
    
    if [ "$PROXYCTL_PROTO" = "http" ] || [ "$PROXYCTL_PROTO" = "https" ]; then
        url="http://$PROXYCTL_HOST:$PROXYCTL_PORT"
    else
        url="$PROXYCTL_PROTO://$PROXYCTL_HOST:$PROXYCTL_PORT"
    fi

    if [ -z "$PROXYCTL_OUT" ]; then
        die "PROXYCTL_OUT is not set. The env module requires a target file."
    fi

    {
        echo "export http_proxy='$url'"
        echo "export https_proxy='$url'"
        echo "export HTTP_PROXY='$url'"
        echo "export HTTPS_PROXY='$url'"
        echo "export ftp_proxy='$url'"
        echo "export rsync_proxy='$url'"
        echo "export all_proxy='$url'"
        echo "export no_proxy='$PROXYCTL_NO_PROXY'"
        echo "export NO_PROXY='$PROXYCTL_NO_PROXY'"
    } >> "$PROXYCTL_OUT"

    info "Shell variables prepared to route through ${C_BLUE}$url${C_RESET}"
}

disable() {
    if [ -z "$PROXYCTL_OUT" ]; then
        die "PROXYCTL_OUT is not set."
    fi

    {
        echo "unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY"
        echo "unset ftp_proxy rsync_proxy all_proxy"
        echo "unset no_proxy NO_PROXY"
    } >> "$PROXYCTL_OUT"

    info "Shell variables prepared to be unset"
}

status() {
    local url
    # Ensure printenv doesn't fail the script if 'set -e' is inherited
    if url=$(printenv http_proxy 2>/dev/null); then
        info "variables are set to: ${C_GREEN}$url${C_RESET}"
    else
        info "variables are ${C_RED}NOT${C_RESET} set"
    fi
}

# --- Module Dispatcher ---
# Validate input to prevent arbitrary function execution
if command -v "$1" >/dev/null 2>&1; then
    "$1"
else
    die "Module ${C_BLUE}'env'${C_RESET} does not support command: $1"
fi
