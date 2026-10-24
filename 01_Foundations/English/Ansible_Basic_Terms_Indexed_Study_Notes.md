# Ansible Basic Terms — Indexed Study Notes

> These notes use short module names for faster hands-on practice.

## Index

1. [Ansible overview](#1-ansible-overview)
2. [Control node](#2-control-node)
3. [Managed nodes](#3-managed-nodes)
4. [Inventory file](#4-inventory-file)
5. [Ansible configuration file](#5-ansible-configuration-file)
6. [Ad-hoc commands](#6-ad-hoc-commands)
7. [Modules](#7-modules)
8. [Module arguments](#8-module-arguments)
9. [State values](#9-state-values)
10. [YAML basics](#10-yaml-basics)
11. [Task](#11-task)
12. [Play](#12-play)
13. [Playbook](#13-playbook)
14. [Variables](#14-variables)
15. [Facts](#15-facts)
16. [Loops](#16-loops)
17. [Conditions](#17-conditions)
18. [Register](#18-register)
19. [Handlers and notify](#19-handlers-and-notify)
20. [Become](#20-become)
21. [Idempotency](#21-idempotency)
22. [Templates](#22-templates)
23. [Roles](#23-roles)
24. [Collections](#24-collections)
25. [Ansible Vault](#25-ansible-vault)
26. [Verification commands](#26-verification-commands)
27. [Recommended learning order](#27-recommended-learning-order)

---

## Quick-reference table

| Term | Simple meaning | Example |
|---|---|---|
| Control node | Machine where Ansible is installed and commands are executed | `ansible-server` |
| Managed node | Remote machine controlled by Ansible | `node1`, `node2`, `node3` |
| Inventory | File containing managed hosts, groups and connection variables | `inventory/nodes` |
| Configuration file | Controls Ansible's default behavior | `ansible.cfg` |
| Ad-hoc command | One Ansible command for a quick task | `ansible all -m ping` |
| Module | Tool that performs one kind of operation | `dnf`, `copy`, `file` |
| Argument | Information supplied to a module | `name=httpd state=present` |
| YAML | Language used for Ansible playbooks | `.yml` or `.yaml` |
| Task | One action inside a play | Install HTTPD |
| Play | Connects target hosts with a list of tasks | Configure `web` hosts |
| Playbook | YAML file containing one or more plays | `install-httpd.yml` |
| Variable | Named reusable value | `web_package: httpd` |
| Fact | Information collected from a managed node | OS, memory or IP address |
| Loop | Repeats a task for multiple items | Create several users |
| Condition | Determines whether a task runs | `when:` |
| Register | Saves task output in a variable | `register: result` |
| Handler | Task triggered by a change | Restart HTTPD |
| Template | Dynamic file containing variables | `httpd.conf.j2` |
| Role | Standard reusable automation structure | `roles/webserver/` |
| Become | Uses privilege escalation | `become: true` |
| Idempotency | Maintains the desired state without unnecessary changes | Installed package remains installed |

---

## 1. Ansible overview

Ansible is an agentless automation and configuration-management tool. The control node connects to managed nodes, normally through SSH, and applies a desired state.

Common uses include:

- Installing and removing packages
- Managing services
- Creating users and groups
- Deploying files and configurations
- Managing scheduled jobs
- Configuring firewalls and storage
- Deploying applications

[Back to Index](#index)

## 2. Control node

The control node is the machine where Ansible is installed and where commands and playbooks are executed.

Your control node is:

```text
ansible-server
```

```bash
ansible all -m ping
ansible-playbook install-httpd.yml
```

[Back to Index](#index)

## 3. Managed nodes

Managed nodes are the remote machines controlled by Ansible.

```text
node1
node2
node3
```

Ansible normally connects to them through SSH. Ansible itself does not normally need to be installed on Linux managed nodes, but a suitable Python interpreter is generally required.

[Back to Index](#index)

## 4. Inventory file

The inventory defines hosts, groups and connection variables.

```ini
[web]
node1 ansible_host=192.168.1.154

[app]
node2 ansible_host=192.168.1.185

[db]
node3 ansible_host=192.168.1.190

[three_tier_app:children]
web
app
db

[all:vars]
ansible_user=ansibleadmin
ansible_python_interpreter=/usr/bin/python3
```

In this entry:

```ini
node1 ansible_host=192.168.1.154
```

| Value | Meaning |
|---|---|
| `node1` | `inventory_hostname` — Ansible's inventory name |
| `192.168.1.154` | `ansible_host` — actual connection address |

Check the inventory:

```bash
ansible-inventory --graph
ansible-inventory --host node1
ansible-inventory --list
```

[Back to Index](#index)

## 5. Ansible configuration file

`ansible.cfg` supplies defaults so they do not need to be repeated in every command.

```ini
[defaults]
inventory = ./inventory/nodes
remote_user = ansibleadmin
host_key_checking = True
ask_pass = False
private_key_file = /home/ansibleadmin/.ssh/ansible-key

[privilege_escalation]
become_method = sudo
become_user = root
become_ask_pass = False
```

Check the active configuration:

```bash
ansible --version
ansible-config dump --only-changed
```

Configuration-file search order:

1. File specified by the `ANSIBLE_CONFIG` environment variable
2. `ansible.cfg` in the current working directory
3. `~/.ansible.cfg`
4. `/etc/ansible/ansible.cfg`

Ansible uses the first configuration file it finds.

[Back to Index](#index)

## 6. Ad-hoc commands

An ad-hoc command performs a quick, one-time task without creating a playbook.

```bash
ansible TARGET -m MODULE -a "ARGUMENTS"
```

Examples:

```bash
ansible all -m ping
ansible web -m dnf -a "name=httpd state=present" -b
ansible all -m command -a "uptime"
```

Use ad-hoc commands for quick checks, simple changes and troubleshooting. Use playbooks for repeatable or multi-step automation.

[Back to Index](#index)

## 7. Modules

A module performs a particular type of operation.

| Module | Purpose |
|---|---|
| `ping` | Test Ansible connectivity and Python execution |
| `command` | Run an ordinary command |
| `shell` | Run a command requiring shell features |
| `file` | Manage files, directories, links and permissions |
| `copy` | Copy files or write content |
| `dnf` | Manage Rocky/RHEL packages |
| `service` | Manage services |
| `user` | Manage users |
| `group` | Manage groups |
| `cron` | Manage cron jobs |
| `debug` | Display messages and variables |
| `setup` | Gather system facts |

Read module documentation:

```bash
ansible-doc file
ansible-doc -s file
```

[Back to Index](#index)

## 8. Module arguments

Arguments tell a module what resource to manage and which state is required.

```bash
ansible web -m dnf -a "name=httpd state=present" -b
```

| Part | Meaning |
|---|---|
| `web` | Target group |
| `dnf` | Module |
| `name=httpd` | Package argument |
| `state=present` | Desired state |
| `-b` | Use privilege escalation |

Arguments are module-specific. Use `ansible-doc -s MODULE` to see the available arguments.

[Back to Index](#index)

## 9. State values

`state` describes the desired final condition. Its permitted values depend on the module.

### Package states

| State | Meaning |
|---|---|
| `present` | Package must be installed |
| `absent` | Package must not be installed |
| `latest` | Package must be at the latest available repository version |

```bash
ansible web -m dnf -a "name=httpd state=present" -b
ansible web -m dnf -a "name=httpd state=latest" -b
ansible web -m dnf -a "name=httpd state=absent" -b
```

Use `latest` carefully in production because it can introduce an unplanned upgrade.

### File states

| State | Meaning |
|---|---|
| `file` | Path must be a regular file; it does not create a missing file |
| `touch` | Create an empty file if necessary |
| `directory` | Directory must exist |
| `link` | Symbolic link must exist |
| `hard` | Hard link must exist |
| `absent` | File, directory or link must not exist |

```bash
ansible all -m file -a "path=/tmp/lab state=directory"
ansible all -m file -a "path=/tmp/lab state=absent"
```

### Service states

| State | Meaning |
|---|---|
| `started` | Service must be running |
| `stopped` | Service must not be running |
| `restarted` | Restart the service whenever the task executes |
| `reloaded` | Reload its configuration |

```yaml
service:
  name: httpd
  state: started
  enabled: true
```

`state: started` controls the service now. `enabled: true` configures it to start after reboot.

[Back to Index](#index)

## 10. YAML basics

Playbooks are written in YAML.

- Use spaces, never tabs.
- Indentation defines structure.
- Use `-` for list items.
- Use `key: value` for mappings.
- Use consistent two-space indentation.
- Begin a playbook with `---` as a good convention.

```yaml
---
- name: Configure web servers
  hosts: web
  become: true

  tasks:
    - name: Install HTTPD
      dnf:
        name: httpd
        state: present
```

[Back to Index](#index)

## 11. Task

A task is one action performed by one module.

```yaml
- name: Install HTTPD
  dnf:
    name: httpd
    state: present
```

A good task name describes the desired action clearly.

[Back to Index](#index)

## 12. Play

A play maps a group of hosts to variables, options, tasks and handlers.

```yaml
- name: Configure web servers
  hosts: web
  become: true

  tasks:
    - name: Install HTTPD
      dnf:
        name: httpd
        state: present

    - name: Start HTTPD
      service:
        name: httpd
        state: started
        enabled: true
```

The entire block above is one play.

[Back to Index](#index)

## 13. Playbook

A playbook is a YAML file containing one or more plays.

```yaml
---
- name: Configure web servers
  hosts: web
  tasks:
    # Web tasks

- name: Configure database servers
  hosts: db
  tasks:
    # Database tasks
```

```bash
ansible-playbook site.yml
```

[Back to Index](#index)

## 14. Variables

A variable stores a reusable value.

```yaml
vars:
  web_package: httpd
  web_service: httpd

tasks:
  - name: Install the web package
    dnf:
      name: "{{ web_package }}"
      state: present
```

Quote a value when it begins with a Jinja2 expression:

```yaml
name: "{{ web_package }}"
```

Variables can come from inventory, playbooks, `group_vars`, `host_vars`, roles, facts, registered output and command-line extra variables.

[Back to Index](#index)

## 15. Facts

Facts are system details collected from managed nodes.

| Fact | Example information |
|---|---|
| `ansible_distribution` | `Rocky` |
| `ansible_distribution_version` | `9.8` |
| `ansible_os_family` | `RedHat` |
| `ansible_hostname` | `node1` |
| `ansible_fqdn` | `node1.nitclasses.com` |
| `ansible_architecture` | `x86_64` |
| `ansible_kernel` | Running kernel version |

```bash
ansible all -m setup
ansible all -m setup -a "filter=ansible_distribution*"
```

```yaml
- name: Display the operating system
  debug:
    msg: "{{ inventory_hostname }} runs {{ ansible_distribution }}"
```

Playbooks gather facts by default unless you set `gather_facts: false`.

[Back to Index](#index)

## 16. Loops

A loop repeats a task for multiple items.

```yaml
- name: Create application users
  user:
    name: "{{ item }}"
    state: present
  loop:
    - alice
    - bob
    - carol
```

For packages, a direct list is normally better than a loop:

```yaml
- name: Install required packages
  dnf:
    name:
      - httpd
      - git
      - vim
    state: present
```

[Back to Index](#index)

## 17. Conditions

`when` determines whether a task should execute.

```yaml
- name: Install HTTPD on Red Hat-family systems
  dnf:
    name: httpd
    state: present
  when: ansible_os_family == "RedHat"
```

Do not add Jinja2 braces around a normal `when` expression.

[Back to Index](#index)

## 18. Register

`register` saves a task result in a variable.

```yaml
- name: Check system uptime
  command: uptime
  register: uptime_result
  changed_when: false

- name: Display uptime
  debug:
    var: uptime_result.stdout
```

| Field | Meaning |
|---|---|
| `stdout` | Normal output |
| `stderr` | Error output |
| `rc` | Return code |
| `changed` | Whether Ansible reported a change |
| `failed` | Whether the task failed |

[Back to Index](#index)

## 19. Handlers and notify

A handler is normally triggered only when a notifying task reports a change.

```yaml
tasks:
  - name: Deploy HTTPD configuration
    copy:
      src: httpd.conf
      dest: /etc/httpd/conf/httpd.conf
    notify: Restart HTTPD

handlers:
  - name: Restart HTTPD
    service:
      name: httpd
      state: restarted
```

If the copied configuration does not change, the handler does not run.

[Back to Index](#index)

## 20. Become

`become: true` enables privilege escalation, normally through `sudo`.

```yaml
- name: Configure web servers
  hosts: web
  become: true
```

It is generally needed for packages, services, users, firewalls and system files. Ansible can log in as `ansibleadmin` and then use `sudo`; direct root SSH login is unnecessary.

[Back to Index](#index)

## 21. Idempotency

Idempotency means repeatedly applying the same automation maintains the desired state without unnecessary changes.

```yaml
- name: Ensure HTTPD is installed
  dnf:
    name: httpd
    state: present
```

```text
First run  → Package is missing → installed → changed
Second run → Package exists     → no change → ok
```

The task still executes and checks the state; it does not reinstall the package unnecessarily.

[Back to Index](#index)

## 22. Templates

A template is a dynamic text file, normally ending in `.j2`, that can contain variables and Jinja2 expressions.

Template file `index.html.j2`:

```html
<h1>Welcome to {{ inventory_hostname }}</h1>
```

Playbook task:

```yaml
- name: Deploy the website page
  template:
    src: index.html.j2
    dest: /var/www/html/index.html
    mode: "0644"
```

[Back to Index](#index)

## 23. Roles

A role organizes reusable automation into a standard directory structure.

```text
roles/webserver/
├── defaults/main.yml
├── files/
├── handlers/main.yml
├── tasks/main.yml
├── templates/
└── vars/main.yml
```

Create a role:

```bash
ansible-galaxy role init roles/webserver
```

Use it:

```yaml
- name: Configure web servers
  hosts: web
  become: true
  roles:
    - webserver
```

[Back to Index](#index)

## 24. Collections

A collection packages related modules, plugins, roles and documentation.

Built-in modules such as `copy`, `file`, and `dnf` can be used with the short names you prefer. Some external modules require their collection to be installed first.

```bash
ansible-galaxy collection list
ansible-galaxy collection install ansible.posix
```

[Back to Index](#index)

## 25. Ansible Vault

Ansible Vault encrypts sensitive Ansible data such as passwords.

```bash
ansible-vault create secrets.yml
ansible-vault edit secrets.yml
ansible-vault view secrets.yml
```

Run a playbook and request the Vault password:

```bash
ansible-playbook site.yml --ask-vault-pass
```

Never store real passwords, private keys or tokens as unencrypted plain text in Git.

[Back to Index](#index)

## 26. Verification commands

| Purpose | Command |
|---|---|
| Check Ansible version and config path | `ansible --version` |
| Check changed configuration | `ansible-config dump --only-changed` |
| Display inventory graph | `ansible-inventory --graph` |
| Display host variables | `ansible-inventory --host node1` |
| Test connectivity | `ansible all -m ping` |
| Check playbook syntax | `ansible-playbook --syntax-check playbook.yml` |
| Preview supported changes | `ansible-playbook --check --diff playbook.yml` |
| List targeted hosts | `ansible-playbook playbook.yml --list-hosts` |
| List tasks | `ansible-playbook playbook.yml --list-tasks` |
| Show detailed troubleshooting | Add `-vvv` |

[Back to Index](#index)

## 27. Recommended learning order

```text
Control node and managed nodes
            ↓
Inventory and ansible.cfg
            ↓
Ad-hoc command syntax
            ↓
Modules, arguments and state
            ↓
YAML
            ↓
Tasks, plays and playbooks
            ↓
Variables and facts
            ↓
Loops and conditions
            ↓
Register and debug
            ↓
Handlers and templates
            ↓
Roles, collections and Vault
```

First concentrate on inventory, configuration, ad-hoc commands, modules, arguments, state, tasks, plays, playbooks, variables and facts. Move to loops, conditions, registered results, handlers, templates and roles after the foundation is comfortable.

[Back to Index](#index)
