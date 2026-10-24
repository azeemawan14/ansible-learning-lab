# Ansible Reusable Task Files: `include_tasks` and `import_tasks`

## Table of Contents

1. [Learning objectives](#1-learning-objectives)
2. [The requirement](#2-the-requirement)
3. [Recommended project structure](#3-recommended-project-structure)
4. [What is a task file?](#4-what-is-a-task-file)
5. [Create the reusable copy task](#5-create-the-reusable-copy-task)
6. [Create the main playbook](#6-create-the-main-playbook)
7. [How the two files work together](#7-how-the-two-files-work-together)
8. [`include_tasks` explained](#8-include_tasks-explained)
9. [`include_tasks` versus `import_tasks`](#9-include_tasks-versus-import_tasks)
10. [Problems in the original YAML](#10-problems-in-the-original-yaml)
11. [`file` module versus `copy` module](#11-file-module-versus-copy-module)
12. [Validate the files](#12-validate-the-files)
13. [Run the playbook](#13-run-the-playbook)
14. [Verify the results](#14-verify-the-results)
15. [Idempotency considerations](#15-idempotency-considerations)
16. [Using variables in the reusable task](#16-using-variables-in-the-reusable-task)
17. [Using the task file from multiple playbooks](#17-using-the-task-file-from-multiple-playbooks)
18. [Common errors and solutions](#18-common-errors-and-solutions)
19. [Cleanup](#19-cleanup)
20. [Quick-reference commands](#20-quick-reference-commands)
21. [Practice questions](#21-practice-questions)
22. [Summary](#22-summary)

---

## 1. Learning objectives

After completing this lesson, you should be able to:

- Separate tasks from a main Ansible playbook.
- Reuse a task file with `include_tasks`.
- Understand the difference between a playbook and a task file.
- Select the correct module for creating files and adding content.
- Recognize incorrect module arguments and indentation.
- Validate, execute, and verify a multi-file playbook.
- Understand the basic difference between `include_tasks` and `import_tasks`.

---

## 2. The requirement

We want the main playbook to perform these actions on all inventory hosts:

1. Create `/tmp/yaml-study-lab`.
2. Create an empty file named `abc.txt`.
3. Load another YAML file containing a `copy` task.
4. Create `notes.txt` with study content.
5. Insert the current inventory hostname into `notes.txt`.

Instead of placing every task in one large playbook, the copy task will be stored in a separate reusable task file.

---

## 3. Recommended project structure

```text
/home/ansibleadmin/automation/
├── ansible.cfg
├── inventory/
├── playbooks/
│   ├── 02_create-dir-file.yml
│   └── tasks/
│       └── create-study-file.yml
└── roles/
```

Create the task directory:

```bash
mkdir -p /home/ansibleadmin/automation/playbooks/tasks
```

Why use a `tasks` directory?

- It clearly separates reusable tasks from complete playbooks.
- It makes the project easier to understand.
- Multiple playbooks can reuse the same task file.
- It provides a natural learning path toward Ansible roles.

---

## 4. What is a task file?

A **task file** is a YAML file containing a list of one or more Ansible tasks.

A task file normally does **not** contain play-level keywords such as:

```yaml
hosts:
gather_facts:
tasks:
```

Instead, it begins directly with a YAML list of tasks:

```yaml
---
- name: Example task
  copy:
    content: Example
    dest: /tmp/example.txt
```

The main playbook supplies the target hosts and then includes or imports the task file.

---

## 5. Create the reusable copy task

Create the file:

```bash
vim /home/ansibleadmin/automation/playbooks/tasks/create-study-file.yml
```

Add:

```yaml
---
- name: Create a study file with content
  copy:
    content: |
      YAML is a data format.
      Ansible uses YAML to structure playbooks.
      Inventory host: {{ inventory_hostname }}
    dest: /tmp/yaml-study-lab/notes.txt
    mode: "0644"
```

### Line-by-line explanation

| Line | Explanation |
|---|---|
| `---` | Optional YAML document-start marker. |
| `- name:` | Starts a task and gives it a readable description. |
| `copy:` | Calls the Ansible copy module. |
| `content: |` | Supplies multiline content and preserves line breaks. |
| `{{ inventory_hostname }}` | Inserts the current host's inventory name. |
| `dest:` | Sets the destination file on each managed node. |
| `mode: "0644"` | Gives the owner read/write and everyone else read permission. |

`mode` is quoted so YAML treats `0644` as a permission string rather than converting it unexpectedly as a number.

---

## 6. Create the main playbook

Create or correct:

```bash
vim /home/ansibleadmin/automation/playbooks/02_create-dir-file.yml
```

Use:

```yaml
---
- name: Create a directory and files
  hosts: all
  gather_facts: false

  tasks:
    - name: Create the lab directory
      file:
        path: /tmp/yaml-study-lab
        state: directory
        mode: "0755"

    - name: Create an empty abc.txt file
      file:
        path: /tmp/yaml-study-lab/abc.txt
        state: touch
        mode: "0644"

    - name: Include the study-file tasks
      include_tasks: tasks/create-study-file.yml
```

The path passed to `include_tasks` is resolved relative to the playbook that contains the statement. Because the main playbook is in `playbooks/`, the relative path is:

```text
tasks/create-study-file.yml
```

---

## 7. How the two files work together

The execution order is:

1. Ansible reads `02_create-dir-file.yml`.
2. The play targets `all` inventory hosts.
3. The first task creates `/tmp/yaml-study-lab`.
4. The second task creates `/tmp/yaml-study-lab/abc.txt`.
5. `include_tasks` loads `tasks/create-study-file.yml` during execution.
6. The included copy task creates `/tmp/yaml-study-lab/notes.txt`.
7. `inventory_hostname` is evaluated separately for each managed node.

For example:

```text
node1 -> Inventory host: node1
node2 -> Inventory host: node2
node3 -> Inventory host: node3
```

---

## 8. `include_tasks` explained

One-line definition:

> `include_tasks` dynamically loads a list of tasks from another YAML file while the playbook is running.

Syntax:

```yaml
- name: Include another task file
  include_tasks: tasks/create-study-file.yml
```

Benefits:

- Keeps the main playbook smaller.
- Makes tasks reusable.
- Supports dynamic conditions and loops.
- Makes complicated automation easier to organize.

Example with a condition:

```yaml
- name: Include study-file tasks on Rocky Linux
  include_tasks: tasks/create-study-file.yml
  when: ansible_distribution == "Rocky"
```

This conditional example requires facts, so `gather_facts` must not be disabled unless the required fact is obtained another way.

---

## 9. `include_tasks` versus `import_tasks`

| Feature | `include_tasks` | `import_tasks` |
|---|---|---|
| Processing | Dynamic | Static |
| Loaded | During execution | When the playbook is parsed |
| Loops on the include/import statement | Supported | Not normally used/supported in the same dynamic way |
| Best for | Runtime choices, loops and dynamic conditions | Fixed task organization known before execution |

Dynamic example:

```yaml
- name: Dynamically include tasks
  include_tasks: tasks/create-study-file.yml
```

Static example:

```yaml
- name: Statically import tasks
  import_tasks: tasks/create-study-file.yml
```

For this beginner lab, `include_tasks` is easy to observe and is a good choice. If the task file will always be used and requires no runtime selection, `import_tasks` is also reasonable.

---

## 10. Problems in the original YAML

The original section looked similar to:

```yaml
- name: Creating a file
  file:
    path: /tmp/yaml-study-lab/abc.txt
    state: touch
    mode: "0644"

    dest: /tmp/yaml-study-lab/notes.txt
    mode: "0644"
```

It has three problems.

### Problem 1: `dest` is under the wrong module

The `file` module does not use `dest` for this purpose. The `dest` argument belongs to modules such as `copy` and `template`.

### Problem 2: `mode` is repeated

The same YAML mapping should not contain duplicate keys. Two `mode` entries at the same level make the configuration ambiguous and can be rejected by YAML or linting tools.

### Problem 3: The copy content is missing

Creating a text file with content requires the `copy` module with both `content` and `dest`.

Correct form:

```yaml
- name: Create a file containing text
  copy:
    content: |
      Example text
    dest: /tmp/yaml-study-lab/notes.txt
    mode: "0644"
```

---

## 11. `file` module versus `copy` module

| Requirement | Suitable module |
|---|---|
| Create a directory | `file` with `state: directory` |
| Create or update an empty file timestamp | `file` with `state: touch` |
| Set ownership or permissions | `file` or the module managing the resource |
| Create a file containing inline text | `copy` with `content` |
| Transfer a local file to managed nodes | `copy` with `src` and `dest` |
| Generate a file using a Jinja template | `template` |

Examples:

```yaml
- name: Create a directory
  file:
    path: /tmp/example
    state: directory
```

```yaml
- name: Copy inline content
  copy:
    content: "Hello\n"
    dest: /tmp/example/hello.txt
```

---

## 12. Validate the files

Change to the project directory so Ansible can find the project configuration:

```bash
cd /home/ansibleadmin/automation
```

### Display the files

```bash
sed -n '1,200p' playbooks/02_create-dir-file.yml
sed -n '1,200p' playbooks/tasks/create-study-file.yml
```

### Run syntax validation

```bash
ansible-playbook --syntax-check playbooks/02_create-dir-file.yml
```

Expected ending:

```text
playbook: playbooks/02_create-dir-file.yml
```

### Run Ansible Lint if installed

```bash
ansible-lint playbooks/02_create-dir-file.yml
```

If your lab intentionally uses short module names, the linter may recommend fully qualified collection names. This is a style recommendation; short names such as `file:` and `copy:` still work in this lab environment.

---

## 13. Run the playbook

From `/home/ansibleadmin/automation`:

```bash
ansible-playbook playbooks/02_create-dir-file.yml
```

Test on one node first when desired:

```bash
ansible-playbook playbooks/02_create-dir-file.yml --limit node1
```

Use check mode before making changes where supported:

```bash
ansible-playbook playbooks/02_create-dir-file.yml --check --diff
```

Use verbose output for troubleshooting:

```bash
ansible-playbook -v playbooks/02_create-dir-file.yml
```

---

## 14. Verify the results

List the directory on all hosts:

```bash
ansible all -m command -a "ls -l /tmp/yaml-study-lab"
```

Read `notes.txt`:

```bash
ansible all -m command -a "cat /tmp/yaml-study-lab/notes.txt"
```

Check both files:

```bash
ansible all -m command -a "stat /tmp/yaml-study-lab/abc.txt /tmp/yaml-study-lab/notes.txt"
```

Expected resources:

```text
/tmp/yaml-study-lab/
├── abc.txt
└── notes.txt
```

---

## 15. Idempotency considerations

The `copy` task is idempotent. If `notes.txt` already contains the desired content and has the correct mode, another run normally reports:

```text
ok
```

or contributes to:

```text
changed=0
```

However:

```yaml
state: touch
```

updates the access and modification timestamps by default. Therefore, the `abc.txt` task may report `changed` on every run.

If an empty `abc.txt` is not required, remove that task and let the idempotent `copy` task create `notes.txt` directly.

If you want to create an empty file only when it is missing, one beginner-friendly approach is:

```yaml
- name: Check whether abc.txt exists
  stat:
    path: /tmp/yaml-study-lab/abc.txt
  register: abc_file

- name: Create abc.txt only when missing
  file:
    path: /tmp/yaml-study-lab/abc.txt
    state: touch
    mode: "0644"
  when: not abc_file.stat.exists
```

---

## 16. Using variables in the reusable task

The task file can be made more reusable with variables.

Main playbook:

```yaml
---
- name: Create a directory and study file
  hosts: all
  gather_facts: false

  vars:
    study_directory: /tmp/yaml-study-lab
    study_filename: notes.txt

  tasks:
    - name: Create the study directory
      file:
        path: "{{ study_directory }}"
        state: directory
        mode: "0755"

    - name: Include the study-file tasks
      include_tasks: tasks/create-study-file.yml
```

Reusable task file:

```yaml
---
- name: Create a study file with content
  copy:
    content: |
      YAML is a data format.
      Ansible uses YAML to structure playbooks.
      Inventory host: {{ inventory_hostname }}
    dest: "{{ study_directory }}/{{ study_filename }}"
    mode: "0644"
```

This allows the main playbook to control the directory and filename without editing the reusable task file.

---

## 17. Using the task file from multiple playbooks

Another playbook in the same `playbooks` directory can reuse it:

```yaml
---
- name: Create study notes on the web group
  hosts: web
  gather_facts: false

  tasks:
    - name: Ensure the destination directory exists
      file:
        path: /tmp/yaml-study-lab
        state: directory
        mode: "0755"

    - name: Reuse the study-file tasks
      include_tasks: tasks/create-study-file.yml
```

Important: the included copy task expects its destination directory to exist. The main playbook should create the directory before including the task file, or the reusable task file should include its own directory-creation task.

---

## 18. Common errors and solutions

### Error: `conflicting action statements`

Cause: two modules were placed inside the same task.

Incorrect:

```yaml
- name: Incorrect task
  file:
    path: /tmp/example
  copy:
    content: Test
```

Solution: make them two separate tasks.

### Error: `unsupported parameters for (file) module: dest`

Cause: `dest` was placed under `file`.

Solution: use `path` with `file`, or move `dest` under `copy`.

### Error: included file could not be found

Cause: the relative path or filename is incorrect.

Verify:

```bash
ls -l /home/ansibleadmin/automation/playbooks/tasks/create-study-file.yml
```

Use:

```yaml
include_tasks: tasks/create-study-file.yml
```

### Error: destination directory does not exist

Cause: `copy` creates the destination file, but it does not create missing parent directories.

Solution: run the directory task before the copy task.

### Error: YAML indentation problem

Use spaces, not tabs. Keep module arguments indented beneath the module name:

```yaml
- name: Correct indentation
  copy:
    content: Example
    dest: /tmp/example.txt
```

### Error: undefined `inventory_hostname`

`inventory_hostname` is normally available for inventory hosts even when `gather_facts: false`. If the target is not a valid inventory host, verify the inventory and host pattern:

```bash
ansible-inventory --graph
ansible all --list-hosts
```

---

## 19. Cleanup

Preview the target first:

```bash
ansible all -m command -a "ls -ld /tmp/yaml-study-lab"
```

Remove the complete lab directory with the idempotent `file` module:

```bash
ansible all -m file -a "path=/tmp/yaml-study-lab state=absent"
```

Verify:

```bash
ansible all -m command -a "test ! -e /tmp/yaml-study-lab"
```

The verification command returns success when the directory no longer exists.

---

## 20. Quick-reference commands

```bash
# Create the task directory
mkdir -p ~/automation/playbooks/tasks

# Edit the main playbook
vim ~/automation/playbooks/02_create-dir-file.yml

# Edit the reusable task file
vim ~/automation/playbooks/tasks/create-study-file.yml

# Change to the project directory
cd ~/automation

# Check the inventory
ansible-inventory --graph

# Check syntax
ansible-playbook --syntax-check playbooks/02_create-dir-file.yml

# Lint the playbook
ansible-lint playbooks/02_create-dir-file.yml

# Preview changes
ansible-playbook --check --diff playbooks/02_create-dir-file.yml

# Test on node1
ansible-playbook playbooks/02_create-dir-file.yml --limit node1

# Run on all hosts targeted by the play
ansible-playbook playbooks/02_create-dir-file.yml

# Verify
ansible all -m command -a "ls -l /tmp/yaml-study-lab"
ansible all -m command -a "cat /tmp/yaml-study-lab/notes.txt"

# Clean up
ansible all -m file -a "path=/tmp/yaml-study-lab state=absent"
```

---

## 21. Practice questions

1. What is the difference between a complete playbook and a task file?
2. Why does the task file not need `hosts:`?
3. What does `include_tasks` do?
4. Where is a relative included-file path resolved from?
5. Why should the directory task run before the copy task?
6. Which module creates a directory?
7. Which module creates a file containing inline text?
8. Why is `dest` invalid beneath the `file` module in this example?
9. What does `content: |` mean in YAML?
10. What value does `inventory_hostname` provide?
11. What is the basic difference between `include_tasks` and `import_tasks`?
12. Why can `state: touch` report `changed` repeatedly?
13. Which command checks Ansible syntax?
14. Which command performs lint checks?
15. How can the playbook be tested on only `node1`?

---

## 22. Summary

- A playbook defines a play, target hosts, and its task sequence.
- A task file is a reusable YAML list of tasks.
- `include_tasks` dynamically loads a task file during execution.
- Use `file` to manage directories, empty files, permissions, and resource state.
- Use `copy` with `content` and `dest` to create a file containing text.
- Never place `dest` under the `file` module for this use case.
- Avoid duplicate YAML keys such as two `mode` entries at the same level.
- Validate with `--syntax-check`, lint with `ansible-lint`, and test with `--limit node1` before targeting every node.
- Reusable task files are a useful step toward learning Ansible roles.
