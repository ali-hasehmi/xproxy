#!/usr/bin/env sh

# Include common helper functions & variables
. "./common.sh"

# Default profile location adheres to XDG config standard
PROFILE_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/proxyctl/profile"

# Default Module Path location 
MODULE_PATH="$(realpath ./modules)"

# ---  Command Line Parsing ---
while getopts ":hp:m:" opt; do
    case "$opt" in
        p )
            PROFILE_PATH="$(realpath "$OPTARG")"
            ;;
        m)  
            MODULE_PATH="$OPTARG"
            ;;
        h)
            # TODO: call help function
            echo "Usage: proxyctl [-p profile] <command> [modules...]"
            echo "Commands: enable(set), disable(unset), status(stat), ls(list), edit(e), view(v)"
            exit 0
            ;;
        \? )
            die "Unknown option: -$OPTARG"
            ;;
        : )
            die "Invalid option: -$OPTARG requires an argument"
            ;;
    esac
done

# Shift off the options so $1 refers to the first positional argument
shift $((OPTIND -1))

if [ "$#" -eq 0 ]; then
    die "Missing command. Run 'proxyctl -h' for usage."
fi

COMMAND="$1"
shift

CLI_MODULES="$*"

# --- Profile Loading & Validation ---
load_profile() {
    if [ ! -f "$PROFILE_PATH" ]; then
        die "Profile not found at: $PROFILE_PATH"
    fi
    
    # Source the profile configuration
    . "$PROFILE_PATH"
    
    # Export explicitly required variables with defaults
    export PROXYCTL_PROTO="${PROTO:-socks5h}"
    export PROXYCTL_HOST="${HOST:-127.0.0.1}"
    export PROXYCTL_PORT="${PORT:-9050}"
    export PROXYCTL_NO_PROXY="${NO_PROXY:-localhost,127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,*.local}"
    # Fallback to 'all' if MODULES is empty
    MODULES="${MODULES:-all}"
}


# Checks if the provided space-separated list contains 'all'
modules_contain_all() {
    for mod in $1; do
        [ "$mod" = "all" ] && return 0
    done
    return 1
}

# Returns a list of names of all modules
modules_get_all() {
    local mod_list
    for mod_file in "$MODULE_PATH"/*.sh; do
        [ -f "$mod_file" ] || continue
        local mod_name=$(basename "$mod_file" .sh)
        mod_list="${mod_name} ${mod_list}"
    done
    [ -z "$mod_list" ] && die "No modules found in $MODULE_PATH"
    echo "$mod_list"
}

# Executes a module with given arguments
modules_exec() {
   local mod_name="$1"
   [ -z "$mod_name" ] && die "Invalid use of modules_exec: No module name was provided"
   shift

   local mod_file="$MODULE_PATH/${mod_name}.sh"
   if [ ! -x "$mod_file" ]; then
      warn "Module '$mod_name' not found or not executable. Skipping."
      return
   fi
            
   # Execute the module with the specified arguments 
   "$mod_file" "$@"
}

# --- Module Resolution ---
modules_get_target() {
    if modules_contain_all "$CLI_MODULES" || modules_contain_all "$MODULES"; then
        # Dynamically list all .sh files in the modules directory
        modules_get_all
    elif [ -n "$CLI_MODULES" ]; then
        echo "$CLI_MODULES"
    else
        echo "$MODULES" # Fallback to the array defined in the profile
    fi
}

# --- Command Aliasing & Routing ---
# Map user-friendly aliases (s, set) to strictly defined internal verbs (enable)
case "$COMMAND" in
    enable|e|set|s)
        VERB="enable"
        ;;
    disable|d|unset|u)
        VERB="disable"
        ;;
    status|stat|st)
        VERB="status"
        ;;
    edit|e)
        VERB="edit"
        ;;
    view|v)
        VERB="view"
        ;;
    list|ls)
        VERB="list"
        ;;
    *)
        die "Unknown command: $COMMAND"
        ;;
esac


load_profile

# --- Execution ---
case "$VERB" in
    edit)
        "${VISUAL:-${EDITOR:-vi}}" "$PROFILE_PATH"
        ;;
    view)
        "${PAGER:-less}" "$PROFILE_PATH"
        ;;
    list)
        MODS="$(modules_get_target)"
        info "Available proxyctl modules:"
        for mod in $MODS; do
            desc=$(modules_exec "$mod" description)
            printf "  ${C_BLUE}%-10s${C_RESET} - %s\n" "$mod" "$desc"
        done
        ;;
    enable|disable|status)
        TARGETS=$(modules_get_target)
        
        if [ -z "$TARGETS" ]; then
            die "No modules specified in CLI or profile."
        fi

        for mod in $TARGETS; do
            # Execute the module with the normalized verb
            modules_exec "$mod" "$VERB"
        done
        ;;
esac
