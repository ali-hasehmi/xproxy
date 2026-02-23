#!/usr/bin/env sh
#
# install script for xproxy
#

set -u

repo_url="https://github.com/ali-hasehmi/xproxy"
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

echo "[INFO] cloning repository in $temp_dir"
git clone --quiet --depth 1 "$repo_url"

cd $repo_name

echo "[INFO] installing xproxy at "$HOME/.xproxy""
mv -f xproxy "$HOME/.xproxy"

[ -f "$HOME/.xproxy_profile" ] || { 
    echo "[INFO installing defulat profile at "$HOME/.xproxy_profile""
    mv -f xproxy_profile "$HOME/.xproxy_profile"
}

shell=$(basename "$SHELL")
shellrc="$HOME/.profile"
case $shell in
    bash) shellrc="$HOME/.bashrc";;
    zsh) shellrc="$HOME/.zshrc";;
    ksh) shellrc="$HOME/.kshrc";;
esac


if  ! grep -qF '. "$HOME/.xproxy"' $shellrc; then
    echo "[INFO] detected shell is $shell"
    echo "[INFO] Updating $shellrc"
    >> $shellrc cat << EOF
# source xproxy
if [ -f "\$HOME/.xproxy" ]; then
. "\$HOME/.xproxy"
fi
EOF

fi

echo "Done!"
echo "Run this: source $shellrc"
