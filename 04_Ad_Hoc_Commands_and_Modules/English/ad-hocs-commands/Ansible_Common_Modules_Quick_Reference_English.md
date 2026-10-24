# Ansible Common Modules — Quick Reference

## Table of Contents

1. [Purpose of this guide](#1-purpose-of-this-guide)
2. [How to use `ansible-doc`](#2-how-to-use-ansible-doc)
3. [Common module reference](#3-common-module-reference)
4. [Quick module-selection guide](#4-quick-module-selection-guide)
5. [Collection-based modules](#5-collection-based-modules)
6. [Practice commands for the personal lab](#6-practice-commands-for-the-personal-lab)
7. [Important safety and idempotency notes](#7-important-safety-and-idempotency-notes)
8. [Quick revision questions](#8-quick-revision-questions)

---

## 1. Purpose of this guide

An Ansible **module** is a reusable unit of code that performs a specific task on a managed node, such as copying a file, installing a package, creating a user, or starting a service.

This guide uses:

- Inventory group: `three_tier_app`
- Managed nodes: `node1`, `node2`, and `node3`
- Remote user: `ansibleadmin`
- Rocky Linux managed nodes
- Short module names, as preferred for faster typing

General ad-hoc command structure:

```bash
ansible <host-pattern> [-b] -m <module> -a "<arguments>"
```

| Part | Meaning |
|---|---|
| `three_tier_app` | Inventory host or group pattern |
| `-b` | Use privilege escalation (`become`) |
| `-m` | Select a module |
| `-a` | Supply arguments to the module |

---

## 2. How to use `ansible-doc`

### Display the complete documentation for a module

```bash
ansible-doc copy
```

### Display a short syntax summary

```bash
ansible-doc -s copy
```

### List available modules

```bash
ansible-doc -l
```

### Search the module list

```bash
ansible-doc -l | grep -i mount
```

### Show examples from the full documentation

```bash
ansible-doc copy
```

Inside the output, search for `EXAMPLES` by typing:

```text
/EXAMPLES
```

Press `q` to exit the documentation viewer.

> **Recommended approach:** Use `ansible-doc -s <module>` when you only need the main parameters. Use `ansible-doc <module>` when you need descriptions, notes, requirements, return values, and examples.

---

## 3. Common module reference

| # | Module | One-line definition and common usage | Documentation command |
|---:|---|---|---|
| 1 | `copy` | Copies a file or content from the control node to managed nodes. | `ansible-doc copy` |
| 2 | `command` | Executes a command directly without using a shell. | `ansible-doc command` |
| 3 | `raw` | Sends a command directly through SSH without requiring Python on the managed node. | `ansible-doc raw` |
| 4 | `shell` | Executes commands through a shell and supports pipes, redirects, variables, and command chaining. | `ansible-doc shell` |
| 5 | `file` | Manages files, directories, links, ownership, permissions, and file state. | `ansible-doc file` |
| 6 | `fetch` | Downloads files from managed nodes to the control node. | `ansible-doc fetch` |
| 7 | `get_url` | Downloads a file from an HTTP, HTTPS, or FTP URL to a managed node. | `ansible-doc get_url` |
| 8 | `lineinfile` | Adds, replaces, or removes a particular line in a text file. | `ansible-doc lineinfile` |
| 9 | `replace` | Replaces all text that matches a regular expression inside a file. | `ansible-doc replace` |
| 10 | `user` | Creates, modifies, locks, or removes user accounts. | `ansible-doc user` |
| 11 | `group` | Creates, modifies, or removes operating-system groups. | `ansible-doc group` |
| 12 | `yum` / `dnf` / `apt` | Installs, updates, or removes packages through a specific package manager. | `ansible-doc dnf` |
| 13 | `yum_repository` | Adds, modifies, enables, disables, or removes YUM/DNF repository definitions. | `ansible-doc yum_repository` |
| 14 | `package` | Manages packages through the package manager detected on the managed node. | `ansible-doc package` |
| 15 | `stat` | Retrieves information about a file, directory, or symbolic link without modifying it. | `ansible-doc stat` |
| 16 | `mount` | Manages active filesystem mounts and `/etc/fstab` entries. | `ansible-doc mount` |
| 17 | `setup` | Collects system information called Ansible facts from managed nodes. | `ansible-doc setup` |
| 18 | `service` | Starts, stops, restarts, enables, or disables services through a generic interface. | `ansible-doc service` |
| 19 | `systemd` | Manages systemd services, units, daemon reloads, and masking. | `ansible-doc systemd` |
| 20 | `debug` | Displays variables, values, and custom messages in a playbook. | `ansible-doc debug` |
| 21 | `uri` | Sends HTTP/HTTPS requests to websites and APIs from a managed node. | `ansible-doc uri` |
| 22 | `parted` | Creates, modifies, resizes, or removes disk partitions. | `ansible-doc parted` |
| 23 | `filesystem` | Creates a filesystem, such as XFS or ext4, on a block device. | `ansible-doc filesystem` |
| 24 | `lvg` | Creates, modifies, or removes an LVM volume group. | `ansible-doc lvg` |
| 25 | `lvol` | Creates, resizes, or removes an LVM logical volume. | `ansible-doc lvol` |
| 26 | `cron` | Creates, modifies, or removes scheduled cron jobs. | `ansible-doc cron` |

---

## 4. Quick module-selection guide

### 4.1 `command` vs `shell` vs `raw`

| Module | Use it when | Important point |
|---|---|---|
| `command` | Running a normal executable such as `uptime`, `lsblk`, or `hostname` | Does not interpret `|`, `>`, `&&`, `;`, `$VAR`, or wildcards through a shell |
| `shell` | The command requires pipes, redirects, shell variables, or multiple commands | Runs through a shell, so input must be handled carefully |
| `raw` | Python is missing or unusable on the managed node | Bypasses the normal Python-based module system |

Examples:

```bash
ansible three_tier_app -m command -a "uptime"
ansible three_tier_app -m shell -a "uptime; lsblk"
ansible three_tier_app -m raw -a "command -v python3"
```

The following fails because `command` treats `uptime;` as an executable name:

```bash
ansible three_tier_app -m command -a "uptime; lsblk"
```

### 4.2 `service` vs `systemd`

| Module | Best use |
|---|---|
| `service` | Portable service management across different init systems |
| `systemd` | systemd-specific features such as `daemon_reload` and masking |

### 4.3 `package` vs `dnf`/`yum`/`apt`

| Module | Best use |
|---|---|
| `package` | Portable playbooks that may run on different Linux distributions |
| `dnf` or `yum` | RHEL, Rocky Linux, AlmaLinux, or Fedora-specific options |
| `apt` | Debian or Ubuntu-specific package options |

### 4.4 `lineinfile` vs `replace`

| Module | Best use |
|---|---|
| `lineinfile` | Managing one specific configuration line |
| `replace` | Replacing every piece of text matching a regular expression |

---

## 5. Collection-based modules

Some modules are supplied by collections rather than only by `ansible-core`.

| Short name | Collection name |
|---|---|
| `mount` | `ansible.posix.mount` |
| `parted` | `community.general.parted` |
| `filesystem` | `community.general.filesystem` |
| `lvg` | `community.general.lvg` |
| `lvol` | `community.general.lvol` |

Check whether a module is available:

```bash
ansible-doc -l | grep -E 'mount|parted|filesystem|lvg|lvol'
```

List installed collections:

```bash
ansible-galaxy collection list
```

If necessary, install the collections:

```bash
ansible-galaxy collection install ansible.posix community.general
```

Short names can be used when Ansible can resolve the installed collection. The fully qualified collection name is useful when there may be ambiguity or when documentation specifically requires it.

---

## 6. Practice commands for the personal lab

> Review commands that modify users, disks, LVM, repositories, services, or cron jobs before running them.

### 6.1 Copy content to all managed nodes

```bash
ansible three_tier_app -m copy \
  -a 'content="Hello from Ansible\n" dest=/tmp/hello.txt mode=0644'
```

### 6.2 Run a simple command

```bash
ansible three_tier_app -m command -a "uptime"
```

### 6.3 Run a low-level command with `raw`

```bash
ansible three_tier_app -m raw -a "command -v python3"
```

### 6.4 Use a pipe through `shell`

```bash
ansible three_tier_app -m shell -a "ps -ef | systemctl is-active sshd"
```

### 6.5 Create a directory

```bash
ansible three_tier_app -m file \
  -a "path=/tmp/ansible-lab state=directory mode=0755"
```

### 6.6 Fetch a file to the control node

```bash
ansible three_tier_app -m fetch \
  -a "src=/tmp/hello.txt dest=./lab-output/"
```

### 6.7 Download a file to managed nodes

```bash
ansible three_tier_app -m get_url \
  -a "url=https://example.com/ dest=/tmp/example.html mode=0644"
```

### 6.8 Manage one configuration line

```bash
ansible three_tier_app -b -m lineinfile -a \
  'path=/etc/ssh/sshd_config regexp="^\s*#?\s*Banner\s+.*$" line="Banner /etc/ssh/banner.txt" backup=yes validate="/usr/sbin/sshd -t -f %s"'
```

### 6.9 Replace matching text

```bash
ansible three_tier_app -m replace \
  -a 'path=/tmp/hello.txt regexp="Ansible" replace="Automation" backup=yes'
```

### 6.10 Create a practice user

```bash
ansible three_tier_app -b -m user \
  -a "name=labuser state=present create_home=yes shell=/bin/bash"
```

### 6.11 Create a practice group

```bash
ansible three_tier_app -b -m group \
  -a "name=labgroup state=present"
```

### 6.12 Install a package on Rocky Linux

```bash
ansible three_tier_app -b -m dnf \
  -a "name=httpd state=present"
```

### 6.13 Manage a DNF repository

First study its parameters:

```bash
ansible-doc -s yum_repository
```

Repository changes affect package sources, so use a trusted URL and test on one node first:

```bash
ansible three_tier_app -b -m yum_repository --limit node1 -a \
  'name=example description="Example Repository" baseurl=https://repo.example.com/rocky/9/x86_64 enabled=no gpgcheck=yes'
```

### 6.14 Install a package through the generic interface

```bash
ansible three_tier_app -b -m package \
  -a "name=git state=present"
```

### 6.15 Inspect a file

```bash
ansible three_tier_app -m stat \
  -a "path=/tmp/hello.txt"
```

### 6.16 Study mount management safely

```bash
ansible-doc -s mount
```

Example for a prepared device and mount point:

```bash
ansible three_tier_app -b -m mount --limit node1 -a \
  "path=/data src=/dev/mapper/vg_lab-lv_data fstype=xfs state=mounted"
```

### 6.17 Collect operating-system facts

```bash
ansible three_tier_app -m setup -a "filter=ansible_distribution*"
```

### 6.18 Manage a service through the generic interface

```bash
ansible three_tier_app -b -m service \
  -a "name=sshd state=started enabled=yes"
```

### 6.19 Manage a systemd service

```bash
ansible three_tier_app -b -m systemd \
  -a "name=sshd state=restarted enabled=yes"
```

### 6.20 Display a variable with `debug`

`debug` is mainly used inside playbooks:

```yaml
- name: Display the inventory hostname
  debug:
    var: inventory_hostname
```

### 6.21 Check a web endpoint

```bash
ansible web -m uri \
  -a "url=http://localhost status_code=200 return_content=no"
```

### 6.22–6.25 Storage modules

The following modules can destroy data if the wrong device is selected:

```bash
ansible-doc -s parted
ansible-doc -s filesystem
ansible-doc -s lvg
ansible-doc -s lvol
```

Before using them, verify disks on one node:

```bash
ansible three_tier_app -m command -a "lsblk -f" --limit node1
```

Typical workflow:

1. `parted` creates a partition.
2. `lvg` creates a volume group.
3. `lvol` creates a logical volume.
4. `filesystem` creates a filesystem.
5. `mount` mounts it and manages `/etc/fstab`.

### 6.26 Create a cron job

```bash
ansible three_tier_app -b -m cron -a \
  'name="daily lab cleanup" minute=0 hour=0 job="/usr/local/sbin/lab-cleanup.sh" state=present'
```

---

## 7. Important safety and idempotency notes

### Idempotency

An operation is **idempotent** when repeated execution keeps the system in the requested state without reporting an unnecessary change.

Modules such as `copy`, `file`, `user`, `group`, `dnf`, `service`, and `lineinfile` normally check the existing state before making a change.

The `command`, `shell`, and `raw` modules cannot always determine whether their commands changed the system. They may report `CHANGED` whenever they execute.

### Use `--check` when supported

```bash
ansible three_tier_app -b -m dnf \
  -a "name=httpd state=present" --check
```

Not every module or command provides complete check-mode support.

### Test on one node first

```bash
ansible three_tier_app -b -m dnf \
  -a "name=httpd state=present" --limit node1
```

### Use privilege escalation only when necessary

Use `-b` for tasks requiring administrative privileges, including package installation, service management, account management, and changes under `/etc`.

---

## 8. Quick revision questions

1. Which module copies a local control-node file to managed nodes?
2. Which module retrieves a file from managed nodes?
3. Why does `command` not process `|`, `>`, or `;`?
4. When should `raw` be used instead of `command`?
5. What is the difference between `lineinfile` and `replace`?
6. What is the difference between `package` and `dnf`?
7. Which module collects Ansible facts?
8. Which modules form the usual LVM storage workflow?
9. Why should storage commands first be tested with `--limit node1`?
10. Why can `shell` report `CHANGED` on every execution?

### Short answers

1. `copy`
2. `fetch`
3. It executes a program directly without a shell.
4. When Python is unavailable or unusable on the managed node.
5. `lineinfile` manages a specific line; `replace` changes all matching text.
6. `package` is generic; `dnf` provides DNF-specific behavior and options.
7. `setup`
8. `parted`, `lvg`, `lvol`, `filesystem`, and `mount`
9. To reduce risk and verify the operation before applying it to all nodes.
10. It generally cannot determine whether an arbitrary shell command changed the system.

---

## Final recommendation

Do not try to memorize every module parameter. Learn the purpose of each module, practice the most common arguments, and use `ansible-doc -s <module>` whenever you need the exact syntax.
