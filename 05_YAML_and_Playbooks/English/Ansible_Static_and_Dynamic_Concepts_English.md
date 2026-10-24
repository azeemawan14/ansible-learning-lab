# Ansible Static and Dynamic Concepts

## Detailed English Study Notes — Personal Rocky Linux Lab

## Table of Contents

1. [Core definition](#1-core-definition)
2. [Static inventory](#2-static-inventory)
3. [Static inventory in your lab](#3-static-inventory-in-your-lab)
4. [Dynamic inventory](#4-dynamic-inventory)
5. [Static versus dynamic inventory](#5-static-versus-dynamic-inventory)
6. [Inventory verification commands](#6-inventory-verification-commands)
7. [Static imports and dynamic includes](#7-static-imports-and-dynamic-includes)
8. [Static `import_tasks` lab](#8-static-import_tasks-lab)
9. [Dynamic `include_tasks` lab](#9-dynamic-include_tasks-lab)
10. [Imports versus includes](#10-imports-versus-includes)
11. [Choosing the correct method](#11-choosing-the-correct-method)
12. [Common misunderstandings](#12-common-misunderstandings)
13. [Troubleshooting](#13-troubleshooting)
14. [Practice questions](#14-practice-questions)
15. [Quick command reference](#15-quick-command-reference)

---

## 1. Core definition

> A **static** resource is fixed and known to Ansible before execution begins.
> A **dynamic** resource is discovered, selected, or processed at run time.

Ansible uses these terms in two major contexts:

1. **Static inventory versus dynamic inventory** — how Ansible obtains its list
   of managed hosts.
2. **Static imports versus dynamic includes** — when Ansible loads reusable
   playbook, task, or role content.

These are related ideas, but they solve different problems. Dynamic inventory
discovers hosts. A dynamic include selects playbook content at run time.

---

## 2. Static inventory

A static inventory contains hosts, groups, connection addresses, and optional
variables written manually by an administrator.

```ini
[web]
node1 ansible_host=192.168.1.154

[app]
node2 ansible_host=192.168.1.185

[db]
node3 ansible_host=192.168.1.190
```

It is called static because:

- hosts are entered manually;
- a newly created server is not added automatically;
- an address or hostname change requires a manual inventory update;
- the inventory remains unchanged until someone edits it.

Static inventory can use INI or YAML format.

### Static INI inventory

```ini
[web]
node1 ansible_host=192.168.1.154
```

### Static YAML inventory

```yaml
---
all:
  children:
    web:
      hosts:
        node1:
          ansible_host: 192.168.1.154
```

Both examples are static. The filename or extension does not determine whether
an inventory is static or dynamic. A manually maintained `nodes.yaml` file is
still a static inventory.

### Advantages

- Easy to create and understand
- Easy to troubleshoot
- No API or cloud credentials required
- Excellent for small, stable labs
- Works even when an external cloud service is unavailable

### Limitations

- Requires manual maintenance
- Can become outdated
- Is inconvenient for large or frequently changing environments
- Can contain duplicated information across teams

---

## 3. Static inventory in your lab

Your current environment is:

| Group | Inventory host | IP address | Purpose |
|---|---|---:|---|
| `web` | `node1` | `192.168.1.154` | Web-server practice |
| `app` | `node2` | `192.168.1.185` | Application-server practice |
| `db` | `node3` | `192.168.1.190` | Database-server practice |

Your practical inventory can be written as:

```ini
# /home/ansibleadmin/automation/inventory/nodes

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

This is a static inventory because you manually define the three managed nodes.
It is the best starting choice for your current LAN lab because the environment
is small, stable, and easy to verify.

The parent group does not make the inventory dynamic. It simply combines the
`web`, `app`, and `db` child groups under `three_tier_app`.

---

## 4. Dynamic inventory

Dynamic inventory obtains hosts automatically from an external source instead
of depending on a manually maintained host list.

Possible sources include:

- AWS EC2
- Microsoft Azure
- Google Cloud Platform
- VMware vCenter
- OpenStack
- Kubernetes
- A Configuration Management Database (CMDB)
- A custom internal API

Modern Ansible normally uses an inventory plugin. Older environments may use
executable inventory scripts.

### Simplified AWS EC2 plugin example

```yaml
---
plugin: amazon.aws.aws_ec2
regions:
  - us-east-1
filters:
  instance-state-name: running
```

When Ansible processes this source, the plugin queries the AWS API and returns
matching running instances. If a matching instance is created or removed, the
next inventory query reflects the current AWS state without requiring a manual
IP-address edit.

Dynamic does not mean random. Results are controlled by:

- the selected inventory plugin;
- authentication and authorization;
- regions, projects, subscriptions, or datacenters;
- tags and metadata;
- inventory filters;
- the current state of the external platform.

### Typical requirements

- The appropriate collection or plugin
- API connectivity
- Authorized credentials
- Platform-specific configuration
- Filters that select only the required systems

Do not hard-code secrets in an inventory file. Use the platform's credential
mechanism, protected environment variables, Ansible Vault, or Automation
Controller credentials.

### Why dynamic inventory matters

In a cloud environment, instances may be created and deleted many times each
day. A manually maintained inventory quickly becomes inaccurate. Dynamic
inventory lets the infrastructure platform act as the source of truth.

---

## 5. Static versus dynamic inventory

| Static inventory | Dynamic inventory |
|---|---|
| Hosts are defined manually | Hosts are discovered from an external source |
| Commonly stored as INI or YAML | Commonly uses an inventory plugin or script |
| Requires manual updates | Reflects current external-platform data |
| Simple initial setup | Requires API/plugin configuration |
| No external API credentials needed | Usually requires authorized credentials |
| Best for small, stable environments | Best for cloud or changing environments |
| Suitable for your three-node LAN lab | Useful for AWS or VMware production estates |

Both forms can contain or generate:

- hosts;
- groups;
- child groups;
- host variables;
- group variables.

The presence of groups or variables does not determine whether an inventory is
static or dynamic. The important question is: **Was the host information entered
manually, or was it discovered from another system?**

---

## 6. Inventory verification commands

Start from your project directory:

```bash
cd /home/ansibleadmin/automation
```

Display the inventory hierarchy:

```bash
ansible-inventory --graph
```

Display the complete parsed inventory:

```bash
ansible-inventory --list
```

Display variables resolved for `node1`:

```bash
ansible-inventory --host node1
```

List the hosts matched by your parent group:

```bash
ansible three_tier_app --list-hosts
```

Test Ansible connectivity:

```bash
ansible three_tier_app -m ping
```

Specify an inventory source explicitly:

```bash
ansible-inventory -i ./inventory/nodes --graph
ansible three_tier_app -i ./inventory/nodes -m ping
```

If `inventory = ./inventory` is configured in the project `ansible.cfg`, you do
not need to type `-i` on every command while working from that project directory.

---

## 7. Static imports and dynamic includes

The terms static and dynamic also describe reusable playbook content.

### Static reuse keywords

- `import_playbook`
- `import_tasks`
- `import_role`

Ansible processes imported content while it parses the playbook. The imported
structure is therefore known before normal task execution begins.

### Dynamic reuse keywords

- `include_tasks`
- `include_role`

Ansible processes included content during execution. This makes run-time
conditions, loops, and variable-based file selection more flexible.

Important distinctions:

- `import_playbook` is used only at the top level of a playbook.
- `import_tasks` and `include_tasks` are used in a task list.
- `import_role` and `include_role` work with roles.
- Dynamic inventory and dynamic includes are separate features.

---

## 8. Static `import_tasks` lab

Create this structure:

```text
playbooks/
├── static-demo.yml
└── tasks/
    └── install-tools.yml
```

Create the imported task file:

```yaml
# playbooks/tasks/install-tools.yml
---
- name: Install Git
  dnf:
    name: git
    state: present

- name: Install Curl
  dnf:
    name: curl
    state: present
```

Create the main playbook:

```yaml
# playbooks/static-demo.yml
---
- name: Demonstrate static task import
  hosts: three_tier_app
  become: true
  gather_facts: false

  tasks:
    - name: Import tool-installation tasks
      import_tasks: tasks/install-tools.yml
```

Validate, inspect, and test:

```bash
ansible-playbook --syntax-check playbooks/static-demo.yml
ansible-playbook playbooks/static-demo.yml --list-tasks
ansible-playbook playbooks/static-demo.yml --limit node1
```

Because `import_tasks` is static, Ansible knows the contents of
`install-tools.yml` while processing the playbook. The imported tasks become
part of the parsed task structure.

---

## 9. Dynamic `include_tasks` lab

Create this structure:

```text
playbooks/
├── dynamic-demo.yml
└── tasks/
    ├── web-tasks.yml
    └── db-tasks.yml
```

Create the web task file:

```yaml
# playbooks/tasks/web-tasks.yml
---
- name: Install Nginx
  dnf:
    name: nginx
    state: present
```

Create the database task file:

```yaml
# playbooks/tasks/db-tasks.yml
---
- name: Install MariaDB server
  dnf:
    name: mariadb-server
    state: present
```

Create the main playbook:

```yaml
# playbooks/dynamic-demo.yml
---
- name: Demonstrate dynamic task inclusion
  hosts: three_tier_app
  become: true
  gather_facts: false

  tasks:
    - name: Include web tasks at run time
      include_tasks: tasks/web-tasks.yml
      when: "'web' in group_names"

    - name: Include database tasks at run time
      include_tasks: tasks/db-tasks.yml
      when: "'db' in group_names"
```

Validate and run:

```bash
ansible-playbook --syntax-check playbooks/dynamic-demo.yml
ansible-playbook playbooks/dynamic-demo.yml --list-tasks
ansible-playbook playbooks/dynamic-demo.yml
```

Expected behavior:

- `node1` includes and runs `web-tasks.yml` because it belongs to `web`.
- `node3` includes and runs `db-tasks.yml` because it belongs to `db`.
- `node2` may skip both includes because it belongs to `app`.
- `skipped` is not an error; it means the `when` expression was false.

---

## 10. Imports versus includes

| Static import | Dynamic include |
|---|---|
| `import_tasks` / `import_role` | `include_tasks` / `include_role` |
| Processed when the playbook is parsed | Processed during execution |
| Structure is known earlier | Selection can depend on run-time values |
| Suitable for fixed, predictable reuse | Suitable for conditions and loops |
| Imported tasks can appear in advance in task listings | Included tasks expand when inclusion occurs |

Observe the difference:

```bash
ansible-playbook playbooks/static-demo.yml --list-tasks
ansible-playbook playbooks/dynamic-demo.yml --list-tasks
```

The statically imported tasks can be visible before execution because Ansible
has already expanded them. Tasks inside a dynamic include may not be fully
expanded until the include is reached during execution.

### Conditions and loops

Dynamic includes are especially useful when you need to:

- apply a condition to the inclusion itself;
- include a task file repeatedly with a loop;
- choose a filename using a run-time variable;
- select different task files for different systems.

Static imports are usually preferable when the task structure is fixed and
predictability is more important than run-time flexibility.

---

## 11. Choosing the correct method

### Use static inventory when:

- you have a small number of hosts;
- addresses and hostnames are stable;
- you are building a personal or classroom lab;
- simple inspection and troubleshooting are priorities.

### Use dynamic inventory when:

- instances are frequently created and removed;
- AWS, Azure, VMware, or another platform is the source of truth;
- hosts must be grouped using tags or metadata;
- manual inventory would quickly become outdated.

### Use `import_tasks` when:

- the reused task structure is fixed;
- the task file should always be loaded;
- early task discovery and predictable parsing are useful.

### Use `include_tasks` when:

- inclusion must be decided at run time;
- a `when` condition controls whether a file is included;
- the include must run in a loop;
- a variable determines which file is selected.

### Recommendation for your current lab

Continue using static inventory for `node1`, `node2`, and `node3`. It is simpler
and more appropriate than introducing a cloud inventory plugin. Practice
`import_tasks` and `include_tasks` separately so you learn reuse without changing
how your hosts are discovered.

---

## 12. Common misunderstandings

### Is `nodes.yaml` different from an inventory file?

`nodes.yaml` may simply be the filename of an inventory. If its hosts are
written manually, it is a YAML-formatted static inventory.

### Does a `.yaml` extension mean dynamic inventory?

No. YAML is only the data format. A YAML file can be a static inventory, a
dynamic plugin configuration, a playbook, or a variables file.

### Is the `inventory/` directory itself dynamic?

No. The directory organizes inventory sources. It can contain static files,
dynamic plugin configurations, or both.

### Do variables make a playbook dynamic inventory?

No. Variables make automation flexible. Dynamic inventory specifically refers
to discovering hosts from an external source.

### Is static always bad because it is hard-coded?

No. Static inventory is often the clearest and most reliable design for a small,
stable lab. Dynamic inventory becomes valuable when infrastructure changes
frequently or is controlled by another platform.

### Are `include_tasks` and dynamic inventory the same feature?

No. `include_tasks` controls reusable task content. Dynamic inventory discovers
managed hosts. They operate at different layers of Ansible.

---

## 13. Troubleshooting

### Inventory is empty

```bash
ansible-inventory -i ./inventory/nodes --graph
```

Check the path, file permissions, inventory syntax, and current working directory.

### A group does not contain the expected host

```bash
ansible-inventory --graph
ansible web --list-hosts
ansible app --list-hosts
ansible db --list-hosts
```

### Included task file cannot be found

Paths for `import_tasks` and `include_tasks` are normally interpreted relative
to the playbook file. Confirm the task file and spelling:

```bash
find playbooks -maxdepth 2 -type f -print | sort
```

### Dynamic inventory authentication fails

Confirm that the required collection is installed, credentials are available,
API access is permitted, and the configured region or project is correct.

### A dynamically included task is skipped

Inspect the condition and group membership:

```bash
ansible node1 -m debug -a "var=group_names"
```

A skipped include is expected when its `when` expression evaluates to false.

---

## 14. Practice questions

1. What is the one-line meaning of static in Ansible?
2. What is the one-line meaning of dynamic in Ansible?
3. Which inventory type are you using in your three-node LAN lab?
4. Why must a static inventory be maintained manually?
5. Where does a dynamic inventory obtain its hosts?
6. Name four possible dynamic inventory sources.
7. Does a `.yaml` extension automatically make an inventory dynamic?
8. What does `ansible-inventory --graph` display?
9. What does `ansible-inventory --host node1` display?
10. What does the `-i` option specify?
11. Which three keywords provide static reuse?
12. Which two keywords provide dynamic reuse?
13. Why is `import_tasks` considered static?
14. Why is `include_tasks` considered dynamic?
15. Why is `when` useful with `include_tasks`?
16. What does a `skipped` result mean?
17. Where can `import_playbook` be used?
18. What can you observe with `--list-tasks`?
19. Why is static inventory appropriate for your current lab?
20. Why can dynamic inventory be valuable in AWS or VMware?

---

## 15. Quick command reference

```bash
cd /home/ansibleadmin/automation

# Configuration and inventory
ansible --version
ansible-config dump --only-changed
ansible-inventory --graph
ansible-inventory --list
ansible-inventory --host node1
ansible three_tier_app --list-hosts
ansible three_tier_app -m ping

# Explicit inventory source
ansible-inventory -i ./inventory/nodes --graph
ansible three_tier_app -i ./inventory/nodes -m ping

# Syntax checks
ansible-playbook --syntax-check playbooks/static-demo.yml
ansible-playbook --syntax-check playbooks/dynamic-demo.yml

# Inspect task expansion
ansible-playbook playbooks/static-demo.yml --list-tasks
ansible-playbook playbooks/dynamic-demo.yml --list-tasks

# Safe one-host test
ansible-playbook playbooks/static-demo.yml --limit node1

# Run the dynamic include demonstration
ansible-playbook playbooks/dynamic-demo.yml
```

## Summary

- Static inventory contains manually defined hosts.
- Dynamic inventory discovers current hosts from an external source.
- Your stable three-node LAN lab is well suited to static inventory.
- `import_playbook`, `import_tasks`, and `import_role` provide static reuse.
- `include_tasks` and `include_role` provide dynamic reuse.
- Inventory discovery and task inclusion are separate Ansible concepts.
- Use static designs for clarity when the environment is fixed.
- Use dynamic designs when information must be selected or discovered at run time.
