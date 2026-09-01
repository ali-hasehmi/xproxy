# Default proxy profile
# vim: ft=sh:

# Protocol can be: http, https, socks4, socks4a, socks5, socks5h
# Default is 'socks5h'
PROTO="socks5h"

# Default is '127.0.0.1'
HOST="127.0.0.1"

# Default is '9050'
PORT="9050"

# Default modules to apply if none are specified on the command line
# Run `proxyctl ls` to see the list of available modules
# Default is 'all'
MODULES="all"

# Bypass list for local and private networks
# Default is 'localhost,127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,*.local'
NO_PROXY="localhost,127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,*.local"

