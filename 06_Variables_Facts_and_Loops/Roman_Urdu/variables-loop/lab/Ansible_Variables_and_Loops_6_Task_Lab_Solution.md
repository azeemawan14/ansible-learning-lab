# Ansible Variables and Loops — Six-Task Lab Solution

## Index

1. [Solution overview](#1-solution-overview)
2. [Complete six-task playbook](#2-complete-six-task-playbook)
3. [Solution explanation](#3-solution-explanation)
4. [Run the solution](#4-run-the-solution)
5. [Verify the results](#5-verify-the-results)
6. [Test idempotency](#6-test-idempotency)
7. [Cleanup](#7-cleanup)

---

## 1. Solution overview

This solution practices these two main Ansible concepts:

- Variables
- Loops

The playbook targets the `three_tier_app` inventory group containing:

| Host | IP address |
|---|---|
| `node1` | `192.168.1.154` |
| `node2` | `192.168.1.185` |
| `node3` | `192.168.1.190` |

Save the playbook as:

```text
/home/ansibleadmin/automation/playbooks/variables-loops-lab.yml
```

## 2. Complete six-task playbook

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
    # Task 1
    - name: Display managed-node information
      debug:
        msg: >-
          {{ inventory_hostname }} runs
          {{ ansible_distribution }}
          {{ ansible_distribution_version }}
          and its IP address is
          {{ ansible_default_ipv4.address }}.

    # Task 2
    - name: Create the main lab directory
      file:
        path: "{{ lab_directory }}"
        state: directory
        owner: ansibleadmin
        group: ansibleadmin
        mode: "{{ directory_mode }}"

    # Task 3
    - name: Create the lab subdirectories
      file:
        path: "{{ lab_directory }}/{{ directory_name }}"
        state: directory
        owner: ansibleadmin
        group: ansibleadmin
        mode: "{{ directory_mode }}"
      loop: "{{ lab_directories }}"
      loop_control:
        loop_var: directory_name
        label: "{{ directory_name }}"

    # Task 4
    - name: Create the study files
      copy:
        content: "{{ item.content }}\n"
        dest: "{{ lab_directory }}/notes/{{ item.filename }}"
        owner: ansibleadmin
        group: ansibleadmin
        mode: "{{ file_mode }}"
      loop: "{{ study_files }}"
      loop_control:
        label: "{{ item.filename }}"

    # Task 5
    - name: Install the required packages
      dnf:
        name: "{{ item }}"
        state: present
      loop: "{{ packages }}"
      loop_control:
        label: "{{ item }}"

    # Task 6
    - name: Verify the study files
      stat:
        path: "{{ item }}"
      loop: "{{ files_to_verify }}"
      register: study_file_results
      loop_control:
        label: "{{ item }}"
```

This playbook contains exactly six tasks.

## 3. Solution explanation

### Play-level settings

| Setting | Explanation |
|---|---|
| `hosts: three_tier_app` | Runs the play on `node1`, `node2`, and `node3` |
| `become: true` | Uses privilege escalation where root access is required |
| `gather_facts: true` | Collects OS, version, network, and other system facts |
| `vars:` | Begins the play-level variable definitions |

### Variables

| Variable | Type | Purpose |
|---|---|---|
| `lab_directory` | String | Stores the main lab directory |
| `directory_mode` | String | Stores directory permissions |
| `file_mode` | String | Stores file permissions |
| `lab_directories` | List | Stores the names of three subdirectories |
| `study_files` | List of dictionaries | Stores filenames and corresponding content |
| `packages` | List | Stores package names |
| `files_to_verify` | List | Stores the complete paths checked by `stat` |

### Task 1: Display host information

The `debug` module displays the inventory hostname and gathered facts:

- `inventory_hostname`: host name from the inventory
- `ansible_distribution`: operating-system name
- `ansible_distribution_version`: operating-system version
- `ansible_default_ipv4.address`: primary IPv4 address

The `>-` YAML operator joins the written lines into one output line and removes the final newline.

### Task 2: Create the main directory

The `file` module ensures that the directory stored in `lab_directory` exists with the required ownership and permissions.

```yaml
path: "{{ lab_directory }}"
mode: "{{ directory_mode }}"
```

### Task 3: Create subdirectories

The task repeats once for every member of `lab_directories`.

```yaml
loop: "{{ lab_directories }}"
```

`loop_control.loop_var` renames the default `item` variable:

```yaml
loop_control:
  loop_var: directory_name
```

During the iterations, `directory_name` becomes:

1. `notes`
2. `reports`
3. `backups`

### Task 4: Create study files

Every loop item is a dictionary containing:

- `filename`
- `content`

The task reads those values with:

```yaml
item.filename
item.content
```

`loop_control.label` makes the output easier to read by displaying only the current filename.

### Task 5: Install packages

The `dnf` task processes `git`, `curl`, and `tree`. The desired state is `present`, meaning each package must be installed.

Passing the complete list directly to `dnf` would normally be more efficient, but this exercise intentionally uses a loop.

### Task 6: Verify files

The `stat` module reads information about every file in `files_to_verify`. It does not modify the files.

```yaml
register: study_file_results
```

Because the task uses a loop, the registered variable contains:

```text
study_file_results.results
```

This is a list containing a separate result for every checked file.

## 4. Run the solution

Move to the project directory:

```bash
cd /home/ansibleadmin/automation
```

### Check syntax

```bash
ansible-playbook playbooks/variables-loops-lab.yml --syntax-check
```

### Perform a dry run

```bash
ansible-playbook playbooks/variables-loops-lab.yml --check
```

Some package operations and system-dependent tasks may not be fully predictable in check mode.

### Test on `node1` first

```bash
ansible-playbook playbooks/variables-loops-lab.yml --limit node1
```

### Run on all three managed nodes

```bash
ansible-playbook playbooks/variables-loops-lab.yml
```

### Run with additional details

```bash
ansible-playbook playbooks/variables-loops-lab.yml -v
```

## 5. Verify the results

### Check the directory structure

```bash
ansible three_tier_app -m command \
  -a "find /tmp/variables-loops-lab -maxdepth 2 -ls"
```

### Read all study files

The wildcard requires shell processing, so use the `shell` module:

```bash
ansible three_tier_app -m shell \
  -a "cat /tmp/variables-loops-lab/notes/*.txt"
```

### Read files individually with `command`

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

Expected package verification should show installed package versions rather than “package is not installed.”

## 6. Test idempotency

Run the playbook a second time:

```bash
ansible-playbook playbooks/variables-loops-lab.yml
```

The second run should mostly report `ok` and:

```text
changed=0
```

This happens because:

- The directories already exist with the correct settings.
- The files already contain the desired content.
- The packages are already installed.
- `debug` only displays information.
- `stat` only reads information.

This demonstrates idempotency: Ansible does not repeat a change when the system already matches the desired state.

## 7. Cleanup

### Preview the directory

Always check the exact target before deleting it:

```bash
ansible three_tier_app -m command \
  -a "ls -la /tmp/variables-loops-lab"
```

### Remove the lab directory

```bash
ansible three_tier_app -b -m file \
  -a "path=/tmp/variables-loops-lab state=absent"
```

### Verify removal

```bash
ansible three_tier_app -m stat \
  -a "path=/tmp/variables-loops-lab"
```

Look for:

```text
"exists": false
```

The cleanup intentionally does not remove `git`, `curl`, or `tree` because those packages may be required by another student or lab.
