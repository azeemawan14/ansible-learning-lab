# Ansible Introduction and Ad-Hoc Commands — Homework

## Lab environment

This homework is adapted for the existing Rocky Linux Ansible practice environment.

| Role | Host | IP address | Operating system/user |
|---|---|---|---|
| Control node | `ansible-server` | `192.168.1.233` | Rocky Linux 9 / `ansibleadmin` |
| Web node | `node1` | `192.168.1.154` | Rocky Linux 9 / `ansibleadmin` |
| Application node | `node2` | `192.168.1.185` | Rocky Linux 9 / `ansibleadmin` |
| Database node | `node3` | `192.168.1.190` | Rocky Linux 9 / `ansibleadmin` |

Ansible, passwordless SSH, the inventory and `ansible.cfg` have already been configured. Students must verify the environment rather than reinstalling or rebuilding it.

## Learning objectives

After completing this homework, the learner should be able to:

- Explain configuration management and Ansible architecture
- Distinguish the control node, managed nodes, inventory, modules and playbooks
- Verify the active Ansible configuration and inventory
- Run ad-hoc commands against hosts and groups
- Use inventory patterns
- Distinguish modules from module arguments
- Explain privilege escalation and idempotency
- Gather basic operating-system facts
- Make and verify safe temporary changes
- Remove all resources created during the exercise

## Important safety rules

1. Run all Ansible commands as `ansibleadmin`, not as `root`.
2. Begin from the project directory:

   ```bash
   cd ~/automation
   ```

3. Read the complete command before pressing Enter.
4. Check the output after every command.
5. Do not modify SSH, firewall, network or SELinux configuration in this homework.
6. Do not use `shell` when the `command` module is sufficient.
7. Use `-b` only for tasks requiring root privileges.
8. Do not place passwords or private keys in screenshots or submitted files.
9. Complete the cleanup task at the end.

---

## Task 1 — Understand Ansible

Write short answers in your own words. Do not copy definitions directly from a book or website.

1. What is configuration management?
2. Why is configuration management needed when an environment contains many servers?
3. What is Ansible?
4. What does **agentless** mean?
5. How does Ansible normally connect to Linux managed nodes?
6. What is the difference between push-based and pull-based automation?
7. Give two differences between Ansible and agent-based tools such as Puppet or Chef.
8. What does idempotency mean?
9. Why are playbooks better than repeated manual commands?

### Describe the architecture

Describe the following components and explain how they work together:

| Component | Question to answer |
|---|---|
| Control node | Where is Ansible installed and executed? |
| Managed nodes | Which machines receive and execute the requested automation? |
| Inventory | How does Ansible know which hosts and groups exist? |
| Modules | What kind of work does a module perform? |
| Module arguments | How do arguments tell a module what to manage? |
| Ad-hoc command | When is a one-line Ansible command useful? |
| Playbook | How does a YAML playbook provide repeatable automation? |

### Architecture to describe

```text
Administrator
     |
     v
Ansible control node
     |
     | SSH + modules
     v
Inventory groups: web, app, db
     |
     v
node1, node2, node3
```

**Evidence required:** Your written answers and architecture description.

---

## Task 2 — Verify the control node

Do not reinstall Ansible. Verify the existing installation:

```bash
whoami
hostname -f
ansible --version
python3 --version
```

Record the following values:

| Item | Your result |
|---|---|
| Current user | |
| Control-node hostname | |
| Ansible core version | |
| Active configuration file | |
| Ansible executable path | |
| Control-node Python version | |

Answer:

1. Why is Ansible installed on the control node?
2. Why does Ansible normally not need to be installed on Linux managed nodes?
3. Why is Python required on the managed nodes for most Ansible modules?

**Evidence required:** Command output or a screenshot with sensitive information removed.

---

## Task 3 — Verify the existing configuration

Move to the project directory:

```bash
cd ~/automation
pwd
```

Check which configuration file is active:

```bash
ansible --version
```

Display non-default configuration values:

```bash
ansible-config dump --only-changed
```

Display the project configuration:

```bash
cat ansible.cfg
```

Answer:

1. Which `ansible.cfg` file is active?
2. What does `inventory` specify?
3. What does `remote_user` specify?
4. Why is `ask_pass = False` appropriate after SSH keys are configured?
5. What does `host_key_checking = True` protect against?
6. What do `become_method`, `become_user` and `become_ask_pass` control?

> Keep `host_key_checking = True`. The SSH host keys have already been established, and disabling verification is unnecessary for this lab.

**Evidence required:** Relevant `ansible --version` and `ansible-config dump --only-changed` output.

---

## Task 4 — Verify the existing inventory

Display the inventory file:

```bash
cat inventory/nodes
```

Display the inventory hierarchy:

```bash
ansible-inventory --graph
```

Display the processed variables for each managed node:

