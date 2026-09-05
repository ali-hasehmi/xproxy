#!/usr/bin/env sh

# Include common helper functions & variables
. "$PROXYCTL_HOME/common.sh"

INFO_TXT=KDE
WARN_TXT=KDE
DIE_TXT=KDE

KWRITE=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
KREAD=$(command -v kreadconfig6 || command -v kreadconfig5 || true)

check_kde() {
    [ -n "$KWRITE" ] && [ -n "$KREAD" ] ||
        die "Neither kwriteconfig6 nor kwriteconfig5 found. KDE tools are not installed."
}

notify_kio() {
    # Notify running KIO workers to reload kioslaverc
    if command -v dbus-send >/dev/null 2>&1; then
        dbus-send --type=signal /KIO/Scheduler org.kde.KIO.Scheduler.reparseSlaveConfiguration string:"" 2>/dev/null || true
    elif command -v qdbus >/dev/null 2>&1; then
        qdbus org.kde.kio.Scheduler /KIO/Scheduler org.kde.KIO.Scheduler.reparseSlaveConfiguration "" 2>/dev/null || true
    fi
}

description() {
    echo "Configures system-wide KDE Plasma desktop proxy settings via KIO"
}

enable() {
    # Set ProxyType=1 (Manual configuration)
    "$KWRITE" --file kioslaverc --group "Proxy Settings" --key "ProxyType" 1

    case "$PROXYCTL_PROTO" in
        socks|socks4|socks5|socks5h)
            local url="socks://$PROXYCTL_HOST:$PROXYCTL_PORT"

            # Set SOCKS proxy
            "$KWRITE" --file kioslaverc --group "Proxy Settings" --key "socksProxy" "$url"

            # Remove protocol-specific proxies so KIO routes everything via SOCKS
            "$KWRITE" --file kioslaverc --group "Proxy Settings" --key "httpProxy" --delete 2>/dev/null || true
            "$KWRITE" --file kioslaverc --group "Proxy Settings" --key "httpsProxy" --delete 2>/dev/null || true
            "$KWRITE" --file kioslaverc --group "Proxy Settings" --key "ftpProxy" --delete 2>/dev/null || true
            ;;
        http)
            local url="http://$PROXYCTL_HOST:$PROXYCTL_PORT"

            # Set HTTP/HTTPS/FTP proxies
            "$KWRITE" --file kioslaverc --group "Proxy Settings" --key "httpProxy" "$url"
            "$KWRITE" --file kioslaverc --group "Proxy Settings" --key "httpsProxy" "$url"
            "$KWRITE" --file kioslaverc --group "Proxy Settings" --key "ftpProxy" "$url"

            # Remove SOCKS proxy to prevent protocol collision
            "$KWRITE" --file kioslaverc --group "Proxy Settings" --key "socksProxy" --delete 2>/dev/null || true
            ;;
        *)
            die "Unsupported protocol for KDE module: $PROXYCTL_PROTO"
            ;;
    esac

    # Set exception list
    "$KWRITE" --file kioslaverc --group "Proxy Settings" --key "NoProxyFor" "$PROXYCTL_NO_PROXY"

    notify_kio
    info "Desktop proxy set to ${C_BLUE}$PROXYCTL_PROTO://$PROXYCTL_HOST:$PROXYCTL_PORT${C_RESET}"
}

disable() {
    # Set ProxyType=0 (Direct connection / No proxy)
    "$KWRITE" --file kioslaverc --group "Proxy Settings" --key "ProxyType" 0

    notify_kio
    info "Desktop proxy mode set to ${C_BLUE}direct${C_RESET} (ProxyType=0)"
}

status() {
    local ptype
    ptype=$("$KREAD" --file kioslaverc --group "Proxy Settings" --key "ProxyType" 2>/dev/null || echo "0")

    case "$ptype" in
        0|"")
            info "Desktop proxy is ${C_RED}INACTIVE${C_RESET} (direct connection)"
            ;;
        1)
            local socks_proxy http_proxy
            socks_proxy=$("$KREAD" --file kioslaverc --group "Proxy Settings" --key "socksProxy" 2>/dev/null || true)
            http_proxy=$("$KREAD" --file kioslaverc --group "Proxy Settings" --key "httpProxy" 2>/dev/null || true)

            if [ -n "$socks_proxy" ]; then
                info "Desktop proxy is ${C_GREEN}ACTIVE${C_RESET} (manual: $socks_proxy)"
            elif [ -n "$http_proxy" ]; then
                info "Desktop proxy is ${C_GREEN}ACTIVE${C_RESET} (manual: $http_proxy)"
            else
                info "Desktop proxy is ${C_GREEN}ACTIVE${C_RESET} (manual)"
            fi
            ;;
        2)
            info "Desktop proxy is in ${C_YELLOW}PAC SCRIPT${C_RESET} mode"
            ;;
        3)
            info "Desktop proxy is in ${C_YELLOW}WPAD (AUTO)${C_RESET} mode"
            ;;
        4)
            info "Desktop proxy is in ${C_YELLOW}ENV VAR${C_RESET} mode"
            ;;
        *)
            info "Desktop proxy mode is unknown: ProxyType=$ptype"
            ;;
    esac
}

# --- Module Dispatcher ---
case "$1" in
    description)
        description
        ;;
    enable|disable|status)
        check_kde
        "$1"
        ;;
    *)
        die "Module ${C_BLUE}'kde'${C_RESET} does not support command: $1"
        ;;
esac
