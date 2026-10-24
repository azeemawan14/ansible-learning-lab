# Ansible Variables and Loops Learning Bundle

This bundle provides structured study notes and hands-on practice for two essential Ansible concepts:

- Variables
- Loops

The material is designed for a Rocky Linux 9 Ansible lab with one control node and three managed nodes.

## Table of Contents

1. [Bundle contents](#1-bundle-contents)
2. [Learning objectives](#2-learning-objectives)
3. [Lab environment](#3-lab-environment)
4. [Recommended learning order](#4-recommended-learning-order)
5. [Directory structure](#5-directory-structure)
6. [Document descriptions](#6-document-descriptions)
7. [How to use the lab files](#7-how-to-use-the-lab-files)
8. [Important commands](#8-important-commands)
9. [Expected learning outcomes](#9-expected-learning-outcomes)
10. [Safety and cleanup](#10-safety-and-cleanup)

---

## 1. Bundle contents

| File | Purpose |
|---|---|
| [Ansible_Loops_Study_Notes_English.md](Ansible_Loops_Study_Notes_English.md) | Detailed explanation of Ansible loops |
| [Ansible_Variables_Study_Notes_English.md](Ansible_Variables_Study_Notes_English.md) | Detailed explanation of Ansible variables |
| [lab/Ansible_Variables_and_Loops_6_Task_Lab.md](lab/Ansible_Variables_and_Loops_6_Task_Lab.md) | Six-task student lab with instructions and hints |
| [lab/Ansible_Variables_and_Loops_6_Task_Lab_Solution.md](lab/Ansible_Variables_and_Loops_6_Task_Lab_Solution.md) | Complete solution and verification procedure |

## 2. Learning objectives

After completing this material, you should be able to:

- Explain the purpose of Ansible variables.
- Define variables inside a playbook.
- Recognize strings, numbers, Boolean values, lists, and dictionaries.
- Reference variables with Jinja expressions such as `{{ variable_name }}`.
- Explain the purpose of an Ansible loop.
- Understand how the `item` variable changes during loop iterations.
- Process a simple list with `loop`.
- Process a list of dictionaries with `item.key_name`.
- Rename `item` using `loop_control.loop_var`.
- Improve loop output using `loop_control.label`.
- Save task output with `register`.
- Understand the `results` list produced by a registered loop.
- Check playbook syntax and perform a dry run.
- Test a playbook on one node with `--limit`.
- Confirm idempotency by running a playbook twice.

## 3. Lab environment

| Component | Configuration |
|---|---|
| Control node | `ansible-server.nitclasses.com` |
| Control-node IP | `192.168.1.x` |
| Control-node user | `ansibleadmin` |
| Project directory | `/home/ansibleadmin/automation` |
| Inventory group | `three_tier_app` |
| Web node | `node1` — `192.168.1.154` |
| Application node | `node2` — `192.168.1.185` |
| Database node | `node3` — `192.168.1.190` |
| Managed-node OS | Rocky Linux 9 |

Example inventory structure:

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

## 4. Recommended learning order

### Step 1: Study variables

Start with:

```text
Ansible_Variables_Study_Notes_English.md
```

Focus on:

- Defining variables under `vars:`
- Jinja expressions
- Lists and dictionaries
- Inventory variables
- `group_vars` and `host_vars`
- Registered variables
- Facts and magic variables
- Variable precedence

### Step 2: Study loops

Continue with:

```text
Ansible_Loops_Study_Notes_English.md
```

Focus on:

- Basic loop syntax
- The `item` variable
- Lists of dictionaries
- `loop_control`
- Conditions with loops
- Registered loop results
- Idempotency

### Step 3: Complete the lab independently

Use:

```text
lab/Ansible_Variables_and_Loops_6_Task_Lab.md
```

Read each requirement and hint, but try to write the playbook without opening the solution.

### Step 4: Compare your work with the solution

After completing the lab, use:

```text
lab/Ansible_Variables_and_Loops_6_Task_Lab_Solution.md
```

Compare:

- YAML indentation
- Variable names
- Loop placement
- Module arguments
- `loop_control` usage
- Verification commands

## 5. Directory structure

```text
variables-loop/
├── README.md
├── Ansible_Loops_Study_Notes_English.md
├── Ansible_Variables_Study_Notes_English.md
└── lab/
    ├── Ansible_Variables_and_Loops_6_Task_Lab.md
    └── Ansible_Variables_and_Loops_6_Task_Lab_Solution.md
```

## 6. Document descriptions

### Ansible Loops Study Notes

This guide explains:

- What a loop is
- Why loops are useful
- Basic `loop` syntax
- How `item` works
- Package, directory, file, and user loops
- Lists of dictionaries
- Variables used as loop input
- `loop_control.loop_var`
- `loop_control.label`
- Conditions and registered loop results
- Common mistakes and practice exercises

### Ansible Variables Study Notes

This guide explains:

- What variables are
- Variable naming rules
- Common YAML data types
- Play variables
- Inventory connection variables
- `group_vars` and `host_vars`
- External variable files
- Registered variables
- Ansible facts
- Magic variables
- Extra variables
- Filters and default values
- Simplified variable precedence
- Ansible Vault for sensitive values

### Six-Task Lab

The lab asks students to:

1. Display managed-node information.
2. Create the main lab directory.
3. Create multiple subdirectories with a loop.
4. Create multiple study files from dictionaries.
5. Install multiple packages with a loop.
6. Verify the files with `stat` and `register`.

### Six-Task Lab Solution

The solution includes:

- The complete playbook
- An explanation of every variable
- An explanation of every task
- Execution and verification commands
- An idempotency test
- A safe cleanup procedure

## 7. How to use the lab files

Copy the playbook solution or create your own playbook under:

```text
/home/ansibleadmin/automation/playbooks/
```

Recommended playbook filename:

```text
variables-loops-lab.yml
```

Move into the project:

```bash
cd /home/ansibleadmin/automation
```

Verify connectivity before starting:

```bash
ansible three_tier_app -m ping
```

## 8. Important commands

### Check syntax

```bash
ansible-playbook playbooks/variables-loops-lab.yml --syntax-check
```

### Perform a dry run

```bash
ansible-playbook playbooks/variables-loops-lab.yml --check
```

### Test on one node

```bash
ansible-playbook playbooks/variables-loops-lab.yml --limit node1
```

### Run on all targeted nodes

```bash
ansible-playbook playbooks/variables-loops-lab.yml
```

### Run with additional details

```bash
ansible-playbook playbooks/variables-loops-lab.yml -v
```

### Verify the generated directory structure

```bash
ansible three_tier_app -m command \
  -a "find /tmp/variables-loops-lab -maxdepth 2 -ls"
```

### Read all generated text files

The wildcard requires shell expansion:

```bash
ansible three_tier_app -m shell \
  -a "cat /tmp/variables-loops-lab/notes/*.txt"
```

### Verify packages

```bash
ansible three_tier_app -m command \
  -a "rpm -q git curl tree"
```

## 9. Expected learning outcomes

Students should understand the relationship:

```text
Variable → stores data
Loop     → processes that data repeatedly
item     → current value during each repetition
Module   → performs the required operation
register → saves the result
```

Example:

```yaml
vars:
  packages:
    - git
    - curl
    - tree

tasks:
  - name: Install packages
    dnf:
      name: "{{ item }}"
      state: present
    loop: "{{ packages }}"
```

In this example:

- `packages` is a list variable.
- `loop` processes the list.
- `item` contains one package name at a time.
- `dnf` ensures the current package is installed.

## 10. Safety and cleanup

Always inspect the exact target before deleting it:

```bash
ansible three_tier_app -m command \
  -a "ls -la /tmp/variables-loops-lab"
```

Remove only the lab directory:

```bash
ansible three_tier_app -b -m file \
  -a "path=/tmp/variables-loops-lab state=absent"
```

Verify removal:

```bash
ansible three_tier_app -m stat \
  -a "path=/tmp/variables-loops-lab"
```

The result should include:

```text
"exists": false
```

The cleanup deliberately leaves `git`, `curl`, and `tree` installed because other students or labs may need them.

---

## Suggested classroom workflow

1. Instructor explains variables with short examples.
2. Students complete two variable exercises.
3. Instructor explains simple loops and `item`.
4. Students practice a simple list loop.
5. Instructor explains dictionaries and `item.filename`.
6. Students complete the six-task lab independently.
7. Students check syntax and test only `node1`.
8. Students run the playbook on all three nodes.
9. Students run it a second time and discuss idempotency.
10. Students compare their work with the provided solution.