```bash
ansible-inventory --host node1
ansible-inventory --host node2
ansible-inventory --host node3
```

List hosts belonging to important groups:

```bash
ansible web --list-hosts
ansible app --list-hosts
ansible db --list-hosts
ansible three_tier_app --list-hosts
```

Complete this table:

| Inventory host | `ansible_host` | Group | SSH user | Python interpreter |
|---|---|---|---|---|
| `node1` | | | | |
| `node2` | | | | |
| `node3` | | | | |

Answer:

1. What is the difference between `inventory_hostname` and `ansible_host`?
2. What does `[three_tier_app:children]` mean?
3. What does `[all:vars]` mean?
4. Why can the inventory use friendly names such as `node1` instead of only IP addresses?

**Evidence required:** Inventory graph and the completed table.

---

## Task 5 — Test SSH and Ansible connectivity

Test passwordless SSH without allowing a password prompt:

```bash
ssh -o BatchMode=yes node1 hostname
ssh -o BatchMode=yes node2 hostname
ssh -o BatchMode=yes node3 hostname
```

Test all managed nodes with Ansible:

```bash
ansible three_tier_app -m ping
```

Run the same test with additional detail:

```bash
ansible three_tier_app -m ping -v
```

Answer:

1. What does `SUCCESS` mean?
2. Why does the Ansible `ping` module return `pong`?
3. Is the Ansible `ping` module the same as the operating-system ICMP `ping` command?
4. What does `changed: false` mean?

**Evidence required:** Output showing successful results from all three nodes.

---

## Task 6 — Run read-only ad-hoc commands

These commands inspect the managed nodes without intentionally changing them.

### Check uptime

```bash
ansible three_tier_app -m command -a "uptime"
```

### Check memory

```bash
ansible web -m command -a "free -h"
```

### Check disk usage

```bash
ansible three_tier_app -m command -a "df -h"
```

### Check the kernel

```bash
ansible three_tier_app -m command -a "uname -r"
```

### Check the current remote user

```bash
ansible three_tier_app -m command -a "whoami"
```

### Check hostnames

```bash
ansible three_tier_app -m command -a "hostname -f"
```

Answer:

1. Which group was targeted by each command?
2. What is the module in these commands?
3. What follows `-a`?
4. Why did the commands report `CHANGED` even though they were read-only?
5. Which setting can be used in a playbook to correct that reporting behavior?

**Evidence required:** Results of at least five read-only ad-hoc commands.

---

## Task 7 — Explore facts and variables

Display Rocky Linux distribution facts:

```bash
ansible three_tier_app -m setup -a "filter=ansible_distribution*"
```

Display Python facts:

```bash
ansible three_tier_app -m setup -a "filter=ansible_python*"
```

Display memory facts:

```bash
ansible three_tier_app -m setup -a "filter=ansible_memtotal_mb"
```

Display important inventory variables:

```bash
ansible three_tier_app -m debug -a "var=inventory_hostname"
ansible three_tier_app -m debug -a "var=ansible_host"
ansible three_tier_app -m debug -a "var=group_names"
```

Display a combined message:

```bash
ansible three_tier_app -m debug \
  -a 'msg="{{ inventory_hostname }} connects to {{ ansible_host }}"'
```

Complete this table:

| Host | Distribution | Version | Architecture | Python version |
|---|---|---|---|---|
| `node1` | | | | |
| `node2` | | | | |
| `node3` | | | | |

Answer:

1. What is the difference between an inventory variable and a gathered fact?
2. Which module gathers system facts?
3. Why might `discovered_interpreter_python` not appear when `ansible_python_interpreter` is already defined?

**Evidence required:** Completed facts table and selected output.

---

## Task 8 — Practice inventory groups and patterns

Test the existing groups:

```bash
ansible web -m ping
ansible app -m ping
ansible db -m ping
ansible three_tier_app -m ping
```

Test union and exclusion patterns:

```bash
ansible 'web:app' -m ping
ansible 'three_tier_app:!db' -m ping
```

Before running each command, predict which hosts will be selected. Then compare the prediction with:

```bash
ansible 'web:app' --list-hosts
ansible 'three_tier_app:!db' --list-hosts
```

Complete this table:

| Pattern | Predicted hosts | Actual hosts |
|---|---|---|
| `web` | | |
| `web:app` | | |
| `three_tier_app` | | |
| `three_tier_app:!db` | | |

### Optional inventory challenge

Add these child groups only if they do not already exist:

```ini
[application:children]
web
app

[all_servers:children]
application
db
```

Validate before using them:

```bash
ansible-inventory --graph
ansible application --list-hosts
ansible all_servers --list-hosts
```

**Evidence required:** Completed pattern table and inventory graph if the optional groups were added.

---

## Task 9 — Create and copy temporary content

Create a temporary directory on every managed node:

