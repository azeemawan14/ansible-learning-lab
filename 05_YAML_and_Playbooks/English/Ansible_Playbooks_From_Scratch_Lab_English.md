# Ansible Playbooks from Scratch - Study Notes and Hands-On Lab

<img src="Ansible-Playbook -tructure-at-a-Glance.png" width="700">


This guide introduces YAML data types, explains the structure of an Ansible playbook, and provides a safe hands-on lab for a Rocky Linux environment.

The examples use short module names such as `file`, `copy`, and `debug`, as preferred for this lab.

## Index

1. [Learning objectives](#1-learning-objectives)
2. [Lab environment](#2-lab-environment)
3. [What is an Ansible playbook?](#3-what-is-an-ansible-playbook)
4. [Ad-hoc commands versus playbooks](#4-ad-hoc-commands-versus-playbooks)
5. [YAML fundamentals](#5-yaml-fundamentals)
6. [Data types used in playbooks](#6-data-types-used-in-playbooks)
7. [Playbook structure](#7-playbook-structure)
8. [How to read a playbook](#8-how-to-read-a-playbook)
9. [Prepare the project](#9-prepare-the-project)
10. [Lab 1 - First playbook](#10-lab-1---first-playbook)
11. [Lab 2 - Variables, lists, mappings, loops, facts, and conditions](#11-lab-2---variables-lists-mappings-loops-facts-and-conditions)
12. [Validate and run a playbook](#12-validate-and-run-a-playbook)
13. [Understand the play recap](#13-understand-the-play-recap)
14. [Test idempotency](#14-test-idempotency)
15. [Useful playbook execution options](#15-useful-playbook-execution-options)
16. [Lab 3 - Handlers and notifications](#16-lab-3---handlers-and-notifications)
17. [Verification commands](#17-verification-commands)
18. [Cleanup playbook](#18-cleanup-playbook)
19. [Common mistakes and troubleshooting](#19-common-mistakes-and-troubleshooting)
20. [Practice assignment](#20-practice-assignment)
21. [Quick-reference tables](#21-quick-reference-tables)
22. [Suggested learning path](#22-suggested-learning-path)

---

## 1. Learning objectives

After completing this lab, you should be able to:

- Explain what a playbook, play, task, module, argument, variable, fact, condition, loop, and handler are.
- Recognize common YAML data types.
- Write a correctly indented YAML playbook.
- Target an inventory group from a playbook.
- Validate a playbook before running it.
- Use check mode and diff mode.
- Run and verify a playbook.
- Test whether a playbook is idempotent.
- Remove everything created by the lab.

---

## 2. Lab environment

These notes are adapted to the following environment:

| Component | Value |
|---|---|
| Control node | `ansible-server.nitclasses.com` |
| Control-node user | `ansibleadmin` |
| Project directory | `/home/ansibleadmin/automation` |
| Inventory source | `/home/ansibleadmin/automation/inventory` |
| Managed-node group | `three_tier_app` |
| Managed nodes | `node1`, `node2`, and `node3` |
| Operating system | Rocky Linux 9 |
| Remote user | `ansibleadmin` |
| Python interpreter | `/usr/bin/python3` |

Example inventory:

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

Example project-level `ansible.cfg`:

```ini
[defaults]
inventory = ./inventory
host_key_checking = False
remote_user = ansibleadmin
ask_pass = False
private_key_file = /home/ansibleadmin/.ssh/ansible-key

[privilege_escalation]
become_method = sudo
become_user = root
become_ask_pass = False
```

> Run the commands from `/home/ansibleadmin/automation` so that Ansible discovers the project-level `ansible.cfg`.

---

## 3. What is an Ansible playbook?

An Ansible playbook is a YAML file that describes repeatable automation. It tells Ansible:

- which hosts to manage;
- which tasks to perform;
- which modules to use;
- which values and variables to pass to those modules;
- whether privilege escalation is required;
- and what the desired final state should be.

A playbook normally uses the `.yml` or `.yaml` filename extension.

Example:

```text
site.yml
```

---

## 4. Ad-hoc commands versus playbooks

| Ad-hoc command | Playbook |
|---|---|
| Runs a quick, one-time task | Stores reusable automation in a file |
| Usually contains one module invocation | Can contain many tasks and plays |
| Convenient for testing and troubleshooting | Better for repeatable work |
| Difficult to document as a complete workflow | Can include names, variables, loops, conditions, tags, and handlers |
| Example: `ansible all -m ping` | Example: `ansible-playbook site.yml` |

Use an ad-hoc command for a quick operation. Use a playbook when the work must be repeated, reviewed, shared, or kept under version control.

---

## 5. YAML fundamentals

YAML is a human-readable data-serialization language. Ansible uses YAML to describe plays, tasks, variables, and module arguments.

### Important YAML rules

1. Use spaces for indentation; never use tabs.
2. Keep items at the same level aligned.
3. Put one space after a colon in `key: value`.
4. A hyphen followed by a space begins a list item.
5. YAML is case-sensitive.
6. Comments begin with `#`.
7. Quote values when they contain special characters or could be interpreted incorrectly.
8. Prefer `true` and `false` for Boolean values.
9. `---` can mark the beginning of a YAML document; it is recommended but not required by Ansible.
10. `...` can mark the end of a YAML document, but it is usually omitted.

Correct indentation:

```yaml
tasks:
  - name: Create a directory
    file:
      path: /tmp/example
      state: directory
```

Incorrect indentation:

```yaml
tasks:
- name: Create a directory
  file:
  path: /tmp/example
    state: directory
```

---

## 6. Data types used in playbooks

### 6.1 String

A string is text.

```yaml
course_name: Ansible Fundamentals
lab_directory: /tmp/ansible-playbook-lab
```

Quoted strings are useful when a value contains special characters:

```yaml
message: "Welcome: this file was managed by Ansible"
```

### 6.2 Integer

An integer is a whole number.

```yaml
student_count: 25
file_mode_decimal: 644
```

File modes should normally be quoted so YAML does not reinterpret them:

```yaml
mode: "0644"
```

### 6.3 Floating-point number

```yaml
course_version: 1.5
```

### 6.4 Boolean

A Boolean represents true or false.

```yaml
become: true
gather_facts: false
```

Prefer `true` and `false` instead of `yes`, `no`, `on`, or `off` because the latter words can be interpreted differently by YAML parsers.

### 6.5 Null value

A null value means that no value is assigned.

```yaml
optional_value: null
```

### 6.6 List

A list is an ordered collection of values. Each item begins with `-`.

```yaml
lab_files:
  - introduction.txt
  - inventory.txt
  - facts.txt
```

Inline form:

```yaml
lab_files: [introduction.txt, inventory.txt, facts.txt]
```

The block form is usually easier to read.

### 6.7 Mapping or dictionary

A mapping stores key-value pairs.

```yaml
file_settings:
  owner: ansibleadmin
  group: ansibleadmin
  mode: "0644"
```

### 6.8 List of mappings

This is common in loops when every item needs several properties.

```yaml
managed_files:
  - name: introduction.txt
    content: "Ansible playbook lab"
  - name: inventory.txt
    content: "Inventory host information"
```

### 6.9 Variables and Jinja expressions

Use double curly braces to read a variable:

```yaml
path: "{{ lab_directory }}"
```

Quote a value when the Jinja expression begins the value:

```yaml
content: "{{ lab_message }}"
```

---

## 7. Playbook structure

The relationship is:

```text
Playbook
  -> one or more plays
      -> a host pattern and play-level settings
      -> one or more tasks
          -> one module per task
              -> module arguments
```

### Main terms

| Term | Meaning |
|---|---|
| Playbook | A YAML file containing one or more plays |
| Play | A set of tasks applied to a host or group pattern |
| `name` | A readable description of a play, task, or handler |
| `hosts` | Inventory host or group pattern targeted by a play |
| `gather_facts` | Controls automatic collection of managed-node facts |
| `become` | Enables privilege escalation, normally through `sudo` |
| `vars` | Defines variables for the play |
| `tasks` | An ordered list of actions |
| Task | One named unit of work |
| Module | An Ansible unit of work, such as `file`, `copy`, or `service` |
| Module arguments | Settings passed to a module, such as `path` and `state` |
| `loop` | Repeats a task for several items |
| `when` | Runs a task only when a condition is true |
| `register` | Saves a task result in a variable |
| `notify` | Requests a handler after a task reports a change |
| `handlers` | Special tasks that run only when notified |
| `tags` | Labels used to select or skip parts of a playbook |

### Skeleton playbook

```yaml
---
- name: Descriptive name of the play
  hosts: three_tier_app
  become: false
  gather_facts: true

  vars:
    example_variable: example value

  tasks:
    - name: Descriptive name of the task
      debug:
        msg: "{{ example_variable }}"

  handlers:
    - name: Example handler
      debug:
        msg: Handler executed
```

Important: `tasks` and `handlers` are plural.

---

## 8. How to read a playbook

Consider this example:

```yaml
---
- name: Create a lab directory
  hosts: three_tier_app
  become: false
  gather_facts: false

  tasks:
    - name: Ensure the lab directory exists
      file:
        path: /tmp/ansible-playbook-lab
        state: directory
        mode: "0755"
```

Read it from top to bottom:

1. `---` begins the YAML document.
2. The first `-` begins a play because a playbook is a list of plays.
3. `name` describes the play.
4. `hosts` targets the `three_tier_app` inventory group.
5. `become: false` means the tasks do not request root privileges.
6. `gather_facts: false` skips automatic fact gathering.
7. `tasks` begins the ordered list of tasks.
8. The second `- name` begins a task.
9. `file` is the module used by the task.
10. `path`, `state`, and `mode` are arguments passed to the `file` module.
11. `state: directory` expresses the desired state: the directory must exist.

---

## 9. Prepare the project

Change to the project directory:

```bash
cd /home/ansibleadmin/automation
```

Confirm the active configuration file:

```bash
ansible --version
```

Confirm the configured inventory:

```bash
ansible-inventory --graph
```

Confirm the target group contains the expected nodes:

```bash
ansible three_tier_app --list-hosts
```

Test connectivity:

```bash
ansible three_tier_app -m ping
```

Create a directory for playbooks:

```bash
mkdir -p playbooks
```

Expected project structure:

```text
automation/
├── ansible.cfg
├── inventory/
│   └── nodes
└── playbooks/
```

---

## 10. Lab 1 - First playbook

Create the file:

```bash
vim playbooks/01-first-playbook.yml
```

Add:

```yaml
---
- name: First Ansible playbook
  hosts: three_tier_app
  gather_facts: false

  tasks:
    - name: Test Ansible connectivity
      ping:

    - name: Display a message
      debug:
        msg: "Hello from Ansible on {{ inventory_hostname }}"
```

This playbook does not change the managed nodes. It tests Ansible connectivity and displays each inventory hostname.

Validate it:

```bash
ansible-playbook playbooks/01-first-playbook.yml --syntax-check
```

Run it:

```bash
ansible-playbook playbooks/01-first-playbook.yml
```

---

## 11. Lab 2 - Variables, lists, mappings, loops, facts, and conditions

Create the file:

```bash
vim playbooks/02-playbook-fundamentals-lab.yml
```

Add:

```yaml
---
- name: Practice Ansible playbook fundamentals
  hosts: three_tier_app
  become: false
  gather_facts: true

  vars:
    lab_directory: /tmp/ansible-playbook-lab
    lab_owner: ansibleadmin
    lab_group: ansibleadmin
    lab_mode: "0755"
    course_title: Ansible Playbook Fundamentals
    managed_files:
      - name: introduction.txt
        description: This file introduces the playbook lab.
      - name: inventory-host.txt
        description: This file records the Ansible inventory hostname.
      - name: operating-system.txt
        description: This file records selected operating-system facts.

  tasks:
    - name: Display the current managed node
      debug:
        msg: "Running on {{ inventory_hostname }} at {{ ansible_host }}"

    - name: Ensure the lab directory exists
      file:
        path: "{{ lab_directory }}"
        state: directory
        owner: "{{ lab_owner }}"
        group: "{{ lab_group }}"
        mode: "{{ lab_mode }}"

    - name: Create files from a list of mappings
      copy:
        content: |
          Course: {{ course_title }}
          Host: {{ inventory_hostname }}
          Purpose: {{ item.description }}
        dest: "{{ lab_directory }}/{{ item.name }}"
        owner: "{{ lab_owner }}"
        group: "{{ lab_group }}"
        mode: "0644"
      loop: "{{ managed_files }}"

    - name: Store operating-system facts in a file
      copy:
        content: |
          Hostname: {{ ansible_hostname }}
          Distribution: {{ ansible_distribution }}
          Version: {{ ansible_distribution_version }}
          Architecture: {{ ansible_architecture }}
          Default IPv4: {{ ansible_default_ipv4.address | default('not available') }}
        dest: "{{ lab_directory }}/facts.txt"
        owner: "{{ lab_owner }}"
        group: "{{ lab_group }}"
        mode: "0644"
      when: ansible_os_family == "RedHat"

    - name: Inspect the lab directory
      command: "ls -la {{ lab_directory }}"
      register: lab_listing
      changed_when: false

    - name: Display the saved command output
      debug:
        var: lab_listing.stdout_lines
```

### Concepts demonstrated

| Playbook feature | Example |
|---|---|
| String variable | `course_title` |
| List | `managed_files` |
| Mapping | Each item containing `name` and `description` |
| Variable expression | `{{ lab_directory }}` |
| Loop | `loop: "{{ managed_files }}"` |
| Current loop item | `item.name` and `item.description` |
| Facts | `ansible_distribution` and `ansible_hostname` |
| Condition | `when: ansible_os_family == "RedHat"` |
| Registered result | `register: lab_listing` |
| Result display | `debug: var=lab_listing.stdout_lines` in YAML form |
| Idempotency correction | `changed_when: false` for a read-only command |

> `ansible_host` comes from inventory. `inventory_hostname` is the name Ansible uses for that host in inventory. Facts such as `ansible_distribution` are collected by `gather_facts: true`.

---

## 12. Validate and run a playbook

### Step 1: Check YAML and Ansible syntax

```bash
ansible-playbook playbooks/02-playbook-fundamentals-lab.yml --syntax-check
```

This checks the playbook structure but does not prove that every task will succeed at runtime.

### Step 2: List the targeted hosts

```bash
ansible-playbook playbooks/02-playbook-fundamentals-lab.yml --list-hosts
```

### Step 3: List the tasks

```bash
ansible-playbook playbooks/02-playbook-fundamentals-lab.yml --list-tasks
```

### Step 4: Preview changes

```bash
ansible-playbook playbooks/02-playbook-fundamentals-lab.yml --check --diff
```

Check mode is a simulation. Some modules fully support it, some support it partially, and command-like modules may be skipped or behave differently. It is not a guarantee of a successful real run.

### Step 5: Run the playbook

```bash
ansible-playbook playbooks/02-playbook-fundamentals-lab.yml
```

### Step 6: Run with additional detail

```bash
ansible-playbook playbooks/02-playbook-fundamentals-lab.yml -v
```

Use `-vv`, `-vvv`, or `-vvvv` only when more troubleshooting detail is needed.

---

## 13. Understand the play recap

Example:

```text
PLAY RECAP
node1 : ok=7 changed=2 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

| Field | Meaning |
|---|---|
| `ok` | Tasks completed successfully, including tasks that changed something |
| `changed` | Tasks reported that they changed managed-node state |
| `unreachable` | Ansible could not connect to the host |
| `failed` | A task failed after connecting |
| `skipped` | A condition or selection caused a task not to run |
| `rescued` | A failed task was handled by a `rescue` section |
| `ignored` | A failure occurred but was allowed to continue |

---

## 14. Test idempotency

Idempotency means that after the desired state has been reached, running the same automation again should not make unnecessary changes.

Run the playbook a second time:

```bash
ansible-playbook playbooks/02-playbook-fundamentals-lab.yml
```

The second run should normally report:

```text
changed=0
```

Why this lab can be idempotent:

- `file` changes the directory only when its state or properties differ.
- `copy` changes a file only when its content or properties differ.
- The read-only `command` task uses `changed_when: false`.

Not every Ansible module is naturally idempotent. The `command`, `shell`, and `raw` modules usually cannot determine desired state by themselves, so they often report `CHANGED` whenever they run.

---

## 15. Useful playbook execution options

### Run on only one host

```bash
ansible-playbook playbooks/02-playbook-fundamentals-lab.yml --limit node1
```

`hosts` sets the play's permitted target pattern. `--limit` narrows that target for the current execution.

### Ask before each task

```bash
ansible-playbook playbooks/02-playbook-fundamentals-lab.yml --step
```

### Start at a named task

```bash
ansible-playbook playbooks/02-playbook-fundamentals-lab.yml \
  --start-at-task "Store operating-system facts in a file"
```

### Ask for a sudo password when needed

```bash
ansible-playbook playbooks/example.yml --ask-become-pass
```

### Use a different inventory explicitly

```bash
ansible-playbook -i ./inventory/nodes playbooks/01-first-playbook.yml
```

If `ansible.cfg` already points to `./inventory`, `-i` is unnecessary while running from the project directory.

---

## 16. Lab 3 - Handlers and notifications

A handler is a special task that normally runs only when another task reports a change and sends a notification. Handlers are commonly used to restart or reload services after a configuration change.

The following optional example safely manages a local lab file and creates a timestamp-free marker through an idempotent module.

Create:

```bash
vim playbooks/03-handler-demo.yml
```

Add:

```yaml
---
- name: Demonstrate notifications and handlers
  hosts: three_tier_app
  gather_facts: false

  vars:
    lab_directory: /tmp/ansible-playbook-lab

  tasks:
    - name: Ensure the lab directory exists
      file:
        path: "{{ lab_directory }}"
        state: directory
        mode: "0755"

    - name: Manage the demonstration configuration
      copy:
        content: |
          training_mode=enabled
          managed_by=ansible
        dest: "{{ lab_directory }}/demo.conf"
        mode: "0644"
      notify: Create handler marker

  handlers:
    - name: Create handler marker
      copy:
        content: "The configuration task notified this handler.\n"
        dest: "{{ lab_directory }}/handler-ran.txt"
        mode: "0644"
```

Run it twice:

```bash
ansible-playbook playbooks/03-handler-demo.yml
ansible-playbook playbooks/03-handler-demo.yml
```

On the first run, `demo.conf` is created and the handler is notified. On the second run, the configuration is unchanged, so the handler should not run.

In a production example, the handler might use `service` or `systemd` to restart a service. A service restart was intentionally avoided in this introductory lab.

---

## 17. Verification commands

List the directory on all managed nodes:

```bash
ansible three_tier_app -m command \
  -a "ls -la /tmp/ansible-playbook-lab"
```

Display the facts file:

```bash
ansible three_tier_app -m command \
  -a "cat /tmp/ansible-playbook-lab/facts.txt"
```

Display the handler marker:

```bash
ansible three_tier_app -m command \
  -a "cat /tmp/ansible-playbook-lab/handler-ran.txt"
```

Use `command` here because no pipe, redirection, wildcard expansion, or other shell feature is required.

---

## 18. Cleanup playbook

Create:

```bash
vim playbooks/99-cleanup-playbook-lab.yml
```

Add:

```yaml
---
- name: Remove files created by the playbook lab
  hosts: three_tier_app
  gather_facts: false

  tasks:
    - name: Ensure the lab directory is absent
      file:
        path: /tmp/ansible-playbook-lab
        state: absent
```

Preview the cleanup:

```bash
ansible-playbook playbooks/99-cleanup-playbook-lab.yml --check --diff
```

Run the cleanup:

```bash
ansible-playbook playbooks/99-cleanup-playbook-lab.yml
```

Verify:

```bash
ansible three_tier_app -m stat \
  -a "path=/tmp/ansible-playbook-lab"
```

Look for:

```text
"exists": false
```

Run the cleanup playbook again. It should report `changed=0`, demonstrating idempotency.

---

## 19. Common mistakes and troubleshooting

### Error: YAML syntax problem

Possible causes:

- incorrect indentation;
- a tab was used;
- a colon is missing;
- a list item is missing `-`;
- an unquoted special value was used.

Check:

```bash
ansible-playbook playbooks/02-playbook-fundamentals-lab.yml --syntax-check
```

### Error: `conflicting action statements`

A task normally invokes one module. This is invalid:

```yaml
- name: Invalid task
  file:
    path: /tmp/example
    state: directory
  copy:
    content: example
    dest: /tmp/example/file.txt
```

Create two separate tasks instead.

### Error: no hosts matched

Check the group name and inventory:

```bash
ansible-inventory --graph
ansible three_tier_app --list-hosts
```

### Error: unreachable host

Test SSH and then use Ansible verbosity:

```bash
ssh -i /home/ansibleadmin/.ssh/ansible-key ansibleadmin@node1
ansible node1 -m ping -vvvv
```

### Error: permission denied

The task may require privilege escalation. Add this at play level when root access is genuinely required:

```yaml
become: true
```

If sudo requires a password, run with:

```bash
ansible-playbook playbooks/example.yml --ask-become-pass
```

### Error: variable is undefined

Check spelling, scope, and whether facts are enabled. If using facts, confirm:

```yaml
gather_facts: true
```

### A read-only command reports `CHANGED`

The `command` and `shell` modules usually report that they ran, not whether the system state changed. For a truly read-only task, use:

```yaml
changed_when: false
```

### `--check` does not predict everything

Check mode depends on module support. Always perform syntax checking, use check mode where useful, and test the real playbook safely in a lab before production use.

---

## 20. Practice assignment

Create `playbooks/04-student-practice.yml` that does the following:

1. Targets `three_tier_app`.
2. Enables fact gathering.
3. Defines `/tmp/student-playbook-practice` as a variable.
4. Creates the directory with mode `0755`.
5. Uses a loop to create these three empty files:
   - `node.txt`
   - `os.txt`
   - `memory.txt`
6. Writes `inventory_hostname` and `ansible_host` to `node.txt`.
7. Writes the distribution name and version to `os.txt`.
8. Writes total memory from `ansible_memtotal_mb` to `memory.txt`.
9. Uses a condition so the file-writing tasks run only for the Red Hat OS family.
10. Registers the output of `ls -la /tmp/student-playbook-practice`.
11. Displays the registered standard-output lines with `debug`.
12. Produces `changed=0` on the second run.
13. Includes a separate cleanup playbook.

Required evidence:

```bash
ansible-playbook playbooks/04-student-practice.yml --syntax-check
ansible-playbook playbooks/04-student-practice.yml --check --diff
ansible-playbook playbooks/04-student-practice.yml
ansible-playbook playbooks/04-student-practice.yml
```

Document the play recap from both real runs and explain why the second run should report no changes.

---

## 21. Quick-reference tables

### Common desired-state values

| Value | Typical meaning |
|---|---|
| `present` | A resource such as a package or user must exist |
| `absent` | A resource must not exist |
| `latest` | A package must be installed at the newest available repository version |
| `directory` | A path must exist as a directory |
| `file` | A path must exist as a regular file; behavior depends on the module |
| `touch` | Create a file if absent and update timestamps if present |
| `started` | A service must be running |
| `stopped` | A service must not be running |
| `restarted` | Restart a service when the task runs |
| `reloaded` | Reload a service configuration when the task runs |

The accepted `state` values depend on the module. Check them with:

```bash
ansible-doc file
ansible-doc copy
ansible-doc service
```

### Common modules for early playbook practice

| Module | Purpose |
|---|---|
| `ping` | Test Ansible connectivity and Python execution |
| `debug` | Display messages or variable values |
| `file` | Manage files, directories, links, permissions, and absence |
| `copy` | Copy local content or create managed text files |
| `lineinfile` | Manage a specific line in a text file |
| `command` | Run a command without a shell |
| `shell` | Run a command through a shell when shell features are necessary |
| `dnf` | Manage packages on Rocky Linux 9 |
| `service` | Manage services in a portable way |
| `systemd` | Manage systemd services and units |
| `uri` | Make HTTP or HTTPS requests |
| `stat` | Inspect a path without changing it |
| `setup` | Gather managed-node facts |

### Recommended validation sequence

```bash
ansible-inventory --graph
ansible three_tier_app -m ping
ansible-playbook playbooks/example.yml --syntax-check
ansible-playbook playbooks/example.yml --list-hosts
ansible-playbook playbooks/example.yml --list-tasks
ansible-playbook playbooks/example.yml --check --diff
ansible-playbook playbooks/example.yml
ansible-playbook playbooks/example.yml
```

---

## 22. Suggested learning path

After completing this foundation lab, study these topics in order:

1. Variables and variable precedence
2. Facts and custom facts
3. Loops
4. Conditions
5. Registered results
6. Handlers and notifications
7. Tags
8. Blocks, rescue, and always
9. Templates with Jinja2
10. Task imports and includes
11. Roles
12. Collections
13. Ansible Vault
14. Troubleshooting with verbosity

This order moves from basic playbook syntax to reusable and production-oriented automation.

---

## Final summary

- A playbook is a YAML list containing one or more plays.
- A play targets inventory hosts and contains ordered tasks.
- A task normally invokes one module with its arguments.
- Variables store reusable values.
- Lists and mappings organize structured data.
- Loops repeat tasks, conditions control execution, and handlers react to changes.
- Validate before running, use check mode carefully, verify the result, and run the playbook again to test idempotency.
- Keep a cleanup playbook for repeatable lab practice.
