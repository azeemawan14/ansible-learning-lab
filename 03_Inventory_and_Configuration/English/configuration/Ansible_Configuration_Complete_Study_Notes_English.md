# Ansible Configuration — Complete Study Notes

This guide explains `ansible.cfg` from the fundamentals through practical use. The examples match a Rocky Linux Ansible lab.

## Index

1. [What is Ansible configuration?](#1-what-is-ansible-configuration)
2. [Inventory file vs configuration file](#2-inventory-file-vs-configuration-file)
3. [Example project structure](#3-example-project-structure)
4. [Complete ansible.cfg example](#4-complete-ansiblecfg-example)
5. [[defaults] section](#5-defaults-section)
6. [inventory](#6-inventory)
7. [host_key_checking](#7-host_key_checking)
8. [remote_user](#8-remote_user)
9. [ask_pass](#9-ask_pass)
10. [private_key_file](#10-private_key_file)
11. [roles_path and collections_paths](#11-roles_path-and-collections_paths)
12. [[privilege_escalation] section](#12-privilege_escalation-section)
13. [become, sudo, and root](#13-become-sudo-and-root)
14. [Configuration search order](#14-configuration-search-order)
15. [Basic configuration precedence](#15-basic-configuration-precedence)
16. [Find the active configuration file](#16-find-the-active-configuration-file)
17. [Configuration validation commands](#17-configuration-validation-commands)
18. [Common problems and troubleshooting](#18-common-problems-and-troubleshooting)
19. [Security recommendations](#19-security-recommendations)
20. [Quick-reference table](#20-quick-reference-table)

---

## 1. What is Ansible configuration?

Ansible configuration is the collection of settings that controls Ansible's default behavior.

It can determine:

- Where Ansible reads its inventory.
- Which SSH user connects to managed nodes.
- Which SSH private key is used.
- Whether Ansible asks for an SSH password.
- Whether SSH host keys are verified.
- Which privilege-escalation method is used.
- Which privileged account Ansible becomes.
- Where Ansible searches for roles and collections.

These settings are commonly stored in a file named `ansible.cfg`.

### Simple definition

> `ansible.cfg` controls Ansible's default behavior, including inventory, SSH, security, roles, collections, and privilege escalation.

---

## 2. Inventory file vs configuration file

| File | Main question | Purpose |
|---|---|---|
| Inventory | Which machines should Ansible manage? | Defines hosts, groups, connection addresses, and host/group variables |
| `ansible.cfg` | How should Ansible connect to and manage them? | Defines default inventory, SSH, key, role, collection, and privilege-escalation settings |

### Inventory example

```ini
[web]
node1 ansible_host=192.168.1.154

[app]
node2 ansible_host=192.168.1.185

[db]
node3 ansible_host=192.168.1.190

[all:vars]
ansible_user=ansibleadmin
ansible_python_interpreter=/usr/bin/python3
```

### Configuration example

```ini
[defaults]
inventory = ./inventory
remote_user = ansibleadmin
private_key_file = /home/ansibleadmin/.ssh/ansible-key
```

`ansible_python_interpreter` normally belongs in inventory, `group_vars`, or `host_vars` because it describes the Python executable on a managed host.

---

## 3. Example project structure

```text
/home/ansibleadmin/automation/
├── ansible.cfg
├── inventory/
│   └── nodes
├── playbooks/
├── roles/
└── collections/
```

Keeping `ansible.cfg` inside the project makes the project self-contained and allows different projects to use different settings.

Enter the project directory before running Ansible:

```bash
cd /home/ansibleadmin/automation
```

---

## 4. Complete ansible.cfg example

```ini
[defaults]
inventory = ./inventory/nodes
host_key_checking = True
remote_user = ansibleadmin
ask_pass = False
private_key_file = /home/ansibleadmin/.ssh/ansible-key
roles_path = ./roles
collections_paths = ./collections

[privilege_escalation]
become_method = sudo
become_user = root
become_ask_pass = False
```

> If the inventory is a file named `inventory` in the project root, use `inventory = ./inventory`. Always match the setting to the actual project structure.

---

## 5. `[defaults]` section

```ini
[defaults]
```

This section contains general Ansible settings such as the inventory path, SSH user, SSH private key, host-key checking, roles, and collections.

Settings use the `key = value` format:

```ini
remote_user = ansibleadmin
```

Spaces around the equal sign are optional, but using them consistently improves readability.

---

## 6. `inventory`

```ini
inventory = ./inventory/nodes
```

This tells Ansible where to read hosts and groups.

`./` means the current project directory. If the current directory is:

```text
/home/ansibleadmin/automation
```

then:

```text
./inventory/nodes
```

resolves to:

```text
/home/ansibleadmin/automation/inventory/nodes
```

With inventory configured, run:

```bash
ansible all -m ping
```

Without the configuration setting, specify the inventory explicitly:

```bash
ansible all -m ping -i ./inventory/nodes
```

Validate the inventory:

```bash
ansible-inventory --graph
```

---

## 7. `host_key_checking`

```ini
host_key_checking = True
```

This instructs Ansible to verify each managed node's SSH host key.

An SSH host key identifies the server. An unexpected host-key change can indicate a rebuilt VM, an incorrect destination, or a security problem.

On the first connection, verify and accept the fingerprint manually:

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node1
```

Some practice labs use:

```ini
host_key_checking = False
```

This avoids first-connection prompts, but `True` is the better production and security-focused setting.

Find a known-host entry:

```bash
ssh-keygen -F node1
```

Remove a confirmed outdated entry:

```bash
ssh-keygen -R node1
ssh-keygen -R 192.168.1.154
```

Verify the new fingerprint before accepting it.

---

## 8. `remote_user`

```ini
remote_user = ansibleadmin
```

This defines the default user for SSH connections to managed nodes.

The equivalent manual connection is:

```bash
ssh ansibleadmin@node1
```

Test the remote user:

```bash
ansible all -m command -a "whoami"
```

Expected output:

```text
ansibleadmin
```

Override the user for one command:

```bash
ansible all -m ping -u anotheruser
```

The related inventory variable is:

```ini
ansible_user=ansibleadmin
```

An applicable `ansible_user` inventory variable can override the configuration default for that host or group.

---

## 9. `ask_pass`

```ini
ask_pass = False
```

Ansible will not ask for an SSH login password. It assumes that SSH key authentication or another non-interactive authentication method is configured.

Test the key directly:

```bash
ssh -i /home/ansibleadmin/.ssh/ansible-key ansibleadmin@node1
```

Temporarily request an SSH password:

```bash
ansible all -m ping --ask-pass
```

Short option:

```bash
ansible all -m ping -k
```

SSH key authentication is preferable for automation.

---

## 10. `private_key_file`

```ini
private_key_file = /home/ansibleadmin/.ssh/ansible-key
```

This specifies the private key Ansible uses for SSH connections.

Equivalent manual command:

```bash
ssh -i /home/ansibleadmin/.ssh/ansible-key ansibleadmin@node1
```

Inspect the key files:

```bash
ls -l /home/ansibleadmin/.ssh/ansible-key*
```

Recommended key permissions:

```bash
chmod 600 /home/ansibleadmin/.ssh/ansible-key
chmod 644 /home/ansibleadmin/.ssh/ansible-key.pub
```

Never distribute the private key. Only the public key should be installed in the remote user's `authorized_keys` file.

Override the key for one command:

```bash
ansible all -m ping --private-key ~/.ssh/another-key
```

---

## 11. `roles_path` and `collections_paths`

### Roles path

```ini
roles_path = ./roles
```

This tells Ansible where to search for local roles.

A role is a reusable automation structure containing organized tasks, handlers, templates, files, defaults, variables, and metadata.

Example:

```text
roles/
└── webserver/
    ├── tasks/
    ├── handlers/
    ├── templates/
    ├── files/
    └── defaults/
```

### Collections path

```ini
collections_paths = ./collections
```

A collection is a packaged set of Ansible content such as modules, plugins, roles, and documentation.

Check the effective paths:

```bash
ansible-config dump --only-changed | \
grep -E 'COLLECTIONS_PATHS|DEFAULT_ROLES_PATH'
```

Remember: `collections_paths` is plural, while `roles_path` is singular.

---

## 12. `[privilege_escalation]` section

```ini
[privilege_escalation]
```

This section controls how Ansible changes from the normal SSH user to a privileged account.

Normal connection:

```text
Control node → SSH → ansibleadmin
```

With privilege escalation:

```text
Control node → SSH → ansibleadmin → sudo → root
```

---

## 13. `become`, sudo, and root

### `become_method`

```ini
become_method = sudo
```

Ansible uses `sudo` for privilege escalation.

### `become_user`

```ini
become_user = root
```

The target account after escalation is `root`.

### `become_ask_pass`

```ini
become_ask_pass = False
```

Ansible will not request a sudo password. Passwordless sudo must therefore be configured on the managed nodes.

Direct test:

```bash
sudo -n whoami
```

Expected output:

```text
root
```

`-n` means non-interactive. The command fails immediately instead of prompting if a password is required.

### Normal and privileged commands

Normal user:

```bash
ansible all -m command -a "whoami"
```

Expected:

```text
ansibleadmin
```

Become root:

```bash
ansible all -b -m command -a "whoami"
```

Expected:

```text
root
```

`-b` is the short form of `--become`.

Request a sudo password when needed:

```bash
ansible all -b -K -m command -a "whoami"
```

`-K` is the short form of `--ask-become-pass`.

### Optional automatic become setting

To enable privilege escalation by default:

```ini
become = True
```

For a learning lab, it can be clearer to omit this setting and use `-b` only for commands that require root privileges.

---

## 14. Configuration search order

Ansible normally searches for a configuration file in this order:

1. The path specified by the `ANSIBLE_CONFIG` environment variable
2. `ansible.cfg` in the current working directory
3. `.ansible.cfg` in the user's home directory
4. `/etc/ansible/ansible.cfg`

Ansible uses the first valid configuration file it finds. It does not normally merge these four configuration files.

### 1. Environment variable

```bash
export ANSIBLE_CONFIG=/home/ansibleadmin/automation/ansible.cfg
```

Check it:

```bash
echo "$ANSIBLE_CONFIG"
```

Remove the temporary override:

```bash
unset ANSIBLE_CONFIG
```

The variable name is uppercase:

```text
ANSIBLE_CONFIG
```

### 2. Current working directory

```text
./ansible.cfg
```

Check the current working directory:

```bash
pwd
```

A project-specific configuration file is usually the best approach.

### 3. User home directory

```text
~/.ansible.cfg
```

The leading dot is part of the filename. This configuration applies to the corresponding Linux user.

### 4. System-level configuration

```text
/etc/ansible/ansible.cfg
```

This is the system-wide fallback configuration.

### Important security note

Ansible may refuse to automatically load `ansible.cfg` from a world-writable current directory. Keep the project directory ownership and permissions secure.

---

## 15. Basic configuration precedence

Ansible settings can come from several sources. A useful basic model is:

```text
Configuration setting
        ↓
Command-line option
        ↓
Playbook keyword
        ↓
Ansible variable
```

The complete precedence system is more detailed, and the exact result depends on the setting category.

### SSH user example

Configuration:

```ini
remote_user = ansibleadmin
```

Inventory:

```ini
node1 ansible_user=khalid
```

For `node1`, the applicable `ansible_user=khalid` connection variable overrides the default `remote_user` setting.

### Inventory selection for one command

```bash
ansible all -m ping -i ./different-inventory
```

### Private key selection for one command

```bash
ansible all -m ping --private-key ~/.ssh/another-key
```

When troubleshooting, inspect both the active configuration and the effective host variables.

---

## 16. Find the active configuration file

Run:

```bash
ansible --version
```

Look for:

```text
config file = /home/ansibleadmin/automation/ansible.cfg
```

Also check:

```bash
echo "${ANSIBLE_CONFIG:-not set}"
pwd
```

If Ansible displays `/etc/ansible/ansible.cfg` instead of the project file, possible causes include:

- You are not inside the project directory.
- The project filename or path is incorrect.
- The project directory is insecure or world-writable.
- `ANSIBLE_CONFIG` points somewhere else.

Recommended check:

```bash
cd /home/ansibleadmin/automation
ansible --version
```

---

## 17. Configuration validation commands

Display settings that differ from their defaults:

```bash
ansible-config dump --only-changed
```

Display the complete effective configuration:

```bash
ansible-config dump
```

List available configuration options:

```bash
ansible-config list
```

Generate a disabled example configuration without overwriting the active file:

```bash
ansible-config init --disabled > ansible.cfg.example
```

Display the inventory hierarchy:

```bash
ansible-inventory --graph
```

Display effective variables for a host:

```bash
ansible-inventory --host node1
```

List inventory hosts:

```bash
ansible all --list-hosts
```

Test Ansible connectivity:

```bash
ansible all -m ping
```

Test the normal remote user:

```bash
ansible all -m command -a "whoami"
```

Test privilege escalation:

```bash
ansible all -b -m command -a "whoami"
```

---

## 18. Common problems and troubleshooting

### `No inventory was parsed`

Check:

```bash
pwd
ls -l ./inventory/nodes
ansible --version
ansible-inventory --graph
```

Compare the configured inventory path with the actual file location.

### The wrong configuration file is active

```bash
ansible --version
echo "${ANSIBLE_CONFIG:-not set}"
pwd
```

Then enter the project directory and check again:

```bash
cd /home/ansibleadmin/automation
ansible --version
```

### Ansible asks for an SSH password

Test direct key authentication:

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node1
```

Verify:

- The private-key path is correct.
- Private-key permissions are secure.
- The public key is present in the remote `authorized_keys` file.
- The remote username is correct.

### `Permission denied (publickey)`

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/ansible-key
ssh -vvv -i ~/.ssh/ansible-key ansibleadmin@node1
```

Verbose SSH output shows which keys the client offers.

### Host-key verification failed

First investigate why the key changed. If the VM was legitimately rebuilt and the new fingerprint has been verified:

```bash
ssh-keygen -R node1
ssh-keygen -R 192.168.1.154
ssh -i ~/.ssh/ansible-key ansibleadmin@node1
```

### Become or sudo fails

```bash
ansible all -m command -a "sudo -n whoami"
```

Direct managed-node test:

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node1
sudo -n whoami
```

### Python interpreter warning

Define the interpreter in inventory when appropriate:

```ini
[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

Verify the remote path with the `raw` module, which does not depend on remote Python:

```bash
ansible all -m raw -a "command -v python3"
```

---

## 19. Security recommendations

- Run Ansible as a normal administrative user, not through direct root SSH login.
- Use SSH key authentication for managed nodes.
- Never share the private SSH key with students or other administrators.
- Prefer installing each administrator's own public key.
- Keep `host_key_checking = True` in production.
- In production, consider restricting sudo to required commands instead of granting unrestricted `NOPASSWD:ALL`.
- Store `ansible.cfg`, inventory, and playbooks in version control.
- Never commit private keys, passwords, or unencrypted secrets to Git.
- Use Ansible Vault for sensitive variables.
- Verify configuration changes with `ansible-config dump --only-changed`.

---

## 20. Quick-reference table

| Setting or command | Purpose |
|---|---|
| `[defaults]` | General/default settings section |
| `inventory` | Inventory path |
| `host_key_checking` | Controls SSH server identity verification |
| `remote_user` | Default SSH login user |
| `ask_pass` | Controls SSH password prompting |
| `private_key_file` | SSH private-key path |
| `roles_path` | Role search path |
| `collections_paths` | Collection search paths |
| `[privilege_escalation]` | Privileged-user settings section |
| `become_method` | Escalation method, such as `sudo` |
| `become_user` | Target account after escalation |
| `become_ask_pass` | Controls sudo password prompting |
| `ANSIBLE_CONFIG` | Explicit configuration-file environment variable |
| `-b` | Enables `--become` |
| `-K` | Requests the become/sudo password |
| `-k` | Requests the SSH login password |
| `-i` | Selects an inventory for one command |
| `-u` | Selects the remote user for one command |
| `ansible --version` | Shows versions and the active configuration file |
| `ansible-config dump --only-changed` | Shows changed effective settings |
| `ansible-inventory --graph` | Shows the inventory hierarchy |
| `ansible all -m ping` | Tests Ansible connectivity |

## Final summary

The inventory answers:

> **Which machines should Ansible manage?**

`ansible.cfg` answers:

> **How should Ansible connect to and manage those machines?**

Recommended verification workflow:

```bash
cd /home/ansibleadmin/automation
echo "${ANSIBLE_CONFIG:-not set}"
pwd
ansible --version
ansible-config dump --only-changed
ansible-inventory --graph
ansible all -m ping
ansible all -m command -a "whoami"
ansible all -b -m command -a "whoami"
```

This sequence verifies configuration-file selection, effective settings, inventory parsing, SSH connectivity, the remote user, and privilege escalation.
