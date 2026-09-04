#!/usr/bin/env sh

#
# install.sh - Installer for proxyctl
#
# Installs:
#   Application files:
#     ${XDG_DATA_HOME:-$HOME/.local/share}/proxyctl
#
#   User profile:
#     ${XDG_CONFIG_HOME:-$HOME/.config}/proxyctl/profile
#
# Usage:
#   Local:   ./install.sh
#   Remote:  curl -fsSL <raw-url>/install.sh | sh
#

set -e

# ---------------------------------------------------------------------------
# Terminal Colors & Logging (Failsafe under set -e)
# ---------------------------------------------------------------------------

C_RED=""
C_GREEN=""
C_YELLOW=""
C_BLUE=""
C_BOLD=""
C_RESET=""

if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
    # Test if terminal supports at least 8 colors without tripping set -e
    num_colors=$(tput colors 2>/dev/null || true)
    case "$num_colors" in
        ''|*[!0-9]*) num_colors=0 ;;
    esac

    if [ "$num_colors" -ge 8 ]; then
        C_RED=$(tput setaf 1 2>/dev/null || true)
        C_GREEN=$(tput setaf 2 2>/dev/null || true)
        C_YELLOW=$(tput setaf 3 2>/dev/null || true)
        C_BLUE=$(tput setaf 4 2>/dev/null || true)
        C_BOLD=$(tput bold 2>/dev/null || true)
        C_RESET=$(tput sgr0 2>/dev/null || true)
    fi
fi

log_install() { printf '%s\n' "${C_BLUE}[INSTALL]${C_RESET} $*"; }
log_git()     { printf '%s\n' "${C_BLUE}[GIT]${C_RESET} $*"; }
log_config()  { printf '%s\n' "${C_GREEN}[CONFIG]${C_RESET} $*"; }
log_warn()    { printf '%s\n' "${C_YELLOW}[WARN]${C_RESET} $*" >&2; }
die()         { printf '%s\n' "${C_RED}[ERROR]${C_RESET} $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Target Paths & Cleanup Trap
# ---------------------------------------------------------------------------

REPO_URL="${PROXYCTL_REPO_URL:-https://github.com/golestan-dev/proxyctl}"

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

TARGET_DATA_DIR="$XDG_DATA_HOME/proxyctl"
TARGET_CONFIG_DIR="$XDG_CONFIG_HOME/proxyctl"
TARGET_PROFILE="$TARGET_CONFIG_DIR/profile"

SOURCE_DIR=""
TEMP_DIR=""

cleanup() {
    [ -z "$TEMP_DIR" ] || rm -rf "$TEMP_DIR"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# ---------------------------------------------------------------------------
# Determine source: local checkout or remote repository
# ---------------------------------------------------------------------------

SCRIPT_DIR=""

case "$0" in
    */*)
        SCRIPT_DIR=$(
            CDPATH='' cd -- "$(dirname -- "$0")" 2>/dev/null &&
            pwd
        ) || true
        ;;
esac

if [ -n "$SCRIPT_DIR" ] &&
   [ -f "$SCRIPT_DIR/main.sh" ] &&
   [ -f "$SCRIPT_DIR/common.sh" ] &&
   [ -f "$SCRIPT_DIR/wrapper.sh" ] &&
   [ -f "$SCRIPT_DIR/profile" ] &&
   [ -d "$SCRIPT_DIR/modules" ]; then

    SOURCE_DIR="$SCRIPT_DIR"
    log_install "Using local repository at: ${C_BOLD}$SOURCE_DIR${C_RESET}"

else
    log_install "Local repository not detected; installing from remote"

    command -v git >/dev/null 2>&1 ||
        die "'git' is required for remote installation"

    command -v mktemp >/dev/null 2>&1 ||
        die "'mktemp' is required for remote installation"

    TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/proxyctl-install.XXXXXX") ||
        die "Failed to create temporary directory"

    log_git "Cloning ${C_BOLD}$REPO_URL${C_RESET}..."

    git clone \
        --quiet \
        --depth 1 \
        "$REPO_URL" \
        "$TEMP_DIR/repo"

    SOURCE_DIR="$TEMP_DIR/repo"
fi

# ---------------------------------------------------------------------------
# Validate source tree
# ---------------------------------------------------------------------------

for file in main.sh common.sh wrapper.sh profile; do
    [ -f "$SOURCE_DIR/$file" ] ||
        die "Missing required file: $SOURCE_DIR/$file"
done

has_modules=0
for mod in "$SOURCE_DIR/modules/"*.sh; do
    [ -f "$mod" ] && has_modules=1 && break
done
[ "$has_modules" -eq 1 ] || die "No modules found in: $SOURCE_DIR/modules"

# ---------------------------------------------------------------------------
# Prepare target directories
# ---------------------------------------------------------------------------

log_install "Preparing target directories..."

mkdir -p "$TARGET_DATA_DIR/modules"
mkdir -p "$TARGET_CONFIG_DIR"

chmod 700 "$TARGET_CONFIG_DIR"

# ---------------------------------------------------------------------------
# Install application files
# Repository modules are updated; unrelated custom modules are preserved.
# ---------------------------------------------------------------------------

log_install "Deploying core files to: ${C_BOLD}$TARGET_DATA_DIR${C_RESET}"

cp "$SOURCE_DIR/main.sh" "$TARGET_DATA_DIR/main.sh"
cp "$SOURCE_DIR/common.sh" "$TARGET_DATA_DIR/common.sh"
cp "$SOURCE_DIR/wrapper.sh" "$TARGET_DATA_DIR/wrapper.sh"

# Copy each repo module explicitly so non-conflicting custom user modules remain intact
for mod in "$SOURCE_DIR/modules/"*.sh; do
    [ -f "$mod" ] || continue
    cp -f "$mod" "$TARGET_DATA_DIR/modules/"
done

chmod +x "$TARGET_DATA_DIR/main.sh"
chmod +x "$TARGET_DATA_DIR"/modules/*.sh

# ---------------------------------------------------------------------------
# Install user profile
# ---------------------------------------------------------------------------

if [ -f "$TARGET_PROFILE" ]; then
    log_config "Existing profile detected; ${C_GREEN}preserving${C_RESET}: $TARGET_PROFILE"
else
    log_config "Installing default profile to: $TARGET_PROFILE"
    cp "$SOURCE_DIR/profile" "$TARGET_PROFILE"
    chmod 600 "$TARGET_PROFILE"
fi

# ---------------------------------------------------------------------------
# Finish
# ---------------------------------------------------------------------------

printf '\n'
printf '%s\n' "${C_GREEN}${C_BOLD}Installation complete.${C_RESET}"
printf '\n'
printf '%s\n' "Application installed at:"
printf '  %s\n' "$TARGET_DATA_DIR"
printf '\n'
printf '%s\n' "Configuration profile:"
printf '  %s\n' "$TARGET_PROFILE"
printf '\n'
printf '%s\n' "Add the following to your shell configuration (e.g. ~/.bashrc or ~/.zshrc):"
printf '\n'
printf '%s\n' "  ${C_YELLOW}[ -f \"$TARGET_DATA_DIR/wrapper.sh\" ] && . \"$TARGET_DATA_DIR/wrapper.sh\"${C_RESET}"
printf '\n'
printf '%s\n' "Then reload your shell configuration or open a new terminal."
