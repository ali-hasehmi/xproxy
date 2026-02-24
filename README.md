# proxyctl: Simple Proxy Manager

**proxyctl** is a shell utility that unifies proxy management across your entire Linux environment. One command updates your **Terminal** (current & future sessions), **GNOME**, and **KDE Plasma** instantly.

---

## Quick installation
```sh
curl -s https://raw.githubusercontent.com/ali-hasehmi/proxyctl/refs/heads/main/install.sh | bash
```
## Configuration
see [proxyctl_profile](./proxyctl_profile), all parameters are documented in the template file, also by default the ~/.proxyctl_profile is used

### 3. Usage
| command                   | description |
| :-------                  | :-------    |
| proxyctl set            	| Enables proxy using the default ~/.xproxy_profile. |
| proxyctl set ./custom.conf	| Enables proxy using a specific custom profile file. |
| proxyctl unset          	| Disables all proxies (System, Env, Cache) and goes direct. |
| proxyctl status	            | Shows the current status of Env vars, GNOME, and KDE |


