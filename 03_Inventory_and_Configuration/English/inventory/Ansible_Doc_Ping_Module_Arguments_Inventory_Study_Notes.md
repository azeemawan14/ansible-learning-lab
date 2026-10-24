# Ansible Study Notes — `ansible-doc`, `ping` Module Arguments, and Temporary Inventory

## 1. Purpose of These Notes

These notes cover the exact Ansible concepts practiced in the lab:

- How to get help/documentation for Ansible modules with `ansible-doc`
- How to use the `ping` module
- How to pass module arguments in an ad-hoc command with `-a`
- How `data=hello` and `data=crash` behave
- How to use a temporary/static inventory file with `-i`
- How the current lab inventory is organized
- Useful commands to inspect inventory and host variables

---

# 2. `ansible-doc` — Ansible Module Help

In Linux, we often use:

```bash
man ls
```

for command documentation.

For Ansible modules, the equivalent tool is:

```bash
ansible-doc
```

## Basic Syntax

```bash
ansible-doc MODULE_NAME
```

Example:

```bash
ansible-doc ping
```

or using the Fully Qualified Collection Name (FQCN):

```bash
ansible-doc ping
```

---

## Useful `ansible-doc` Commands

### View full documentation for a module

```bash
ansible-doc ping
```

### View short module syntax/options

```bash
ansible-doc -s ping
```

The `-s` option is very useful when you mainly want to see:

- Parameters
- Options
- Expected values

### List available modules/plugins

```bash
ansible-doc -l
```

### Search the module list

```bash
ansible-doc -l | grep ping
```

Example for package-related modules:

```bash
ansible-doc -l | grep dnf
```

---

# 3. Understanding the `ping` Module

The Ansible `ping` module is **not the same as the Linux/network ICMP `ping` command**.

Normal network ping:

```bash
ping 192.168.1.154
```

primarily checks network reachability using ICMP.

Ansible ping:

```bash
ansible web -m ping
```

checks whether Ansible can successfully communicate with the managed host and execute the module there.

A successful result looks like:

```text
node1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

So a useful mental model is:

```text
Control Node
    |
    | Ansible connection
    v
Managed Node
    |
    | Execute Ansible module
    v
Python / Module Execution
    |
    v
SUCCESS -> "pong"
```

---

# 4. Basic Ad-Hoc `ping` Command

The command practiced was:

```bash
ansible web -m ping -i ./automation/inventory/
```

Result:

```text
node1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

## Command Breakdown

```text
ansible web -m ping -i ./automation/inventory/
   |      |    |              |
   |      |    |              +-- inventory path
   |      |    +----------------- module name
   |      +---------------------- target inventory group
   +----------------------------- Ansible ad-hoc command
```

### `web`

This is the inventory group being targeted.

### `-m ping`

`-m` specifies the Ansible module.

### `-i`

`-i` tells Ansible which inventory file or inventory directory to use.

---

# 5. Passing Module Arguments with `-a`

General syntax:

```bash
ansible TARGET -m MODULE -a "argument=value"
```

For example:

```bash
ansible web -m ping -a "data=hello" -i ./automation/inventory/
```

Here:

```text
-m ping
```

means:

> Use the `ping` module.

And:

```text
-a "data=hello"
```

means:

> Pass `data=hello` as an argument to the module.

---

# 6. `data=hello`

Command used:

```bash
ansible web -m ping -a "data=hello" -i ./automation/inventory/
```

Result:

```text
node1 | SUCCESS => {
    "changed": false,
    "ping": "hello"
}
```

Normally, the ping module returns:

```text
"ping": "pong"
```

But when we pass:

```text
data=hello
```

it returns:

```text
"ping": "hello"
```

This proves that the module argument was passed successfully.

---

# 7. `data=crash`

Command used:

```bash
ansible web -m ping -a "data=crash" -i ./automation/inventory/
```

The command intentionally failed and returned:

```text
An exception occurred during task execution.
The error was: Exception: boom
```

and:

```text
node1 | FAILED!
```

This is expected behavior.

The value:

```text
crash
```

is a special value for the Ansible `ping` module that deliberately causes an exception.

It is useful for learning how Ansible reports module failures.

## Simple Flow

```text
data=hello
     |
     v
Module executes successfully
     |
     v
"ping": "hello"
```

Compared with:

```text
data=crash
     |
     v
Module deliberately raises an exception
     |
     v
FAILED
Exception: boom
```

So this failure does **not** mean the SSH connection or managed node was broken.

The failure was intentionally requested.

---

# 8. Viewing More Details About a Failure

The output itself suggested:

```text
To see the full traceback, use -vvv
```

So a verbose version can be run as:

```bash
ansible web -m ping -a "data=crash" -i ./automation/inventory/ -vvv
```

`-vvv` gives much more troubleshooting detail, including connection and module execution information.

Use verbose output when debugging; do not use it unnecessarily for every normal command.

---

# 9. My Temporary / Static Inventory File

