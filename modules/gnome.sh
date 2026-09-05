#!/usr/bin/env sh

# Include common helper functions & variables
. "$PROXYCTL_HOME/common.sh"

INFO_TXT=GNOME
WARN_TXT=GNOME
DIE_TXT=GNOME

check_gnome() {
    command -v gsettings >/dev/null 2>&1 ||
        die "gsettings not found. GNOME desktop tools are not installed."

    gsettings list-schemas 2>/dev/null | grep -qx "org.gnome.system.proxy" ||
        die "GSettings schema 'org.gnome.system.proxy' is not installed."

    gsettings get org.gnome.system.proxy mode >/dev/null 2>&1 ||
        die "Unable to communicate with GSettings via D-Bus session."
}

description() {
    echo "Configures system-wide GNOME/GTK desktop proxy settings via GSettings"
}

format_ignore_hosts() {
    local formatted="" item
    local old_ifs="$IFS"
    IFS=','
    for item in $PROXYCTL_NO_PROXY; do
        item=$(echo "$item" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [ -n "$item" ] || continue
        if [ -z "$formatted" ]; then
            formatted="'$item'"
        else
            formatted="$formatted, '$item'"
        fi
    done
    IFS="$old_ifs"

    if [ -z "$formatted" ]; then
        echo "@as []"
    else
        echo "[$formatted]"
    fi
}

enable() {
    local ignore_list
    ignore_list=$(format_ignore_hosts)

    case "$PROXYCTL_PROTO" in
        socks|socks4|socks5|socks5h)
            # SOCKS handles all protocols natively; disable HTTP fallback binding
            gsettings set org.gnome.system.proxy use-same-proxy false

            # Set SOCKS proxy
            gsettings set org.gnome.system.proxy.socks host "$PROXYCTL_HOST"
            gsettings set org.gnome.system.proxy.socks port "$PROXYCTL_PORT"

            # Clear HTTP, HTTPS, and FTP so SOCKS handles all traffic
            gsettings set org.gnome.system.proxy.http host ''
            gsettings set org.gnome.system.proxy.http port 0
            gsettings set org.gnome.system.proxy.https host ''
            gsettings set org.gnome.system.proxy.https port 0
            gsettings set org.gnome.system.proxy.ftp host ''
            gsettings set org.gnome.system.proxy.ftp port 0
            ;;
        http)
            # Route all traffic through the HTTP proxy using CONNECT tunneling
            gsettings set org.gnome.system.proxy use-same-proxy true

            # Set HTTP proxy endpoint
            gsettings set org.gnome.system.proxy.http host "$PROXYCTL_HOST"
            gsettings set org.gnome.system.proxy.http port "$PROXYCTL_PORT"

            # Clear HTTPS, SOCKS, and FTP schemas to prevent TLS/protocol conflicts
            gsettings set org.gnome.system.proxy.https host ''
            gsettings set org.gnome.system.proxy.https port 0
            gsettings set org.gnome.system.proxy.socks host ''
            gsettings set org.gnome.system.proxy.socks port 0
            gsettings set org.gnome.system.proxy.ftp host ''
            gsettings set org.gnome.system.proxy.ftp port 0
            ;;
        https)
            die "Explicit 'https' proxy is not supported. Use 'http' to tunnel HTTPS traffic."
            ;;
        *)
            die "Unsupported protocol for GNOME module: $PROXYCTL_PROTO"
            ;;
    esac

    # Set non-proxy exception list and switch mode to manual
    gsettings set org.gnome.system.proxy ignore-hosts "$ignore_list"
    gsettings set org.gnome.system.proxy mode 'manual'

    info "Desktop proxy set to ${C_BLUE}$PROXYCTL_PROTO://$PROXYCTL_HOST:$PROXYCTL_PORT${C_RESET}"
}

disable() {
    gsettings set org.gnome.system.proxy mode 'none'
    info "Desktop proxy mode set to ${C_BLUE}none${C_RESET}"
}

status() {
    local mode
    mode=$(gsettings get org.gnome.system.proxy mode 2>/dev/null | tr -d "'")

    case "$mode" in
        none)
            info "Desktop proxy is ${C_RED}INACTIVE${C_RESET} (mode: none)"
            ;;
        manual)
            local shost sport hhost hport same_proxy
            shost=$(gsettings get org.gnome.system.proxy.socks host | tr -d "'")
            sport=$(gsettings get org.gnome.system.proxy.socks port)
            hhost=$(gsettings get org.gnome.system.proxy.http host | tr -d "'")
            hport=$(gsettings get org.gnome.system.proxy.http port)
            same_proxy=$(gsettings get org.gnome.system.proxy use-same-proxy)

            if [ -n "$shost" ] && [ "$sport" -ne 0 ]; then
                info "Desktop proxy is ${C_GREEN}ACTIVE${C_RESET} (socks://$shost:$sport)"
            elif [ -n "$hhost" ] && [ "$hport" -ne 0 ]; then
                info "Desktop proxy is ${C_GREEN}ACTIVE${C_RESET} (http://$hhost:$hport, use-same-proxy: $same_proxy)"
            else
                info "Desktop proxy is ${C_GREEN}ACTIVE${C_RESET} (mode: manual)"
            fi
            ;;
        auto)
            info "Desktop proxy is in ${C_YELLOW}AUTO${C_RESET} mode"
            ;;
        *)
            info "Desktop proxy mode is unknown: $mode"
            ;;
    esac
}

# --- Module Dispatcher ---
case "$1" in
    description)
        description
        ;;
    enable|disable|status)
        check_gnome
        "$1"
        ;;
    *)
        die "Module ${C_BLUE}'gnome'${C_RESET} does not support command: $1"
        ;;
esac
