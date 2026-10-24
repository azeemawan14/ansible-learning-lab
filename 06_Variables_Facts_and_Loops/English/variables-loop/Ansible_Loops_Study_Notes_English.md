# Ansible Loops — Study Notes

## Index

1. [What is a loop?](#1-what-is-a-loop)
2. [Why loops are used](#2-why-loops-are-used)
3. [Basic syntax](#3-basic-syntax)
4. [Understanding `item`](#4-understanding-item)
5. [Package loop](#5-package-loop)
6. [Directory and file loops](#6-directory-and-file-loops)
7. [Loop over dictionaries](#7-loop-over-dictionaries)
8. [Loop over a variable](#8-loop-over-a-variable)
9. [Rename `item` with `loop_control`](#9-rename-item-with-loop_control)
10. [Use conditions with loops](#10-use-conditions-with-loops)
11. [Register loop results](#11-register-loop-results)
12. [Complete personal-lab example](#12-complete-personal-lab-example)
13. [Verification commands](#13-verification-commands)
14. [Idempotency](#14-idempotency)
15. [Common mistakes](#15-common-mistakes)
16. [Practice exercises](#16-practice-exercises)
17. [Quick reference](#17-quick-reference)

---

## 1. What is a loop?

An Ansible loop repeats one task for every value in a list. It prevents us from writing nearly identical tasks repeatedly.

> **One-line definition:** An Ansible loop repeats a task for each item in a collection.

## 2. Why loops are used

Loops help us:

- Install several packages.
- Create several users, files, or directories.
- Start several services.
- Process structured records containing multiple properties.
- Keep playbooks shorter and easier to maintain.

## 3. Basic syntax

```yaml
- name: Display course names
  debug:
    msg: "Course: {{ item }}"
  loop:
    - Linux
    - Ansible
    - DevOps
```

`loop:` contains the list, and `{{ item }}` represents the current value.

## 4. Understanding `item`

For this loop:

```yaml
loop:
  - git
  - curl
  - tree
```

Ansible executes the task three times:

| Execution | Value of `item` |
|---:|---|
| 1 | `git` |
| 2 | `curl` |
| 3 | `tree` |

`item` is not permanently stored. Ansible changes its value during every loop iteration.

## 5. Package loop

```yaml
- name: Install required packages
  dnf:
    name: "{{ item }}"
    state: present
  loop:
    - git
    - curl
    - tree
```

For package modules, passing the complete list directly is normally more efficient:

```yaml
- name: Install required packages efficiently
  dnf:
    name:
      - git
      - curl
      - tree
    state: present
```

Use a loop when individual items need separate processing, conditions, results, or different properties.

## 6. Directory and file loops

### Create multiple directories

```yaml
- name: Create lab directories
  file:
    path: "/tmp/{{ item }}"
    state: directory
    mode: "0755"
  loop:
    - ansible-lab
    - yaml-lab
    - nginx-lab
```

### Create multiple files

```yaml
- name: Create practice files
  file:
    path: "/tmp/ansible-lab/{{ item }}"
    state: touch
    mode: "0644"
  loop:
    - file1.txt
    - file2.txt
    - file3.txt
```

## 7. Loop over dictionaries

A list item can be a dictionary containing several named values:

```yaml
- name: Create student users
  user:
    name: "{{ item.username }}"
    comment: "{{ item.description }}"
    state: present
  loop:
    - username: student1
      description: Linux Student
    - username: student2
      description: Ansible Student
    - username: student3
      description: DevOps Student
```

During each iteration:

- `item.username` reads the username.
- `item.description` reads the description.

### Create files with different content

```yaml
- name: Create study files
  copy:
    content: "{{ item.content }}\n"
    dest: "/tmp/{{ item.filename }}"
    mode: "0644"
  loop:
    - filename: ansible.txt
      content: Ansible is an automation tool
    - filename: yaml.txt
      content: YAML is a data-serialization language
```

## 8. Loop over a variable

It is better to place reusable data in a variable:

```yaml
vars:
  required_packages:
    - git
    - curl
    - tree

tasks:
  - name: Install required packages
    dnf:
      name: "{{ item }}"
      state: present
    loop: "{{ required_packages }}"
```

Here, `required_packages` is a list variable and the loop processes each member.

## 9. Rename `item` with `loop_control`

A descriptive name makes a complex loop easier to understand:

```yaml
- name: Create lab directories
  file:
    path: "/tmp/{{ directory_name }}"
    state: directory
    mode: "0755"
  loop:
    - ansible-lab
    - yaml-lab
    - nginx-lab
  loop_control:
    loop_var: directory_name
```

Now `directory_name` replaces `item`.

You can also display a useful label:

```yaml
loop_control:
  label: "{{ item.username }}"
```

## 10. Use conditions with loops

```yaml
- name: Display selected packages
  debug:
    msg: "Selected package: {{ item }}"
  loop:
    - git
    - curl
    - tree
  when: item != "curl"
```

This skips `curl` and processes the other items.

## 11. Register loop results

```yaml
- name: Check several files
  stat:
    path: "{{ item }}"
  loop:
    - /etc/hosts
    - /etc/ssh/sshd_config
  register: file_checks

- name: Display all registered results
  debug:
    var: file_checks.results
```

Because the original task uses a loop, its registered data contains a `results` list. Each result includes its corresponding `item`.

## 12. Complete personal-lab example

Save this as `/home/ansibleadmin/automation/playbooks/loop-practice.yml`:

```yaml
---
- name: Practice loops in the personal Ansible lab
  hosts: three_tier_app
  become: true
  gather_facts: false

  vars:
    lab_directory: /tmp/ansible-loop-lab
    study_files:
      - filename: linux.txt
        content: Linux operating-system practice
      - filename: ansible.txt
        content: Ansible automation practice
      - filename: yaml.txt
        content: YAML syntax practice

  tasks:
    - name: Create the lab directory
      file:
        path: "{{ lab_directory }}"
        state: directory
        mode: "0755"

    - name: Create all study files
      copy:
        content: "{{ item.content }}\n"
        dest: "{{ lab_directory }}/{{ item.filename }}"
        mode: "0644"
      loop: "{{ study_files }}"
      loop_control:
        label: "{{ item.filename }}"
```

This targets your `three_tier_app` group containing `node1`, `node2`, and `node3`.

## 13. Verification commands

Check syntax:

```bash
ansible-playbook playbooks/loop-practice.yml --syntax-check
```

Preview supported changes:

```bash
ansible-playbook playbooks/loop-practice.yml --check
```

Run the playbook:

```bash
ansible-playbook playbooks/loop-practice.yml
```

Run with additional detail:

```bash
ansible-playbook playbooks/loop-practice.yml -v
```

Verify the files:

```bash
ansible three_tier_app -m command -a "ls -l /tmp/ansible-loop-lab"
```

## 14. Idempotency

An idempotent task makes a change only when the desired state is missing. If the files already have the correct content and permissions, the second playbook run should normally report `changed=0` for those tasks.

The loop itself does not guarantee idempotency. Idempotency depends on the module and how the task is written. Modules such as `file`, `copy`, `user`, and `dnf` are designed to manage state idempotently.

## 15. Common mistakes

### Missing braces

Incorrect:

```yaml
name: item
```

Correct:

```yaml
name: "{{ item }}"
```

### Incorrect indentation

`loop:` belongs at the task level, aligned with the module name:

```yaml
- name: Correct example
  debug:
    msg: "{{ item }}"
  loop:
    - one
    - two
```

### Referencing a missing dictionary key

If the data contains `username`, use `item.username`, not `item.name`.

### Using a loop unnecessarily

Package modules can usually accept a complete package list in a single task.

## 16. Practice exercises

1. Create `/tmp/student1`, `/tmp/student2`, and `/tmp/student3` with one loop.
2. Create three users using a list variable.
3. Create two files with different names, content, and modes using dictionaries.
4. Register the results of checking `/etc/hosts` and `/etc/passwd`.
5. Run your playbook twice and compare `changed` values.

## 17. Quick reference

| Term | Meaning |
|---|---|
| `loop` | Collection Ansible processes |
| `item` | Current value during an iteration |
| `loop_control` | Changes loop display or behavior |
| `loop_var` | Replaces the name `item` |
| `label` | Controls the item label shown in output |
| `register` | Saves task results in a variable |
| `results` | List of results produced by a registered loop |

