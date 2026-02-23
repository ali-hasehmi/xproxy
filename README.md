# xproxy: Simple Proxy Manager

**xproxy** is a shell utility that unifies proxy management across your entire Linux environment. One command updates your **Terminal** (current & future sessions), **GNOME**, and **KDE Plasma** instantly.

---

## Quick installation
```sh
curl -s https://raw.githubusercontent.com/ali-hasehmi/xproxy/refs/heads/main/install.sh | bash
```
## Configuration
see [xproxy_profile](./xproxy_profile), all parameters are documented in the template file, also by default the ~/.xproxy_profile is used

### 3. Usage
| command                   | description |
| :-------                  | :-------    |
| xproxy set            	| Enables proxy using the default ~/.xproxy_profile. |
| xproxy set ./custom.conf	| Enables proxy using a specific custom profile file. |
| xproxy unset          	| Disables all proxies (System, Env, Cache) and goes direct. |
| xproxy status	            | Shows the current status of Env vars, GNOME, and KDE |


