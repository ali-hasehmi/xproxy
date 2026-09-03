# Allows PROXYCTL_HOME to be overridden so developers can run the tool 
# straight from their git clone without installing it.

proxyctl() {
    local tmpfile
    tmpfile=$(mktemp -t proxyctl_env.XXXXXX) || return 
    
    (
        trap 'exit 130' INT
        trap 'exit 143' TERM

        # Default to XDG path, but user/developer can override the installation directory
        local install_dir="${PROXYCTL_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/proxyctl}"
        
        # Execute the core orchestrator. We pass the tmpfile via environment variable.
        PROXYCTL_OUT="$tmpfile" PROXYCTL_HOME="$install_dir" "$install_dir/main.sh" "$@"
    )
    local ret=$?

    # If the module wrote export/unset commands, source them into the interactive shell
    if [ "$ret" -eq 0 ] && [ -s "$tmpfile" ]; then
        echo "Changes to be applied:"
        while IFS= read -r line; do
            echo "  + $line"
        done < "$tmpfile"
        while true; do
            read -r -p "Apply above changes? [Y/n] " yn
            yn=${yn:-Y}
            case $yn in
                [Yy]* ) . "$tmpfile"; echo "Changes applied." ; break;;
                [Nn]* ) echo "Aborted by user."; break;; 
            esac
        done
    fi

    # cleanup.
    rm -f "$tmpfile"

    return "$ret"
}