```bash
ansible three_tier_app -m file \
  -a "path=/tmp/ansible-homework state=directory mode=0755"
```

Create a local file on the control node:

```bash
printf 'Hello from %s\n' "$USER" > hello.txt
```

Copy it to all managed nodes:

```bash
ansible three_tier_app -m copy \
  -a "src=hello.txt dest=/tmp/ansible-homework/hello.txt mode=0644"
```

Verify the remote contents:

```bash
ansible three_tier_app -m command \
  -a "cat /tmp/ansible-homework/hello.txt"
```

Check file information:

```bash
ansible three_tier_app -m stat \
  -a "path=/tmp/ansible-homework/hello.txt"
```

Answer:

1. On which machine was `hello.txt` initially created?
2. What direction did the `copy` module transfer the file?
3. What does `mode=0644` mean?
4. Why was `-b` not required for a directory under `/tmp` owned by the SSH user?

**Evidence required:** Copy results and verification output.

---

## Task 10 — Practice package management and `--become`

Check whether the `tree` package is installed:

```bash
ansible web -m command -a "rpm -q tree"
```

The command may return a non-zero result if the package is missing. That is expected before installation.

Install `tree` on the `web` group:

```bash
ansible web -m dnf -a "name=tree state=present" -b
```

Verify it:

```bash
ansible web -m command -a "rpm -q tree"
```

Answer:

1. What does `-b` or `--become` do?
2. Why is privilege escalation required for package installation?
3. Why is the `dnf` module preferable to running `dnf install` through `shell`?
4. What does `state=present` mean?

**Evidence required:** Installation and verification output.

---

## Task 11 — Demonstrate idempotency

Run the same package task a second time:

```bash
ansible web -m dnf -a "name=tree state=present" -b
```

Run the same copy task a second time:

```bash
ansible three_tier_app -m copy \
  -a "src=hello.txt dest=/tmp/ansible-homework/hello.txt mode=0644"
```

Compare the first and second results.

Complete this table:

| Operation | First run | Second run | Explanation |
|---|---|---|---|
| Install `tree` | | | |
| Copy `hello.txt` | | | |

Answer:

1. What does `changed` mean?
2. What does `ok` or `changed: false` mean?
3. Did Ansible skip the task, or did it check the desired state again?
4. Explain idempotency in your own words.

**Evidence required:** First and second execution results.

---

## Task 12 — Compare `command` and `shell`

Run a simple command with `command`:

```bash
ansible three_tier_app -m command -a "uptime"
```

Run a pipeline with `shell`:

```bash
ansible three_tier_app -m shell \
  -a "ps -ef | systemctl is-active sshd"
```

Complete the comparison:

| Feature | `command` | `shell` |
|---|---|---|
| Runs through a shell | | |
| Supports pipes such as `|` | | |
| Supports redirection such as `>` | | |
| Safer default for ordinary commands | | |

Answer:

1. Why does the pipeline require `shell`?
2. Why should `command` be preferred when shell features are unnecessary?
3. What security risk can occur when untrusted input is passed to `shell`?

**Evidence required:** Results and completed table.

---

## Task 13 — Troubleshooting challenge

Without changing the production inventory, explain how you would investigate each situation:

1. `UNREACHABLE!` with `Permission denied (publickey)`
2. `UNREACHABLE!` with `Connection timed out`
3. Python interpreter not found
4. `Missing sudo password`
5. A host pattern matches no hosts
6. SSH host-key verification fails after a VM is rebuilt

Useful diagnostic commands:

```bash
ansible TARGET --list-hosts
ansible-inventory --graph
ansible-inventory --host node1
ssh -v node1
ansible node1 -m ping -vvv
ansible-config dump --only-changed
```

**Evidence required:** Written troubleshooting sequence for at least four scenarios.

---

## Task 14 — Cleanup

Remove the temporary package from the `web` group:

```bash
ansible web -m dnf -a "name=tree state=absent" -b
```

Remove the temporary directory and everything inside it:

```bash
ansible three_tier_app -m file \
  -a "path=/tmp/ansible-homework state=absent"
```

Remove the local practice file from the control node:

```bash
rm hello.txt
```

Verify cleanup:

```bash
ansible web -m command -a "rpm -q tree"
ansible three_tier_app -m stat \
  -a "path=/tmp/ansible-homework"
```

Expected results:

- `rpm -q tree` reports that the package is not installed.
- The `stat` result shows `exists: false`.

**Evidence required:** Cleanup commands and verification results.

---

## Task 15 — Final reflection

Answer in your own words:

1. What was the most important concept learned?
2. Which command was most useful and why?
3. What is the difference between a module and an argument?
4. What is the difference between inventory and `ansible.cfg`?
5. When should an ad-hoc command be replaced by a playbook?
6. Why must every change be verified?
7. What problem did you encounter and how did you troubleshoot it?

---


