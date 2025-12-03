# xproxy: Simple Proxy Manager

**xproxy** is a bash utility that unifies proxy management across your entire Linux environment. One command updates your **Terminal** (current & future sessions), **GNOME**, and **KDE Plasma** instantly.

---

## Quick Start

### 1. Installation
Save the xproxy script to your home directory and source it in your `.bashrc`.

```bash
# 1. Save the script (assuming you named it .xproxy)
mv xproxy ~/.xproxy

# 2. Add to .bashrc (or .zshrc)
echo 'if [ -f "$HOME/.xproxy" ]; then source "$HOME/.xproxy"; fi' >> ~/.bashrc

# 3. Reload shell
source ~/.bashrc
```
### 2. Configuration 
Save the xproxy_profile to your home directory

```bash
# Save the default profile
mv xproxy_profile ~/.xproxy_profile
```

Open the file in a text editor and configure it 

### 3. Usage
| command                   | description |
| :-------                  | :-------    |
| xproxy set            	| Enables proxy using the default ~/.xproxy_profile. |
| xproxy set ./custom.conf	| Enables proxy using a specific custom profile file. |
| xproxy unset          	| Disables all proxies (System, Env, Cache) and goes direct. |
| xproxy status	            | Shows the current status of Env vars, GNOME, and KDE |


