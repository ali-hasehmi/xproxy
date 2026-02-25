#!/usr/bin/env sh
#
# install script for proxyctl
#

set -e

repo_url="https://github.com/ali-hasehmi/proxyctl"
repo_name=$(basename $repo_url)
temp_dir="${TMPDIR:-/tmp}"

cleanup() {
    rm -rf "$temp_dir/$repo_name"
}

trap cleanup EXIT

# Dependency check

dependencies="git"

for dep in $dependencies; do
    command -v "$dep" >/dev/null 2>/dev/null || {
        >&2 echo "error: missing dependency: cannot find '$dep' executable"
        exit 127
    }
done

cd "$temp_dir"

echo "[GIT] cloning repository in $temp_dir/$repo_name"
git clone --quiet --depth 1 "$repo_url"

cd $repo_name

if diff -q proxyctl "$HOME/.proxyctl" >/dev/null 2>/dev/null; then
    echo "[PROXYCTL] "$HOME/.proxyctl" is already installed"
else
    echo "[PROXYCTL] installing proxyctl at "$HOME/.proxyctl""
    mv -f proxyctl "$HOME/.proxyctl"
fi

if [ -f "$HOME/.proxyctl_profile" ]; then
    echo "[PROFILE] "$HOME/.proxyctl_profile" is already installed"
else
    echo "[PROFILE] installing defulat profile at "$HOME/.proxyctl_profile""
    mv -f proxyctl_profile "$HOME/.proxyctl_profile"
fi

shell=$(basename "$SHELL")
shellrc="$HOME/.profile"
case $shell in
    bash) shellrc="$HOME/.bashrc";;
    zsh) shellrc="$HOME/.zshrc";;
    ksh) shellrc="$HOME/.kshrc";;
esac


echo "[SHELL] detected shellrc is $shellrc"

if  grep -qF '. "$HOME/.proxyctl"' $shellrc; then
    echo "[SHELL] $shellrc is already updated"
else 
    echo "[SHELL] Updating $shellrc"
    >> $shellrc cat << EOF

# source proxyctl
if [ -f "\$HOME/.proxyctl" ]; then
    . "\$HOME/.proxyctl"
fi
EOF

fi

echo "Done!"
echo "Run this: source $shellrc"