Current inventory file:

```text
/home/ansibleadmin/automation/inventory/nodes
```

Confirmed with:

```bash
realpath ./automation/inventory/nodes
```

Output:

```text
/home/ansibleadmin/automation/inventory/nodes
```

The current inventory is:

```ini
# ============================================
# Ansible Static Inventory — Personal Lab
# ============================================

# Control node
# ansible_connection=local prevents SSH from being used for localhost
[control]
ansible-server ansible_connection=local


# Web-server group
[web]
node1 ansible_host=192.168.1.154


# Application-server group
[app]
node2 ansible_host=192.168.1.185


# Database-server group
[db]
node3 ansible_host=192.168.1.190


# Parent group containing all managed-node groups
[three_tier_app:children]
web
app
db

# if we have large number of hosts or series of IP addresses or complete subnet.
[database]
192.168.10.[1:20]

# if we have large number of hosts having hostname in a sequence.
[sandbox]
server[1:9].nitclasses.com


# Variables inherited by every inventory host
[all:vars]

# SSH user used to connect to managed nodes
ansible_user=ansibleadmin

# Python interpreter used to execute Ansible modules
ansible_python_interpreter=/usr/bin/python3

# Optional private SSH key
# Uncomment this only when the key must be specified explicitly
# ansible_ssh_private_key_file=/home/ansibleadmin/.ssh/id_ed25519
```

---

# 10. Understanding the Inventory Structure

## Control Group

```ini
[control]
ansible-server ansible_connection=local
```

This means `ansible-server` belongs to the `control` group.

```text
ansible_connection=local
```

tells Ansible to execute locally instead of trying SSH for that host.

---

## Web Group

```ini
[web]
node1 ansible_host=192.168.1.154
```

Here:

```text
node1
```

is the inventory name/alias.

```text
ansible_host=192.168.1.154
```

is the real IP address Ansible uses to connect.

So:

```text
node1
   |
   +--> ansible_host
           |
           v
      192.168.1.154
```

---

## Application Group

```ini
[app]
node2 ansible_host=192.168.1.185
```

`node2` is in the `app` group.

---

## Database Group

```ini
[db]
node3 ansible_host=192.168.1.190
```

`node3` is in the `db` group.

---

# 11. Parent Group with `:children`

```ini
[three_tier_app:children]
web
app
db
```

This creates a parent group called:

```text
three_tier_app
```

Its child groups are:

```text
web
app
db
```

Conceptually:

```text
three_tier_app
├── web
│   └── node1
├── app
│   └── node2
└── db
    └── node3
```

This lets us target the complete three-tier environment:

```bash
ansible three_tier_app -m ping -i ~/automation/inventory/nodes
```

---

# 12. Host Range Examples in the Inventory

The inventory contains this practice example:

```ini
[database]
192.168.10.[1:20]
```

This represents a sequence such as:

```text
192.168.10.1
192.168.10.2
192.168.10.3
...
192.168.10.20
```

It also contains:

```ini
[sandbox]
server[1:9].nitclasses.com
```

which represents:

```text
server1.nitclasses.com
server2.nitclasses.com
...
server9.nitclasses.com
```

## Important Lab Note

These range examples should represent real reachable hosts before targeting them.

If they are only examples and we run:

```bash
ansible all -m ping
```

Ansible may try to connect to them as well and report failures.

For a clean lab, comment out unused example groups until they are needed.

---

# 13. Global Inventory Variables

The inventory has:

```ini
[all:vars]
ansible_user=ansibleadmin
ansible_python_interpreter=/usr/bin/python3
```

`[all:vars]` means these variables can be inherited by inventory hosts.

## `ansible_user`

```ini
ansible_user=ansibleadmin
```

This is the remote user Ansible uses for SSH connections.

Equivalent idea:

```bash
ssh ansibleadmin@192.168.1.154
```

---

## `ansible_python_interpreter`

```ini
ansible_python_interpreter=/usr/bin/python3
```

This tells Ansible which Python interpreter to use on the managed node when executing Python-based modules.

---

# 14. Useful Inventory Inspection Commands

## Show inventory hierarchy

```bash
ansible-inventory -i ~/automation/inventory/nodes --graph
```

This is useful for understanding:

- Groups
- Child groups
- Hosts

---

## Show variables resolved for one host

```bash
ansible-inventory -i ~/automation/inventory/nodes --host node1
```

This is especially useful for seeing variables such as:

```text
ansible_host
ansible_user
ansible_python_interpreter
```

For `node1`, some variables are defined directly on the host and others are inherited from `[all:vars]`.

---

## Show complete resolved inventory

```bash
ansible-inventory -i ~/automation/inventory/nodes --list
```

---

## List hosts in a group

```bash
ansible web -i ~/automation/inventory/nodes --list-hosts
```

Expected idea:

```text
hosts (1):
  node1
```

---

# 15. Inventory Directory vs Inventory File

This command worked:

