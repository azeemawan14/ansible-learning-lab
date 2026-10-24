# Ansible Variables and Loops — Six-Task Lab

## Index

1. [Lab objective](#1-lab-objective)
2. [Lab environment](#2-lab-environment)
3. [Concepts covered](#3-concepts-covered)
4. [Lab preparation](#4-lab-preparation)
5. [Task 1 — Display host information](#5-task-1--display-host-information)
6. [Task 2 — Create the main directory](#6-task-2--create-the-main-directory)
7. [Task 3 — Create subdirectories](#7-task-3--create-subdirectories)
8. [Task 4 — Create study files](#8-task-4--create-study-files)
9. [Task 5 — Install packages](#9-task-5--install-packages)
10. [Task 6 — Verify files](#10-task-6--verify-files)
11. [Complete solution](#11-complete-solution)
12. [Run and verify the lab](#12-run-and-verify-the-lab)
13. [Idempotency test](#13-idempotency-test)
14. [Cleanup](#14-cleanup)
15. [Review questions](#15-review-questions)

---

## 1. Lab objective

This beginner lab practices only two main Ansible concepts:

- Variables
- Loops

Students will define reusable values, process simple lists and dictionaries, and use those values to manage all three lab nodes.

## 2. Lab environment

| Component | Value |
|---|---|
| Control node | `ansible-server.nitclasses.com` |
| Control-node IP | `192.168.1.233` |
| Project directory | `/home/ansibleadmin/automation` |
| Playbook directory | `/home/ansibleadmin/automation/playbooks` |
| Inventory group | `three_tier_app` |
| Managed nodes | `node1`, `node2`, `node3` |
| Remote user | `ansibleadmin` |
| Managed-node OS | Rocky Linux 9 |

## 3. Concepts covered

| Concept | Purpose |
|---|---|
| `vars` | Defines reusable values inside the play |
| Simple variable | Stores one value, such as a path or mode |
| List variable | Stores an ordered collection of values |
| List of dictionaries | Stores items that each have several properties |
| `{{ variable }}` | References a variable through Jinja syntax |
| `loop` | Repeats a task for every list item |
| `item` | Represents the current loop item |
| `loop_control` | Changes the loop variable or displayed label |
| `register` | Saves a task's result in a variable |

## 4. Lab preparation

Move into the Ansible project:

```bash
cd /home/ansibleadmin/automation
```

Confirm that all managed nodes are reachable:

```bash
ansible three_tier_app -m ping
```

Create the playbook:

```bash
vim playbooks/variables-loops-lab.yml
```

Start with this play and variable section:

```yaml
---
- name: Practice Ansible variables and loops
  hosts: three_tier_app
  become: true
  gather_facts: true

  vars:
    lab_directory: /tmp/variables-loops-lab
    directory_mode: "0755"
    file_mode: "0644"

    lab_directories:
      - notes
      - reports
      - backups

    study_files:
      - filename: ansible.txt
        content: Ansible is an automation tool.
      - filename: yaml.txt
        content: YAML is a data-serialization language.
      - filename: loops.txt
        content: Ansible loops repeat a task for multiple items.

    packages:
      - git
      - curl
      - tree

    files_to_verify:
      - /tmp/variables-loops-lab/notes/ansible.txt
      - /tmp/variables-loops-lab/notes/yaml.txt
      - /tmp/variables-loops-lab/notes/loops.txt

  tasks:
```

Add the following six tasks under `tasks:`.

## 5. Task 1 — Display host information

Use variables and facts to display the inventory hostname, operating-system name and version, and primary IPv4 address.

Expected format:

```text
node1 runs Rocky 9.8 and its IP address is 192.168.1.154.
```

Hint:

```yaml
- name: Task 1 - Display managed-node information
  debug:
    msg: >-
      {{ inventory_hostname }} runs
      {{ ansible_distribution }}
      {{ ansible_distribution_version }}
      and its IP address is
      {{ ansible_default_ipv4.address }}.
```

`inventory_hostname` is a magic variable. The other system values are facts, so this play uses `gather_facts: true`.

## 6. Task 2 — Create the main directory

Use these variables:

```yaml
lab_directory: /tmp/variables-loops-lab
directory_mode: "0755"
```

The directory must exist, belong to `ansibleadmin:ansibleadmin`, and have mode `0755`.

Hint:

```yaml
- name: Task 2 - Create the main lab directory
  file:
    path: "{{ lab_directory }}"
    state: directory
    owner: ansibleadmin
    group: ansibleadmin
    mode: "{{ directory_mode }}"
```

## 7. Task 3 — Create subdirectories

Process the `lab_directories` list to create:

```text
/tmp/variables-loops-lab/notes
/tmp/variables-loops-lab/reports
/tmp/variables-loops-lab/backups
```

Use `loop_control` to rename `item` to `directory_name`.

Hint:

```yaml
- name: Task 3 - Create the lab subdirectories
  file:
    path: "{{ lab_directory }}/{{ directory_name }}"
    state: directory
    owner: ansibleadmin
    group: ansibleadmin
    mode: "{{ directory_mode }}"
  loop: "{{ lab_directories }}"
  loop_control:
    loop_var: directory_name
```

During the three iterations, `directory_name` contains `notes`, `reports`, and `backups`.

## 8. Task 4 — Create study files

Process the `study_files` list of dictionaries. Create every file inside the `notes` directory.

Requirements:

- Use `item.filename` for the filename.
- Use `item.content` for the content.
- Use `file_mode` for permissions.
- Display only the filename as the loop label.

Hint:

```yaml
- name: Task 4 - Create the study files
  copy:
    content: "{{ item.content }}\n"
    dest: "{{ lab_directory }}/notes/{{ item.filename }}"
    owner: ansibleadmin
    group: ansibleadmin
    mode: "{{ file_mode }}"
  loop: "{{ study_files }}"
  loop_control:
    label: "{{ item.filename }}"
```

## 9. Task 5 — Install packages

Process the `packages` list containing `git`, `curl`, and `tree`.

Requirements:

- Use the `dnf` module.
- Every package must be present.
- Use a loop for this learning exercise.
- Display the current package name in the output.

Hint:

```yaml
- name: Task 5 - Install the required packages
  dnf:
    name: "{{ item }}"
    state: present
  loop: "{{ packages }}"
  loop_control:
    label: "{{ item }}"
```

> For normal package management, passing the complete list directly to `dnf` is usually more efficient. This lab deliberately uses a loop for practice.

## 10. Task 6 — Verify files

Use `stat` to check the three paths in `files_to_verify`. Register the complete loop result as `study_file_results`.

Requirements:

- Use the `stat` module.
- Read paths from `files_to_verify`.
- Save the results with `register`.
- Do not change the files.

Hint:

```yaml
- name: Task 6 - Verify the study files
  stat:
    path: "{{ item }}"
  loop: "{{ files_to_verify }}"
  register: study_file_results
  loop_control:
    label: "{{ item }}"
```

Because a loop is used, `study_file_results.results` contains a separate result for every checked path.

## 11. Complete solution

```yaml
---
- name: Practice Ansible variables and loops
  hosts: three_tier_app
  become: true
  gather_facts: true

  vars:
    lab_directory: /tmp/variables-loops-lab
    directory_mode: "0755"
    file_mode: "0644"

    lab_directories:
      - notes
      - reports
      - backups

    study_files:
      - filename: ansible.txt
        content: Ansible is an automation tool.
      - filename: yaml.txt
        content: YAML is a data-serialization language.
      - filename: loops.txt
        content: Ansible loops repeat a task for multiple items.

    packages:
      - git
      - curl
      - tree

    files_to_verify:
      - /tmp/variables-loops-lab/notes/ansible.txt
      - /tmp/variables-loops-lab/notes/yaml.txt
      - /tmp/variables-loops-lab/notes/loops.txt

  tasks:
    - name: Task 1 - Display managed-node information
      debug:
        msg: >-
          {{ inventory_hostname }} runs
          {{ ansible_distribution }}
          {{ ansible_distribution_version }}
          and its IP address is
          {{ ansible_default_ipv4.address }}.

    - name: Task 2 - Create the main lab directory
      file:
        path: "{{ lab_directory }}"
        state: directory
        owner: ansibleadmin
        group: ansibleadmin
        mode: "{{ directory_mode }}"

    - name: Task 3 - Create the lab subdirectories
      file:
        path: "{{ lab_directory }}/{{ directory_name }}"
        state: directory
        owner: ansibleadmin
        group: ansibleadmin
        mode: "{{ directory_mode }}"
      loop: "{{ lab_directories }}"
      loop_control:
        loop_var: directory_name

    - name: Task 4 - Create the study files
      copy:
        content: "{{ item.content }}\n"
        dest: "{{ lab_directory }}/notes/{{ item.filename }}"
        owner: ansibleadmin
        group: ansibleadmin
        mode: "{{ file_mode }}"
      loop: "{{ study_files }}"
      loop_control:
        label: "{{ item.filename }}"

    - name: Task 5 - Install the required packages
      dnf:
        name: "{{ item }}"
        state: present
      loop: "{{ packages }}"
      loop_control:
        label: "{{ item }}"

    - name: Task 6 - Verify the study files
      stat:
        path: "{{ item }}"
      loop: "{{ files_to_verify }}"
      register: study_file_results
      loop_control:
        label: "{{ item }}"
```

The solution contains exactly six tasks.

## 12. Run and verify the lab

### Check syntax

```bash
ansible-playbook playbooks/variables-loops-lab.yml --syntax-check
```

### Perform a dry run

```bash
ansible-playbook playbooks/variables-loops-lab.yml --check
```

Package operations and some system-dependent tasks may not be fully predictable in check mode.

### Test on only `node1`

```bash
ansible-playbook playbooks/variables-loops-lab.yml --limit node1
```

### Run on all three managed nodes

```bash
ansible-playbook playbooks/variables-loops-lab.yml
```

### Verify the directory structure

```bash
ansible three_tier_app -m command \
  -a "find /tmp/variables-loops-lab -maxdepth 2 -ls"
```

### Read the files

```bash
ansible three_tier_app -m command \
  -a "cat /tmp/variables-loops-lab/notes/ansible.txt"
```

```bash
ansible three_tier_app -m command \
  -a "cat /tmp/variables-loops-lab/notes/yaml.txt"
```

```bash
ansible three_tier_app -m command \
  -a "cat /tmp/variables-loops-lab/notes/loops.txt"
```

### Verify installed packages

```bash
ansible three_tier_app -m command \
  -a "rpm -q git curl tree"
```

## 13. Idempotency test

Run the playbook a second time:

```bash
ansible-playbook playbooks/variables-loops-lab.yml
```

The second run should mostly report `ok` and `changed=0` because:

- The required directories already exist with the correct settings.
- The study files already contain the desired content.
- The packages are already installed.
- The `stat` module only reads information.
- The `debug` task does not change a managed node.

## 14. Cleanup

Preview the lab directory before deleting anything:

```bash
ansible three_tier_app -m command \
  -a "ls -la /tmp/variables-loops-lab"
```

Remove only this lab directory:

```bash
ansible three_tier_app -b -m file \
  -a "path=/tmp/variables-loops-lab state=absent"
```

Verify removal:

```bash
ansible three_tier_app -m stat \
  -a "path=/tmp/variables-loops-lab"
```

This cleanup does not remove `git`, `curl`, or `tree`, because other users or labs may require those packages.

## 15. Review questions

1. What is an Ansible variable?
2. What is the purpose of `{{ }}`?
3. What is the difference between a simple variable and a list variable?
4. What does `item` contain during a loop?
5. Why does Task 3 use `loop_var: directory_name`?
6. What is a list of dictionaries?
7. Why does Task 4 use both `item.filename` and `item.content`?
8. What information does `register` save?
9. Why does a registered loop variable contain a `results` list?
10. What should happen during the second playbook run, and why?
