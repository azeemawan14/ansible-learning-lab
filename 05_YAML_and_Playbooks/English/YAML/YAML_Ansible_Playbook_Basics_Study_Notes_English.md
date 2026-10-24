# YAML and Ansible Playbook Basics — English Study Notes

> These notes explain YAML structure and Ansible playbooks through indentation, parent and child keys, mappings, lists, modules, arguments, and practical examples.

---

## Index

1. [Learning objectives](#1-learning-objectives)
2. [What is YAML?](#2-what-is-yaml)
3. [Fundamental YAML rules](#3-fundamental-yaml-rules)
4. [Keys and values](#4-keys-and-values)
5. [Parent and child keys](#5-parent-and-child-keys)
6. [Mappings or dictionaries](#6-mappings-or-dictionaries)
7. [Sequences or lists](#7-sequences-or-lists)
8. [Mapping versus list](#8-mapping-versus-list)
9. [Scalar values](#9-scalar-values)
10. [Nested data structures](#10-nested-data-structures)
11. [Multiline text: pipe and greater-than](#11-multiline-text-pipe-and-greater-than)
12. [What is an Ansible playbook?](#12-what-is-an-ansible-playbook)
13. [Important playbook components](#13-important-playbook-components)
14. [Why can a module value appear blank?](#14-why-can-a-module-value-appear-blank)
15. [Complete playbook example](#15-complete-playbook-example)
16. [Parent-child structure of the example](#16-parent-child-structure-of-the-example)
17. [Ansible variables](#17-ansible-variables)
18. [Why quote file permissions?](#18-why-quote-file-permissions)
19. [Playbook validation and safe testing](#19-playbook-validation-and-safe-testing)
20. [Idempotency](#20-idempotency)
21. [Common mistakes](#21-common-mistakes)
22. [Quick-reference table](#22-quick-reference-table)
23. [Practice exercises](#23-practice-exercises)
24. [Quick revision summary](#24-quick-revision-summary)

---

## 1. Learning objectives

After reading these notes, you should be able to:

- Explain how YAML indentation represents structure.
- Identify parent and child keys.
- Distinguish a mapping from a sequence.
- Recognize scalar and nested values.
- Explain plays, tasks, modules, and arguments.
- Write and validate a basic Ansible playbook.

[Back to Index](#index)

---

## 2. What is YAML?

**YAML** is a recursive abbreviation for:

> **YAML Ain't Markup Language**

YAML is a human-readable **data-serialization format**. It provides a structured way to represent data so that people and applications can read it.

Ansible uses YAML to write playbooks. YAML itself is not an automation tool or a programming language.

### Simple relationship

| Component | Purpose |
|---|---|
| Ansible | The automation engine |
| Inventory | Identifies managed nodes |
| Playbook | Contains automation instructions |
| YAML | Provides structure for the instructions |

[Back to Index](#index)

---

## 3. Fundamental YAML rules

### Rule 1: Use spaces for indentation

```yaml
student:
  name: Khalid
  course: Ansible
```

The two spaces before `name` and `course` show that both keys belong under `student`.

### Rule 2: Do not use tabs

Tabs can cause YAML parsing errors. Use spaces consistently.

### Rule 3: Keep the same indentation at the same level

```yaml
student:
  name: Khalid
  course: Ansible
```

`name` and `course` are at the same level, so they have identical indentation.

### Rule 4: Put a space after a colon

Correct:

```yaml
name: Khalid
```

Incorrect:

```yaml
name:Khalid
```

### Rule 5: Begin list items with a hyphen

```yaml
packages:
  - git
  - curl
  - tree
```

### One-line definition

> **Indentation is the use of spaces at the beginning of YAML lines to represent structure and parent-child relationships.**

[Back to Index](#index)

---

## 4. Keys and values

YAML data is commonly written in `key: value` form.

```yaml
course: Ansible
```

- `course` is the key.
- `Ansible` is the value.
- The colon separates the key from its value.

Another example:

```yaml
state: present
```

- `state` is the key.
- `present` is its value.

[Back to Index](#index)

---

## 5. Parent and child keys

### Definitions

- **Parent key:** A key that contains indented data beneath it.
- **Child key:** A key nested under a parent key.

### Example

```yaml
student:
  name: Khalid
  course: Ansible
```

Structure:

```text
student (parent)
├── name (child) → Khalid (value)
└── course (child) → Ansible (value)
```

### A key can be both a child and a parent

```yaml
students:
  student1:
    name: Khalid
    course: Ansible
```

- `students` is the top-level parent.
- `student1` is a child of `students`.
- `student1` is also the parent of `name` and `course`.

[Back to Index](#index)

---

## 6. Mappings or dictionaries

A mapping is a collection of key-value pairs.

```yaml
student:
  name: Khalid
  course: Ansible
```

This is a nested mapping. It does not use hyphens.

A mapping answers the question:

> Which value belongs to which key?

### Ansible example

```yaml
file:
  path: /tmp/yaml-study-lab
  state: directory
  mode: "0755"
```

- `file` is the parent key and Ansible module.
- `path`, `state`, and `mode` are its child arguments.

[Back to Index](#index)

---

## 7. Sequences or lists

A sequence is an ordered collection of items. Each list item normally begins with a hyphen followed by a space.

```yaml
packages:
  - git
  - curl
  - tree
```

- `packages` is the parent key.
- `git`, `curl`, and `tree` are list items.

### Ansible module example

```yaml
dnf:
  name:
    - git
    - curl
    - tree
  state: present
```

Structure:

```text
dnf (parent/module)
├── name (child/argument)
│   ├── git  (list item)
│   ├── curl (list item)
│   └── tree (list item)
└── state (child/argument) → present (value)
```

[Back to Index](#index)

---

## 8. Mapping versus list

| Feature | Mapping | Sequence/List |
|---|---|---|
| Purpose | Associates keys with values | Stores ordered items |
| Common syntax | `key: value` | `- item` |
| Example | `name: Khalid` | `- git` |
| Main idea | Which value belongs to a key? | Which items belong to a collection? |

### Students represented as a mapping

```yaml
students:
  student1:
    name: Khalid
    course: Ansible
  student2:
    name: Ahmed
    course: Linux
```

`student1` and `student2` are keys, not list items.

### Students represented as a list

```yaml
students:
  - name: Khalid
    course: Ansible
  - name: Ahmed
    course: Linux
```

Each hyphen begins a new student list item.

[Back to Index](#index)

---

## 9. Scalar values

A scalar is a single value.

| Scalar type | Example |
|---|---|
| String | `Ansible` |
| Integer | `200` |
| Boolean | `true` or `false` |
| Null | `null` |

Example:

```yaml
course: Ansible
gather_facts: false
port: 80
```

`Ansible`, `false`, and `80` are scalar values.

[Back to Index](#index)

---

## 10. Nested data structures

A structure is nested when a mapping or list appears inside another mapping or list.

```yaml
department:
  students:
    - name: Khalid
      course: Ansible
    - name: Ahmed
      course: Linux
```

In this example:

- `department` contains `students`.
- The value of `students` is a list.
- Each list item is itself a mapping.

[Back to Index](#index)

---

## 11. Multiline text: pipe and greater-than

### Pipe `|`

The pipe creates a literal multiline string and preserves line breaks.

```yaml
content: |
  YAML is a data format.
  Ansible uses YAML to structure playbooks.
```

The two lines remain separate in the resulting content.

### Greater-than `>`

The greater-than symbol creates a folded multiline string. Normal line breaks are generally converted into spaces.

```yaml
message: >
  This is a long
  message written on
  multiple YAML lines.
```

| Symbol | Behavior |
|---|---|
| `|` | Preserves line breaks |
| `>` | Folds ordinary lines together with spaces |

[Back to Index](#index)

---

## 12. What is an Ansible playbook?

An Ansible playbook is a YAML file containing repeatable automation instructions.

A playbook specifies:

1. Which hosts automation should target.
2. Whether privilege escalation is required.
3. Whether facts should be gathered.
4. Which tasks should run and in what order.

### One-line definition

> **An Ansible playbook is a YAML file containing one or more plays that define repeatable automation.**

[Back to Index](#index)

---

## 13. Important playbook components

| Term | Definition | Example |
|---|---|---|
| Playbook | A YAML file containing one or more plays | `site.yml` |
| Play | Connects target hosts with an ordered task list | `- name: Configure servers` |
| `name` | Human-readable description of a play or task | `name: Install Nginx` |
| `hosts` | Selects the inventory target | `hosts: three_tier_app` |
| `become` | Requests privilege escalation | `become: true` |
| `gather_facts` | Enables or disables automatic fact gathering | `gather_facts: false` |
| `tasks` | Begins the ordered task sequence | `tasks:` |
| Task | One unit of automation work | Create a directory |
| Module | Performs the actual operation | `file`, `copy`, `dnf` |
| Argument | Provides input to a module | `path`, `state`, `mode` |

### Why is a playbook a list?

```yaml
---
- name: First play
  hosts: all
```

The top-level hyphen begins a play. A playbook can contain a list of one or more plays.

### Why are tasks a list?

```yaml
tasks:
  - name: First task
    ping:

  - name: Second task
    command: uptime
```

Each hyphen under `tasks` begins a new task.

[Back to Index](#index)

---

## 14. Why can a module value appear blank?

```yaml
file:
  path: /tmp/yaml-study-lab
  state: directory
  mode: "0755"
```

Although nothing appears after `file:` on the same line, its value is not empty. Its value is the indented mapping containing:

- `path`
- `state`
- `mode`

Another example:

```yaml
ping:
```

The `ping` module can run without arguments, so no nested argument is required.

### Important rule

> A module value is not always blank. It may be a nested mapping below the module key, while some modules can also run without arguments.

[Back to Index](#index)

---

## 15. Complete playbook example

```yaml
---
- name: Create a study file on all managed nodes
  hosts: three_tier_app
  gather_facts: false

  tasks:
    - name: Ensure the lab directory exists
      file:
        path: /tmp/yaml-study-lab
        state: directory
        mode: "0755"

    - name: Create a study file
      copy:
        content: |
          YAML is a data format.
          Ansible uses YAML to structure playbooks.
          Inventory host: {{ inventory_hostname }}
        dest: /tmp/yaml-study-lab/notes.txt
        mode: "0644"
```

### What does the playbook do?

1. Targets the `three_tier_app` inventory group.
2. Skips automatic fact gathering.
3. Ensures `/tmp/yaml-study-lab` exists as a directory.
4. Sets the directory mode to `0755`.
5. Creates `notes.txt` on every targeted node.
6. Writes the current inventory hostname into the file.
7. Sets the file mode to `0644`.

[Back to Index](#index)

---

## 16. Parent-child structure of the example

```text
Playbook
└── Play (top-level hyphen)
    ├── name
    ├── hosts
    ├── gather_facts
    └── tasks
        ├── Task 1 (first hyphen under tasks)
        │   ├── name
        │   └── file (module)
        │       ├── path
        │       ├── state
        │       └── mode
        └── Task 2 (second hyphen under tasks)
            ├── name
            └── copy (module)
                ├── content
                ├── dest
                └── mode
```

### Which entries are list items?

- The top-level hyphen begins a play list item.
- The first hyphen under `tasks` begins Task 1.
- The second hyphen under `tasks` begins Task 2.

### Parents and their direct children

| Parent | Direct children |
|---|---|
| Play | `name`, `hosts`, `gather_facts`, `tasks` |
| `tasks` | Task 1 and Task 2 |
| Task 1 | `name`, `file` |
| `file` | `path`, `state`, `mode` |
| Task 2 | `name`, `copy` |
| `copy` | `content`, `dest`, `mode` |

[Back to Index](#index)

---

## 17. Ansible variables

```yaml
Inventory host: {{ inventory_hostname }}
```

`{{ inventory_hostname }}` is a Jinja variable expression. Ansible evaluates it at runtime and replaces it with the current inventory hostname.

- The file on Node1 contains `node1`.
- The file on Node2 contains `node2`.
- The file on Node3 contains `node3`.

### Common variables

| Variable | Meaning |
|---|---|
| `inventory_hostname` | The current host's inventory name |
| `ansible_host` | IP address or hostname used for the connection |
| `ansible_user` | SSH connection user |
| `ansible_python_interpreter` | Python executable path on the managed node |

[Back to Index](#index)

---

## 18. Why quote file permissions?

Recommended:

```yaml
mode: "0755"
mode: "0644"
```

Quoting helps preserve the exact permission representation and avoids unintended numeric interpretation.

| Mode | Common meaning |
|---|---|
| `"0755"` | Owner: rwx, Group: r-x, Others: r-x |
| `"0644"` | Owner: rw-, Group: r--, Others: r-- |

[Back to Index](#index)

---

## 19. Playbook validation and safe testing

Assume the playbook is named `yaml-study.yml`.

### Step 1: Check syntax

```bash
ansible-playbook yaml-study.yml --syntax-check
```

This parses the YAML and validates the Ansible playbook structure without performing a normal task run.

### Step 2: Use check mode (dry run)

```bash
ansible-playbook yaml-study.yml --check
```

Check mode simulates possible changes. Not every module supports check mode equally.

### Step 3: Use check mode with diff

```bash
ansible-playbook yaml-study.yml --check --diff
```

For supported files and templates, `--diff` displays before-and-after differences.

### Step 4: Add verbose output

```bash
ansible-playbook yaml-study.yml -v
ansible-playbook yaml-study.yml -vv
ansible-playbook yaml-study.yml -vvv
```

| Option | Detail level |
|---|---|
| `-v` | Some additional information |
| `-vv` | More execution details |
| `-vvv` | Connection and troubleshooting details |
| `-vvvv` | Very detailed connection debugging |

### Step 5: Run normally

```bash
ansible-playbook yaml-study.yml
```

### Step 6: Test on one host first

```bash
ansible-playbook yaml-study.yml --limit node1
```

Testing first on a limited host is a useful safety practice.

[Back to Index](#index)

---

## 20. Idempotency

Idempotency means that running the same automation again should not make unnecessary changes when the desired state already exists.

Possible first run:

```text
changed=2
```

Possible second run:

```text
changed=0
```

`changed=0` on the second run commonly demonstrates that the resources are already in their desired state.

### Important note

The `shell` and `command` modules commonly report `changed` when they run because Ansible may not automatically know whether the command changed the system.

[Back to Index](#index)

---

## 21. Common mistakes

### Mistake 1: Using tabs

**Solution:** Configure the editor to insert spaces.

### Mistake 2: Inconsistent indentation at the same level

Incorrect:

```yaml
student:
  name: Khalid
   course: Ansible
```

Correct:

```yaml
student:
  name: Khalid
  course: Ansible
```

### Mistake 3: Missing the space after a colon

Incorrect:

```yaml
name:Khalid
```

Correct:

```yaml
name: Khalid
```

### Mistake 4: Forgetting list-item hyphens

Incorrect:

```yaml
packages:
  git
  curl
```

Correct:

```yaml
packages:
  - git
  - curl
```

### Mistake 5: Mixing play, task, and module indentation

`hosts` and `tasks` are children of a play. Modules are children of tasks. Module arguments are children of their module.

### Mistake 6: Assuming every valid YAML file is a valid playbook

A file may be valid YAML but still fail Ansible's required playbook structure or keyword validation.

### Mistake 7: Writing unquoted file modes

Treat permission modes as strings:

```yaml
mode: "0644"
```

[Back to Index](#index)

---

## 22. Quick-reference table

| Term or symbol | Meaning |
|---|---|
| Indentation | Starting spaces that represent structure |
| Parent | A key containing nested data |
| Child | A key indented beneath a parent |
| Key | Label before the colon |
| Value | Data assigned to a key |
| Mapping | Collection of key-value pairs |
| Sequence/List | Ordered collection of items |
| `-` | Begins a list item |
| `:` | Separates a key from its value |
| `|` | Preserves multiline line breaks |
| `>` | Folds ordinary multiline text |
| Scalar | A single string, number, Boolean, or null value |
| Playbook | YAML file containing plays |
| Play | Connects target hosts to tasks |
| Task | One unit of automation work |
| Module | Performs the actual operation |
| Argument | Input supplied to a module |
| `{{ variable }}` | Runtime Jinja expression |
| `---` | YAML document-start marker |

[Back to Index](#index)

---

## 23. Practice exercises

### Exercise 1: Identify parents and children

```yaml
service:
  name: nginx
  state: started
  enabled: true
```

Identify:

1. The parent key
2. The child keys
3. The scalar values

### Exercise 2: Write a package list

Write a YAML task that uses the `dnf` module to install `httpd`, `git`, and `tree`.

### Exercise 3: Convert a mapping into a list

```yaml
students:
  student1:
    name: Khalid
    course: Ansible
  student2:
    name: Ahmed
    course: Linux
```

Convert this structure into a list of students.

### Exercise 4: Find the error

```yaml
tasks:
  - name: Create directory
    file:
      path: /tmp/lab
       state: directory
      mode: "0755"
```

Hint: Inspect the indentation of `state`.

### Exercise 5: Run the validation sequence

```bash
ansible-playbook yaml-study.yml --syntax-check
ansible-playbook yaml-study.yml --check --diff
ansible-playbook yaml-study.yml --limit node1
ansible-playbook yaml-study.yml
```

[Back to Index](#index)

---

## 24. Quick revision summary

1. YAML uses indentation to represent structure.
2. Use consistent spaces instead of tabs.
3. Keys indented under a parent are its children.
4. A mapping contains key-value pairs.
5. Every list item normally begins with a hyphen.
6. A scalar is one value.
7. A playbook is a top-level list of plays.
8. Each hyphen under `tasks` begins a new task.
9. A module performs work; arguments provide instructions to that module.
10. The pipe preserves multiline line breaks.
11. `{{ inventory_hostname }}` is a runtime variable expression.
12. Quoting file modes is recommended.
13. `--syntax-check` validates the playbook before execution.
14. `--check` provides a dry run when supported.
15. `changed=0` on a second run commonly demonstrates idempotency.

---

## Final memory line

> **The playbook says what the automation should do; hosts say where it should run; a task is one step; a module performs the work; arguments provide module details; and YAML indentation shows the structure of everything.**

[Back to Index](#index)

