# Ansible Variables — Study Notes

## Index

1. [What is a variable?](#1-what-is-a-variable)
2. [Why variables are used](#2-why-variables-are-used)
3. [Variable naming rules](#3-variable-naming-rules)
4. [Define and reference variables](#4-define-and-reference-variables)
5. [Common variable data types](#5-common-variable-data-types)
6. [Variables with loops](#6-variables-with-loops)
7. [Inventory variables](#7-inventory-variables)
8. [`group_vars` and `host_vars`](#8-group_vars-and-host_vars)
9. [External variable files](#9-external-variable-files)
10. [Registered variables](#10-registered-variables)
11. [Ansible facts](#11-ansible-facts)
12. [Magic variables](#12-magic-variables)
13. [Command-line extra variables](#13-command-line-extra-variables)
14. [Default values and filters](#14-default-values-and-filters)
15. [Variable precedence](#15-variable-precedence)
16. [Sensitive variables](#16-sensitive-variables)
17. [Complete personal-lab example](#17-complete-personal-lab-example)
18. [Commands for checking variables](#18-commands-for-checking-variables)
19. [Common mistakes](#19-common-mistakes)
20. [Practice exercises](#20-practice-exercises)
21. [Quick reference](#21-quick-reference)

---

## 1. What is a variable?

An Ansible variable is a named value used to store reusable information such as a username, package name, file path, IP address, port number, list, or dictionary.

> **One-line definition:** An Ansible variable stores a value that can be referenced and reused during automation.

## 2. Why variables are used

Variables make playbooks:

- Reusable across different systems.
- Easier to update.
- Less repetitive.
- Easier to read and maintain.
- Suitable for different groups, hosts, and environments.

Instead of repeating `/tmp/ansible-lab`, define it once and reference its variable wherever needed.

## 3. Variable naming rules

Good names:

```yaml
web_package: nginx
http_port: 80
lab_directory: /tmp/ansible-lab
```

Recommendations:

- Begin the name with a letter.
- Use letters, numbers, and underscores.
- Use descriptive lowercase names.
- Do not use spaces or hyphens in ordinary variable names.
- Avoid names that conflict with Ansible playbook keywords.

Avoid:

```yaml
web-package: nginx
lab directory: /tmp/lab
```

## 4. Define and reference variables

Define play variables under `vars:`:

```yaml
---
- name: Practice variables
  hosts: three_tier_app
  gather_facts: false

  vars:
    lab_directory: /tmp/ansible-lab
    lab_file: notes.txt
    file_mode: "0644"

  tasks:
    - name: Create the lab directory
      file:
        path: "{{ lab_directory }}"
        state: directory
        mode: "0755"

    - name: Create the study file
      copy:
        content: "Created with Ansible variables.\n"
        dest: "{{ lab_directory }}/{{ lab_file }}"
        mode: "{{ file_mode }}"
```

Variable expressions use Jinja syntax:

```yaml
"{{ variable_name }}"
```

When a YAML value begins with `{{`, quote the whole value.

## 5. Common variable data types

### String

```yaml
web_package: nginx
```

### Number

```yaml
http_port: 80
```

### Boolean

```yaml
enable_service: true
```

Use `true` and `false` for clarity.

### List

```yaml
required_packages:
  - git
  - curl
  - tree
```

### Dictionary

```yaml
student:
  name: Khalid
  course: Ansible
  city: Chicago
```

Reference dictionary members with dot notation:

```yaml
msg: "{{ student.name }} studies {{ student.course }}."
```

Bracket notation is also valid:

```yaml
msg: "{{ student['name'] }}"
```

### List of dictionaries

```yaml
student_accounts:
  - username: student1
    description: Linux Student
  - username: student2
    description: Ansible Student
```

## 6. Variables with loops

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

- `required_packages` contains the list.
- `loop` reads the list.
- `item` represents the current package.

## 7. Inventory variables

Your INI inventory can contain connection variables:

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

| Variable | Purpose |
|---|---|
| `ansible_host` | Address Ansible uses to reach the host |
| `ansible_user` | Remote SSH username |
| `ansible_port` | Remote SSH port, normally `22` |
| `ansible_ssh_private_key_file` | Private key used for SSH |
| `ansible_python_interpreter` | Python executable on the managed node |

## 8. `group_vars` and `host_vars`

Recommended structure:

```text
/home/ansibleadmin/automation/
├── ansible.cfg
├── inventory/
│   ├── nodes
│   ├── group_vars/
│   │   ├── all.yml
│   │   └── web.yml
│   └── host_vars/
│       └── node1.yml
└── playbooks/
```

### Why place them under `inventory/`?

- Your configured inventory source is `/home/ansibleadmin/automation/inventory`.
- Keeping variable directories beside the inventory source makes their relationship clear.
- Ansible's variable plugins can discover group and host files associated with that inventory.

### Variables for every host

`inventory/group_vars/all.yml`:

```yaml
---
ansible_user: ansibleadmin
ansible_python_interpreter: /usr/bin/python3
lab_directory: /tmp/ansible-lab
```

### Variables for the `web` group

`inventory/group_vars/web.yml`:

```yaml
---
web_package: nginx
web_service: nginx
http_port: 80
```

### Variables for only `node1`

`inventory/host_vars/node1.yml`:

```yaml
---
server_role: web
site_title: Node1 Training Website
```

## 9. External variable files

Create `/home/ansibleadmin/automation/vars/lab-vars.yml`:

```yaml
---
lab_directory: /tmp/ansible-study
lab_file: notes.txt
lab_content: Ansible variables make playbooks reusable.
```

Load it with `vars_files`:

```yaml
---
- name: Use an external variable file
  hosts: three_tier_app
  gather_facts: false

  vars_files:
    - ../vars/lab-vars.yml

  tasks:
    - name: Create the lab directory
      file:
        path: "{{ lab_directory }}"
        state: directory
        mode: "0755"

    - name: Create the study file
      copy:
        content: "{{ lab_content }}\n"
        dest: "{{ lab_directory }}/{{ lab_file }}"
        mode: "0644"
```

The directory is created before the file is copied.

## 10. Registered variables

`register` saves the result of a task:

```yaml
- name: Check system uptime
  command: uptime
  register: uptime_result
  changed_when: false

- name: Display uptime
  debug:
    var: uptime_result.stdout
```

Common registered-result properties:

| Property | Meaning |
|---|---|
| `stdout` | Normal command output |
| `stderr` | Error output |
| `rc` | Return code; `0` normally means success |
| `changed` | Whether Ansible reported a change |
| `failed` | Whether the task failed |

`changed_when: false` is suitable here because `uptime` only reads information and does not change the system.

## 11. Ansible facts

Facts are variables automatically discovered from managed nodes when fact gathering is enabled:

```yaml
gather_facts: true
```

Example:

```yaml
- name: Display operating-system information
  debug:
    msg: >-
      {{ inventory_hostname }} runs
      {{ ansible_distribution }}
      {{ ansible_distribution_version }}.
```

Common facts:

| Fact | Meaning |
|---|---|
| `ansible_distribution` | Operating-system name |
| `ansible_distribution_version` | OS version |
| `ansible_hostname` | Managed node hostname |
| `ansible_architecture` | CPU architecture |
| `ansible_memtotal_mb` | Total memory in MB |
| `ansible_processor_vcpus` | Number of virtual CPUs |
| `ansible_default_ipv4.address` | Primary IPv4 address |

Display facts with an ad-hoc command:

```bash
ansible node1 -m setup
```

Filter the output:

```bash
ansible node1 -m setup -a "filter=ansible_distribution*"
```

## 12. Magic variables

Ansible supplies special variables automatically:

| Variable | Meaning |
|---|---|
| `inventory_hostname` | Current host's name as written in inventory |
| `groups` | Dictionary containing inventory groups and members |
| `group_names` | Groups to which the current host belongs |
| `hostvars` | Variables belonging to inventory hosts |
| `playbook_dir` | Directory containing the current playbook |

`inventory_hostname` does not require fact gathering:

```yaml
- name: Display inventory hostname
  debug:
    msg: "Currently running on {{ inventory_hostname }}"
```

## 13. Command-line extra variables

Use `-e` or `--extra-vars`:

```bash
ansible-playbook playbooks/create-file.yml \
  -e "lab_directory=/tmp/student-lab"
```

Pass multiple values:

```bash
ansible-playbook playbooks/create-file.yml \
  -e "lab_directory=/tmp/student-lab lab_file=homework.txt"
```

JSON preserves data types more reliably:

```bash
ansible-playbook playbooks/create-file.yml \
  -e '{"lab_directory":"/tmp/student-lab","cleanup":true}'
```

Extra variables have very high precedence, so they can override values defined in most other locations.

## 14. Default values and filters

Use the `default` filter when a variable might be undefined:

```yaml
- name: Display course name
  debug:
    msg: "Course: {{ course_name | default('Ansible Basics') }}"
```

If `course_name` is missing, the output uses `Ansible Basics`.

Useful filters include:

```yaml
"{{ student_name | upper }}"
"{{ package_list | length }}"
"{{ value | default('fallback') }}"
```

## 15. Variable precedence

The same variable may be defined in several locations. Ansible uses precedence rules to decide which value wins.

A simplified beginner-friendly order from lower to higher precedence is:

1. Role defaults
2. Inventory group variables
3. Inventory host variables
4. Play variables and `vars_files`
5. Task variables
6. Command-line extra variables (`-e`)

The full Ansible precedence system has more levels. For early practice, remember that `-e` normally overrides your other variable definitions.

Avoid defining the same variable in many places unless you intentionally want an override.

## 16. Sensitive variables

Do not store plain-text passwords or secret keys in a public repository. Use Ansible Vault for sensitive values:

```bash
ansible-vault create vars/secrets.yml
```

Run a playbook that uses an encrypted variable file:

```bash
ansible-playbook playbooks/site.yml --ask-vault-pass
```

## 17. Complete personal-lab example

Save as `/home/ansibleadmin/automation/playbooks/variables-practice.yml`:

```yaml
---
- name: Practice variables in the personal Ansible lab
  hosts: three_tier_app
  become: true
  gather_facts: true

  vars:
    lab_directory: /tmp/ansible-variable-lab
    file_mode: "0644"
    study_files:
      - filename: system.txt
        content: >-
          {{ inventory_hostname }} runs
          {{ ansible_distribution }}
          {{ ansible_distribution_version }}.
      - filename: course.txt
        content: Ansible variables and loops practice.

  tasks:
    - name: Create the lab directory
      file:
        path: "{{ lab_directory }}"
        state: directory
        mode: "0755"

    - name: Create study files
      copy:
        content: "{{ item.content }}\n"
        dest: "{{ lab_directory }}/{{ item.filename }}"
        mode: "{{ file_mode }}"
      loop: "{{ study_files }}"
      loop_control:
        label: "{{ item.filename }}"

    - name: Display the lab result
      debug:
        msg: "Files were created in {{ lab_directory }} on {{ inventory_hostname }}."
```

## 18. Commands for checking variables

Check syntax:

```bash
ansible-playbook playbooks/variables-practice.yml --syntax-check
```

Perform a dry run:

```bash
ansible-playbook playbooks/variables-practice.yml --check
```

Run with verbose output:

```bash
ansible-playbook playbooks/variables-practice.yml -v
```

Display variables assigned to one inventory host:

```bash
ansible-inventory --host node1
```

Display the inventory graph:

```bash
ansible-inventory --graph
```

Display a variable with an ad-hoc command:

```bash
ansible node1 -m debug -a "var=inventory_hostname"
```

## 19. Common mistakes

### Not quoting a value that starts with Jinja

Incorrect:

```yaml
path: {{ lab_directory }}
```

Correct:

```yaml
path: "{{ lab_directory }}"
```

### Misspelled variable name

`lab_directory` and `lab_directry` are different variables.

### Using a fact while fact gathering is disabled

If `gather_facts: false`, facts such as `ansible_distribution` may be undefined unless gathered separately.

### Confusing inventory variables with facts

- `inventory_hostname` comes from inventory and does not require facts.
- `ansible_hostname` is normally a gathered fact.

### Putting secrets in normal YAML

Use Ansible Vault for passwords and other confidential data.

## 20. Practice exercises

1. Define variables for a directory name, filename, content, and mode.
2. Move the variables into `vars/lab-vars.yml` and load them with `vars_files`.
3. Add `web_package: nginx` to `group_vars/web.yml`.
4. Add a different `server_role` in each host's `host_vars` file.
5. Register the output of `uptime` and display only `stdout`.
6. Display the OS name and primary IPv4 address using facts.
7. Override a play variable using `-e` and observe the result.

## 21. Quick reference

| Term | Meaning |
|---|---|
| `vars` | Defines variables directly in a play |
| `vars_files` | Loads variables from another YAML file |
| `group_vars` | Variables assigned to an inventory group |
| `host_vars` | Variables assigned to one inventory host |
| `register` | Stores a task result |
| Facts | System information discovered by Ansible |
| Magic variables | Special variables supplied by Ansible |
| `-e` | Passes extra variables from the command line |
| `default` | Provides a fallback for an undefined value |
| Ansible Vault | Encrypts sensitive Ansible data |