```bash
ansible web -m ping -i ./automation/inventory/
```

Here Ansible was given the **inventory directory**.

The more explicit form is:

```bash
ansible web -m ping -i ./automation/inventory/nodes
```

Both can work when the inventory directory contains valid inventory sources.

For learning and troubleshooting, specifying the exact inventory file is often clearer:

```bash
ansible web -m ping -i ~/automation/inventory/nodes
```

That removes ambiguity about which inventory source is being loaded.

---

# 16. Short Form vs FQCN

This worked:

```bash
ansible web -m ping
```

The fully qualified module name is:

```bash
ansible web -m ping
```

For ad-hoc practice, short names are convenient.

For playbooks and documentation, using the FQCN is often clearer:

```yaml
- name: Test managed host
  ping:
```

---

# 17. Ad-Hoc Command Pattern to Remember

A very useful pattern is:

```bash
ansible <target> -m <module> -a "<module arguments>" -i <inventory>
```

For this lab:

```bash
ansible web -m ping -a "data=hello" -i ~/automation/inventory/nodes
```

Breakdown:

```text
ansible
   |
   +-- web                  -> target group
   |
   +-- -m ping              -> module
   |
   +-- -a "data=hello"      -> module argument
   |
   +-- -i .../nodes         -> inventory source
```

---

# 18. Commands Practiced in This Lab

### Default Ansible ping

```bash
ansible web -m ping -i ./automation/inventory/
```

### Pass custom data

```bash
ansible web -m ping -a "data=hello" -i ./automation/inventory/
```

### Intentionally trigger an exception

```bash
ansible web -m ping -a "data=crash" -i ./automation/inventory/
```

### Find exact inventory path

```bash
realpath ./automation/inventory/nodes
```

Result:

```text
/home/ansibleadmin/automation/inventory/nodes
```

---

# 19. One Small Environment Lesson

The command:

```bash
explorer.exe .
```

returned:

```text
-bash: explorer.exe: command not found
```

That command works in environments such as WSL where Windows executables are accessible.

The Ansible server is a regular Linux environment, so Windows Explorer is not available there.

Use Linux commands instead:

```bash
pwd
ls
ls -la
```

or:

```bash
cd ~/automation/inventory
ls -l
```

---

# 20. Quick Revision

## Documentation

```bash
ansible-doc ping
```

Full help.

```bash
ansible-doc -s ping
```

Short syntax/options.

---

## Module

```bash
-m ping
```

Selects the module.

---

## Arguments

```bash
-a "data=hello"
```

Passes arguments to the module.

---

## Inventory

```bash
-i ~/automation/inventory/nodes
```

Tells Ansible which inventory source to use.

---

## Default `ping`

```bash
ansible web -m ping -i ~/automation/inventory/nodes
```

Expected:

```text
"ping": "pong"
```

---

## Custom Data

```bash
ansible web -m ping -a "data=hello" -i ~/automation/inventory/nodes
```

Expected:

```text
"ping": "hello"
```

---

## Intentional Failure

```bash
ansible web -m ping -a "data=crash" -i ~/automation/inventory/nodes
```

Expected:

```text
FAILED
Exception: boom
```

---

# 21. Best Learning Sequence From Here

A clean learning order is:

```text
1. ansible-doc
        ↓
2. Understand a module
        ↓
3. Run it as an ad-hoc command
        ↓
4. Pass module arguments
        ↓
5. Target inventory groups
        ↓
6. Inspect inventory variables
        ↓
7. Put the same module into a playbook
```

This is better than jumping directly into large playbooks because it makes each layer clear before adding the next one.

---

# 22. Key Interview / Study Points

- `ansible-doc` provides Ansible plugin/module documentation.
- `-m` selects a module.
- `-a` passes arguments to the selected module.
- `-i` selects the inventory source.
- Ansible `ping` is not the same as ICMP/network ping.
- Successful Ansible ping normally returns `pong`.
- `data=hello` demonstrates passing a module argument.
- `data=crash` intentionally raises an exception.
- Inventory aliases such as `node1` can map to real addresses using `ansible_host`.
- Variables under `[all:vars]` can be inherited by inventory hosts.
- `ansible-inventory --graph` shows inventory structure.
- `ansible-inventory --host node1` is excellent for checking the variables Ansible resolved for one host.

---

## My Lab Summary

Current working test:

```text
ansible-server
      |
      | Ansible
      v
[web]
node1
      |
      +--> 192.168.1.154
      |
      +--> ansible_user=ansibleadmin
      |
      +--> ansible_python_interpreter=/usr/bin/python3
```

Successful test:

```bash
ansible web -m ping -i ~/automation/inventory/nodes
```

Successful argument test:

```bash
ansible web -m ping -a "data=hello" -i ~/automation/inventory/nodes
```

Intentional failure test:

```bash
ansible web -m ping -a "data=crash" -i ~/automation/inventory/nodes
```

This gives a strong foundation before moving on to additional modules and playbooks.
