# Ansible Common Modules & Arguments — Quick Reference

> **Study method:** Learn **Module → Purpose → Important Arguments → Syntax → Example**. Do not try to memorize every possible argument. Use `ansible-doc` for the rest.

## 1. Ad-Hoc Command Syntax

| Part | Meaning | Example |
|---|---|---|
| `TARGET` | Host/group/pattern | `three_tier_app` |
| `-m` | Module | `-m file` |
| `-a` | Module arguments | `-a "path=/tmp/lab state=directory"` |
| `-i` | Inventory | `-i ./automation/inventory/nodes` |
| `-b` | Become/sudo | `-b` |
| `-K` | Ask for become password | `-b -K` |
| `-u` | Remote user | `-u ansibleadmin` |
| `-C` | Check mode when supported | `-C` |
| `-vvv` | Detailed troubleshooting | `-vvv` |

```bash
ansible TARGET -m MODULE -a "ARGUMENT=value ..." -i INVENTORY
```

---

## 2. Most Common Modules — Master Table

| Module | Purpose | Arguments to Learn First |
|---|---|---|
| `ping` | Test Ansible connectivity/execution | `data` |
| `command` | Run ordinary commands | `cmd`, `chdir`, `creates`, `removes` |
| `shell` | Run commands requiring shell features | `cmd`, `chdir`, `creates`, `removes`, `executable` |
| `file` | Manage files/directories/links/permissions | `path`, `state`, `owner`, `group`, `mode`, `src` |
| `copy` | Copy files or write content | `src`, `dest`, `content`, `owner`, `group`, `mode`, `backup` |
| `template` | Deploy Jinja2 templates | `src`, `dest`, `owner`, `group`, `mode`, `backup` |
| `dnf` | RHEL/Rocky package management | `name`, `state`, `update_cache` |
| `package` | Generic package management | `name`, `state` |
| `service` | Generic service management | `name`, `state`, `enabled` |
| `systemd_service` | systemd-specific service management | `name`, `state`, `enabled`, `daemon_reload`, `masked` |
| `user` | Manage users | `name`, `state`, `uid`, `groups`, `append`, `shell`, `create_home` |
| `group` | Manage groups | `name`, `state`, `gid`, `system` |
| `setup` | Gather Ansible facts | `filter`, `gather_subset` |
| `debug` | Print messages/variables | `msg`, `var`, `verbosity` |
| `stat` | Inspect file/path information | `path`, `follow`, `get_checksum` |
| `lineinfile` | Manage one line in a file | `path`, `regexp`, `line`, `state`, `backup` |
| `blockinfile` | Manage a text block | `path`, `block`, `marker`, `state`, `backup` |
| `get_url` | Download HTTP/HTTPS file | `url`, `dest`, `mode`, `checksum` |
| `unarchive` | Extract archives | `src`, `dest`, `remote_src`, `creates` |
| `fetch` | Copy managed-node file to control node | `src`, `dest`, `flat` |
| `cron` | Manage cron jobs | `name`, `minute`, `hour`, `job`, `state`, `user` |
| `reboot` | Reboot and wait for host | `reboot_timeout`, `pre_reboot_delay`, `post_reboot_delay` |
| `wait_for` | Wait for port/path/condition | `host`, `port`, `path`, `state`, `timeout`, `delay` |
| `uri` | HTTP/API requests | `url`, `method`, `status_code`, `body`, `body_format` |

---

## 3. Quick Examples Table

| Task | Module | Example |
|---|---|---|
| Test node | `ping` | `ansible all -m ping -i ./automation/inventory/nodes` |
| Show FQDN | `command` | `ansible all -m command -a "hostname -f" -i ./automation/inventory/nodes` |
| Create directory | `file` | `ansible all -m file -a "path=/tmp/lab state=directory mode=0755" -i ./automation/inventory/nodes` |
| Remove directory | `file` | `ansible all -m file -a "path=/tmp/lab state=absent" -i ./automation/inventory/nodes` |
| Create content | `copy` | `ansible all -m copy -a 'content="Hello\n" dest=/tmp/hello.txt' -i ./automation/inventory/nodes` |
| Install package | `dnf` | `ansible all -m dnf -a "name=httpd state=present" -b -i ./automation/inventory/nodes` |
| Start service | `service` | `ansible all -m service -a "name=httpd state=started enabled=yes" -b -i ./automation/inventory/nodes` |
| Create user | `user` | `ansible all -m user -a "name=devops state=present shell=/bin/bash" -b -i ./automation/inventory/nodes` |
| Gather OS facts | `setup` | `ansible node1 -m setup -a "filter=ansible_distribution*" -i ./automation/inventory/nodes` |
| Display host/IP | `debug` | `ansible all -m debug -a 'msg="{{ inventory_hostname }} -> {{ ansible_host }}"' -i ./automation/inventory/nodes` |
| Inspect file | `stat` | `ansible all -m stat -a "path=/etc/ssh/sshd_config" -i ./automation/inventory/nodes` |
| Fetch remote file | `fetch` | `ansible node1 -m fetch -a "src=/var/log/messages dest=/tmp/logs/" -b -i ./automation/inventory/nodes` |

---

# 4. `file`

| Argument | Meaning | Example |
|---|---|---|
| `path` | Target path | `/tmp/ansible-lab` |
| `state` | Desired state | `directory`, `touch`, `absent`, `link` |
| `owner` | Owner | `ansibleadmin` |
| `group` | Group | `ansibleadmin` |
| `mode` | Permissions | `0755`, `0644` |
| `src` | Source for links | `/opt/app/current` |

```bash
ansible three_tier_app -m file -a "path=/tmp/ansible-lab state=directory mode=0755" -i ./automation/inventory/nodes
```

Memory tip: `directory` means the directory must exist; `absent` means it must not exist.

---

# 5. `copy`

| Argument | Meaning |
|---|---|
| `src` | Source file on control node |
| `dest` | Destination on managed node |
| `content` | Write direct content instead of copying source |
| `owner`, `group` | Ownership |
| `mode` | Permissions |
| `backup` | Backup old destination before replacement |

```bash
ansible three_tier_app -m copy -a 'content="Hello from Ansible\n" dest=/tmp/hello.txt mode=0644' -i ./automation/inventory/nodes
```

---

# 6. `command` vs `shell`

| `command` | `shell` |
|---|---|
| Preferred for normal commands | Use when shell features are required |
| No shell interpretation | Runs through a shell |
| Pipes/redirection are not processed as shell syntax | Supports `|`, `>`, `&&`, variables, etc. |
| Safer default | Requires more care with input/quoting |

Important arguments for both: `cmd`, `chdir`, `creates`, `removes`.

```bash
ansible all -m command -a "hostname -f" -i ./automation/inventory/nodes
```

Shell example:

```bash
ansible all -m shell -a 'ps -ef | grep "[s]shd"' -i ./automation/inventory/nodes
```

---

# 7. `dnf` and `package`

| Argument | Meaning | Values |
|---|---|---|
| `name` | Package | `httpd`, `git`, `vim` |
| `state` | Desired state | `present`, `absent`, `latest` |
| `update_cache` | Refresh metadata | `yes` |

```bash
ansible all -m dnf -a "name=httpd state=present" -b -i ./automation/inventory/nodes
```

`dnf` is especially relevant to RHEL/Rocky. `package` provides a more generic package-management interface.

---

# 8. `service` / `systemd_service`

| Argument | Meaning | Common Values |
|---|---|---|
| `name` | Service/unit | `httpd`, `sshd`, `chronyd` |
| `state` | Desired/action state | `started`, `stopped`, `restarted`, `reloaded` |
| `enabled` | Start at boot | `yes`, `no` |
| `daemon_reload` | Reload systemd manager config (`systemd_service`) | `true` |
| `masked` | Mask/unmask unit (`systemd_service`) | `true`, `false` |

```bash
ansible all -m service -a "name=httpd state=started enabled=yes" -b -i ./automation/inventory/nodes
```

---

# 9. `user` / `group`

| User Argument | Meaning |
|---|---|
| `name` | Username |
| `state` | `present` / `absent` |
| `uid` | Numeric UID |
| `group` | Primary group |
| `groups` | Supplementary groups |
| `append` | Append supplementary groups |
| `shell` | Login shell |
| `create_home` | Create home directory |

```bash
ansible all -m user -a "name=devops state=present shell=/bin/bash create_home=yes" -b -i ./automation/inventory/nodes
```

Group:

```bash
ansible all -m group -a "name=devops state=present" -b -i ./automation/inventory/nodes
```

---

# 10. `setup`, `debug`, `stat`

| Module | Key Arguments | Purpose |
|---|---|---|
| `setup` | `filter`, `gather_subset` | Gather system facts |
| `debug` | `msg`, `var` | Display information |
| `stat` | `path`, `follow`, `get_checksum` | Inspect file/path |

```bash
ansible node1 -m setup -a "filter=ansible_distribution*" -i ./automation/inventory/nodes
```

```bash
ansible web:app -m debug -a 'msg="{{ inventory_hostname }} -> {{ ansible_host }}"' -i ./automation/inventory/nodes
```

```bash
ansible all -m stat -a "path=/etc/ssh/sshd_config" -i ./automation/inventory/nodes
```

---

# 11. Configuration File Modules

| Module | Best Use | Important Arguments |
|---|---|---|
| `lineinfile` | One line | `path`, `regexp`, `line`, `state`, `backup` |
| `blockinfile` | Multi-line block | `path`, `block`, `marker`, `state`, `backup` |
| `template` | Complete variable-driven config | `src`, `dest`, `owner`, `group`, `mode`, `backup` |

Example:

```bash
ansible all -m lineinfile -a 'path=/tmp/app.conf regexp="^ENV=" line="ENV=production" create=yes' -i ./automation/inventory/nodes
```

---

# 12. Transfer / Download / Archive

| Module | Direction/Purpose | Key Arguments |
|---|---|---|
| `copy` | Control → Managed | `src`, `dest` |
| `fetch` | Managed → Control | `src`, `dest`, `flat` |
| `get_url` | Web → Managed | `url`, `dest`, `checksum` |
| `unarchive` | Extract archive | `src`, `dest`, `remote_src`, `creates` |

Memory:

```text
copy  → Control Node → Managed Node
fetch → Managed Node → Control Node
```

---

# 13. Operations Modules

| Module | Purpose | Important Arguments |
|---|---|---|
| `cron` | Schedule jobs | `name`, `minute`, `hour`, `job`, `state`, `user` |
| `reboot` | Reboot safely and wait | `reboot_timeout`, `pre_reboot_delay`, `post_reboot_delay` |
| `wait_for` | Wait for port/path/condition | `port`, `path`, `state`, `timeout`, `delay` |
| `uri` | HTTP/API check/request | `url`, `method`, `status_code`, `body`, `body_format` |

Cron example:

```bash
ansible all -m cron -a 'name="daily backup" minute="0" hour="2" job="/opt/backup.sh"' -b -i ./automation/inventory/nodes
```

HTTP health check:

```bash
ansible web -m uri -a "url=http://localhost status_code=200" -i ./automation/inventory/nodes
```

---

# 14. Which Module Should I Use?

| Need | Module |
|---|---|
| Test Ansible connection | `ping` |
| Normal Linux command | `command` |
| Pipe/redirection/shell feature | `shell` |
| File/directory/permissions | `file` |
| Copy file/content | `copy` |
| Variable-driven config | `template` |
| RHEL/Rocky packages | `dnf` |
| Generic packages | `package` |
| Service | `service` |
| systemd-specific controls | `systemd_service` |
| User/group | `user`, `group` |
| System facts | `setup` |
| Print variable | `debug` |
| Inspect file | `stat` |
| One config line | `lineinfile` |
| Config block | `blockinfile` |
| Download | `get_url` |
| Extract archive | `unarchive` |
| Remote → control file | `fetch` |
| Cron | `cron` |
| Reboot | `reboot` |
| Wait for port/path | `wait_for` |
| HTTP/API | `uri` |

---

# 15. Best Arguments to Memorize First

| Module | Memorize These First |
|---|---|
| `file` | `path`, `state`, `owner`, `group`, `mode` |
| `copy` | `src`, `dest`, `content`, `mode` |
| `command` | `cmd`, `chdir`, `creates` |
| `shell` | `cmd`, `chdir`, `creates` |
| `dnf` | `name`, `state` |
| `service` | `name`, `state`, `enabled` |
| `user` | `name`, `state`, `groups`, `append`, `shell` |
| `setup` | `filter` |
| `debug` | `msg`, `var` |
| `stat` | `path` |
| `lineinfile` | `path`, `regexp`, `line`, `state` |
| `template` | `src`, `dest`, `mode` |

---

# 16. Study Formula

| Question | Identify |
|---|---|
| **WHO?** | Target host/group |
| **WHAT?** | Module |
| **HOW?** | Arguments |
| **STATE?** | Desired result |
| **CHANGED?** | `changed=true/false` |
| **VERIFY?** | Command/module to prove result |

Example:

```bash
ansible three_tier_app -m file -a "path=/tmp/lab state=directory mode=0755" -i ./automation/inventory/nodes
```

```text
WHO?   → three_tier_app
WHAT?  → file
HOW?   → path, state, mode
STATE? → directory must exist
VERIFY → ls -ld /tmp/lab
```

---

# 17. Documentation — Don't Memorize Everything

Full documentation:

```bash
ansible-doc file
```

Short option reference:

```bash
ansible-doc -s file
```

Examples:

```bash
ansible-doc -s dnf
ansible-doc -s service
ansible-doc -s user
```

> **Best rule:** Know which module solves the problem, memorize its most common arguments, and use `ansible-doc` for the rest.

---

## Recommended Learning Order

```text
ping
 ↓
command + debug
 ↓
file
 ↓
copy + stat
 ↓
dnf
 ↓
service/systemd_service
 ↓
user/group
 ↓
setup (facts)
 ↓
lineinfile/template
 ↓
fetch/get_url/unarchive
 ↓
cron/uri/wait_for/reboot
 ↓
PLAYBOOKS
```

**Ansible Common Modules & Arguments Quick Reference**  
**Lab:** `ansible-server` → `node1`, `node2`, `node3`  
**Updated:** September 11, 2026
