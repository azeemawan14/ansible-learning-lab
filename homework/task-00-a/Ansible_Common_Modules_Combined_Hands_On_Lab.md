# Ansible Common Modules — Combined Hands-On Lab

## Lab Goal

This lab combines the most commonly used Ansible modules into one progressive exercise for the Rocky Linux practice environment. It uses ad-hoc commands, verifies every important operation, demonstrates idempotency, and removes the resources created during the lab.

## Index

1. [Environment](#1-environment)
2. [Modules covered](#2-modules-covered)
3. [Safety rules](#3-safety-rules)
4. [Phase 1 — Pre-checks](#4-phase-1--pre-checks)
5. [Phase 2 — Command, shell, and raw](#5-phase-2--command-shell-and-raw)
6. [Phase 3 — File, copy, stat, and fetch](#6-phase-3--file-copy-stat-and-fetch)
7. [Phase 4 — Lineinfile and replace](#7-phase-4--lineinfile-and-replace)
8. [Phase 5 — Get URL](#8-phase-5--get-url)
9. [Phase 6 — Package management](#9-phase-6--package-management)
10. [Phase 7 — User and group management](#10-phase-7--user-and-group-management)
11. [Phase 8 — Mount module](#11-phase-8--mount-module)
12. [Phase 9 — Setup and facts](#12-phase-9--setup-and-facts)
13. [Phase 10 — Complete cleanup](#13-phase-10--complete-cleanup)
14. [Final verification](#14-final-verification)
15. [Module summary](#15-module-summary)
16. [Practice questions](#16-practice-questions)

---

## 1. Environment

| Role | Host | Address | Inventory group |
|---|---|---|---|
| Control node | `ansible-server` | `192.168.1.233` | `control`, if configured |
| Web node | `node1` | `192.168.1.154` | `web` |
| Application node | `node2` | `192.168.1.185` | `app` |
| Database node | `node3` | `192.168.1.190` | `db` |

The parent group `three_tier_app` should contain `web`, `app`, and `db`.

Begin as `ansibleadmin`:

```bash
cd ~/automation
whoami
pwd
```

Expected user:

```text
ansibleadmin
```

---

## 2. Modules Covered

| Module | Purpose |
|---|---|
| `ping` | Test Ansible connectivity |
| `command` | Run a command without a shell |
| `raw` | Send a command directly through SSH |
| `shell` | Run a command through a shell |
| `file` | Manage files, directories, links, and permissions |
| `copy` | Copy content from the control node to managed nodes |
| `fetch` | Bring files from managed nodes to the control node |
| `get_url` | Download a URL directly on a managed node |
| `lineinfile` | Manage one line in a text file |
| `replace` | Replace text using a regular expression |
| `group` | Manage Linux groups |
| `user` | Manage Linux users |
| `dnf` | Manage packages on modern Rocky/RHEL systems |
| `yum` | Manage packages through the yum-compatible interface |
| `package` | Manage packages using an OS-independent interface |
| `stat` | Gather information about a path |
| `mount` | Manage mounts and `/etc/fstab` entries |
| `setup` | Gather system facts |
| `debug` | Display variables and messages |

Short module names are used throughout this lab.

---

## 3. Safety Rules

1. Run the commands only against the assigned lab nodes.
2. Read the target group before pressing Enter.
3. Use `-b` only where root privileges are required.
4. Do not change SSH, firewall, SELinux, network, or hostname settings.
5. The lab uses unique names: `ansible-lab`, `ansiblelab`, and `ansible_lab`.
6. Check whether the `tree` package existed before the lab. Remove it afterward only if this lab installed it.
7. Complete the cleanup phase.

---

## 4. Phase 1 — Pre-Checks

### Step 1: Verify configuration and inventory

```bash
ansible --version
ansible-config dump --only-changed
ansible-inventory --graph
ansible three_tier_app --list-hosts
```

Expected managed hosts:

```text
node1
node2
node3
```

### Step 2: Test connectivity with `ping`

```bash
ansible three_tier_app -m ping
```

Each node should return:

```text
"changed": false,
"ping": "pong"
```

Do not continue until all three nodes return `SUCCESS`.

### Step 3: Confirm the remote account

```bash
ansible three_tier_app -m command -a "whoami"
```

Expected:

```text
ansibleadmin
```

---

## 5. Phase 2 — Command, Shell, and Raw

### Step 1: Use `command`

```bash
ansible three_tier_app -m command -a "uptime"
ansible three_tier_app -m command -a "uname -r"
```

`command` is preferred when pipes, redirection, variable expansion, and other shell features are unnecessary.

### Step 2: Use `shell`

```bash
ansible three_tier_app -m shell \
  -a "ps -ef | systemctl is-active sshd"
```

The pipe is a shell operator, so this operation requires `shell`.

### Step 3: Use `raw`

```bash
ansible three_tier_app -m raw -a "id"
```

`raw` sends the command directly through the connection and does not require Python on the managed node. It is commonly used to bootstrap Python, but normal modules should be preferred after Python is available.

### Compare

| Feature | `command` | `shell` | `raw` |
|---|---|---|---|
| Executes a Linux command | Yes | Yes | Yes |
| Uses the normal Ansible module subsystem | Yes | Yes | No |
| Requires remote Python | Normally yes | Normally yes | No |
| Processes `;`,`>`, and `&&` | No | Yes | Usually yes |
| Best use | Ordinary commands | Commands requiring shell features | Python bootstrap or emergency access |
| Safety | Safest default | Use carefully | Use only when necessary |

### Why `command` cannot run a command list

Do not use:

```bash
ansible three_tier_app -m command -a "uptime; lsblk"
```

The `command` module does not ask a shell to interpret the semicolon. It may pass `;` and `lsblk` as arguments to `uptime`, causing an error instead of running two commands.

When multiple commands or shell operators are genuinely required, use `shell`:

```bash
ansible three_tier_app -m shell \
  -a "uptime; lsblk"
```

The same command string can be sent with `raw`:

```bash
ansible three_tier_app -m raw \
  -a "uptime; lsblk"
```

The words `uptime` and `lsblk` are **Linux commands**, not Ansible modules.

### Use `raw` when Python is unavailable

Check whether Python 3 exists without depending on Python:

```bash
ansible node1 -m raw \
  -a "command -v python3 || echo 'Python is missing'"
```

If Python is missing on an approved Rocky Linux managed node, bootstrap it:

```bash
ansible node1 -m raw \
  -a "dnf install -y python3" -b
```

After Python becomes available, return to regular Ansible modules because they provide structured results and better idempotency.

> Do not use the outdated statement that `command` requires “Python 2.4 or later.” Modern Ansible requires a Python version supported by the installed `ansible-core` release. This lab explicitly uses `/usr/bin/python3`.

---

## 6. Phase 3 — File, Copy, Stat, and Fetch

### Step 1: Create the remote directory with `file`

```bash
ansible three_tier_app -m file \
  -a "path=/tmp/ansible-lab state=directory mode=0755"
```

Run the command a second time. The second run should report `changed=false`.

### Step 2: Create a source file on the control node

```bash
printf 'environment=practice\nowner=ansibleadmin\n' > module-lab.conf
cat module-lab.conf
```

### Step 3: Copy it to every node

```bash
ansible three_tier_app -m copy \
  -a "src=module-lab.conf dest=/tmp/ansible-lab/module-lab.conf mode=0644"
```

Run the copy command a second time to observe idempotency.

### Step 4: Inspect it with `stat`

```bash
ansible three_tier_app -m stat \
  -a "path=/tmp/ansible-lab/module-lab.conf"
```

Look for:

- `exists: true`
- `isreg: true`
- Mode `0644`
- File owner
- Checksum

### Step 5: Display its remote content

```bash
ansible three_tier_app -m command \
  -a "cat /tmp/ansible-lab/module-lab.conf"
```

### Step 6: Fetch a copy from every node

```bash
ansible three_tier_app -m fetch \
  -a "src=/tmp/ansible-lab/module-lab.conf dest=./lab-output/"
```

`fetch` normally creates a separate host directory beneath `lab-output`, preventing files from different hosts from overwriting one another.

Inspect locally:

```bash
find ./lab-output -type f -name module-lab.conf -print
```

Direction:

```text
copy:  control node  → managed node
fetch: managed node  → control node
```

---

## 7. Phase 4 — Lineinfile and Replace

### Step 1: Add a managed line

```bash
ansible three_tier_app -m lineinfile \
  -a "path=/tmp/ansible-lab/module-lab.conf line='managed_by=ansible' state=present"
```

Run it again. The second run should report `changed=false` because the line already exists.

### Step 2: Replace text

```bash
ansible three_tier_app -m replace \
  -a "path=/tmp/ansible-lab/module-lab.conf regexp='environment=practice' replace='environment=training'"
```

Run it again. The second run should report `changed=false` because the original matching text no longer exists.

### Step 3: Verify

```bash
ansible three_tier_app -m command \
  -a "cat /tmp/ansible-lab/module-lab.conf"
```

Expected content:

```text
environment=training
owner=ansibleadmin
managed_by=ansible
```

---

## 8. Phase 5 — Get URL

`get_url` downloads a file directly from a URL to the managed node.

This step requires outbound internet access from `node1`.

### Step 1: Download a public test page

```bash
ansible web -m get_url \
  -a "url=https://www.example.com/ dest=/tmp/ansible-lab/example.html mode=0644"
```

### Step 2: Verify

```bash
ansible web -m stat \
  -a "path=/tmp/ansible-lab/example.html"
```

Run the `get_url` command again. If the remote content has not changed, Ansible should avoid downloading a different copy.

> If the node has no internet access, record the failure and skip this phase. Do not disable TLS validation to force the download.

---

## 9. Phase 6 — Package Management

This phase uses `tree` to compare `dnf`, `yum`, and `package`.

### Step 1: Record the original state

```bash
ansible web -m command -a "rpm -q tree"
```

Record whether `tree` was already installed.

### Step 2: Install using `dnf`

```bash
ansible web -m dnf \
  -a "name=tree state=present" -b
```

### Step 3: Verify

```bash
ansible web -m command -a "rpm -q tree"
```

### Step 4: Check the same state through `yum`

```bash
ansible web -m yum \
  -a "name=tree state=present" -b
```

Because `tree` is already installed, this should normally report no change.

### Step 5: Check the same state through `package`

```bash
ansible web -m package \
  -a "name=tree state=present" -b
```

### Module selection

| Module | Recommended use |
|---|---|
| `dnf` | Modern Rocky Linux and RHEL systems |
| `yum` | Yum-compatible RHEL-family environments |
| `package` | Generic playbooks across supported operating systems |

For this Rocky Linux 9 lab, `dnf` is the clearest choice.

---

## 10. Phase 7 — User and Group Management

This phase creates one temporary group and user on `node2`.

### Step 1: Create the group

```bash
ansible app -m group \
  -a "name=ansible_lab state=present" -b
```

### Step 2: Create the user

```bash
ansible app -m user \
  -a "name=ansiblelab group=ansible_lab comment='Temporary Ansible Lab User' create_home=yes state=present" -b
```

No password is assigned, so this account should not be used for password login.

### Step 3: Verify

```bash
ansible app -m command -a "id ansiblelab"
ansible app -m command -a "getent group ansible_lab"
```

### Step 4: Demonstrate idempotency

Run the `group` and `user` creation commands again. Both should normally report `changed=false`.

---

## 11. Phase 8 — Mount Module

This phase creates a small temporary `tmpfs` mount on `node3`. It does not format or modify a disk.

### Step 1: Create a mount point

```bash
ansible db -m file \
  -a "path=/mnt/ansible-lab state=directory mode=0755" -b
```

### Step 2: Mount a temporary filesystem

```bash
ansible db -m mount \
  -a "path=/mnt/ansible-lab src=tmpfs fstype=tmpfs opts=size=64m state=mounted" -b
```

`state=mounted` mounts the filesystem and manages an `/etc/fstab` entry.

### Step 3: Verify

```bash
ansible db -m command \
  -a "findmnt /mnt/ansible-lab"
```

Expected filesystem type:

```text
tmpfs
```

### Step 4: Check idempotency

Run the mount command again. It should normally report `changed=false`.

> Do not replace `tmpfs` with a real disk device unless you fully understand storage administration and have an approved unused device.

---

## 12. Phase 9 — Setup and Facts

### Gather distribution facts

```bash
ansible three_tier_app -m setup \
  -a "filter=ansible_distribution*"
```

### Gather hostname facts

```bash
ansible three_tier_app -m setup \
  -a "filter=ansible_hostname"
```

### Gather memory facts

```bash
ansible three_tier_app -m setup \
  -a "filter=ansible_memtotal_mb"
```

### Gather default IPv4 facts

```bash
ansible three_tier_app -m setup \
  -a "filter=ansible_default_ipv4"
```

### Display selected variables with `debug`

```bash
ansible three_tier_app -m debug \
  -a 'msg="{{ inventory_hostname }} connects to {{ ansible_host }}"'
```

Difference:

| Item | Source |
|---|---|
| `inventory_hostname` | Name defined in inventory |
| `ansible_host` | Connection address defined in inventory |
| `ansible_distribution` | Fact gathered from the managed node |
| `ansible_default_ipv4.address` | Fact gathered from the managed node |

---

## 13. Phase 10 — Complete Cleanup

Run cleanup in the specified order.

### Step 1: Remove the temporary user

```bash
ansible app -m user \
  -a "name=ansiblelab state=absent remove=yes" -b
```

### Step 2: Remove the temporary group

```bash
ansible app -m group \
  -a "name=ansible_lab state=absent" -b
```

### Step 3: Remove the temporary mount

```bash
ansible db -m mount \
  -a "path=/mnt/ansible-lab state=absent" -b
```

`state=absent` unmounts the filesystem and removes its matching `/etc/fstab` entry.

### Step 4: Remove the mount-point directory

```bash
ansible db -m file \
  -a "path=/mnt/ansible-lab state=absent" -b
```

### Step 5: Remove the remote lab directory

```bash
ansible three_tier_app -m file \
  -a "path=/tmp/ansible-lab state=absent"
```

### Step 6: Remove local lab files

Confirm your current directory first:

```bash
pwd
ls -ld ./lab-output ./module-lab.conf
```

Then remove only these lab-created paths:

```bash
rm -r ./lab-output
rm ./module-lab.conf
```

### Step 7: Handle the `tree` package

If `tree` was **not installed before this lab**, remove it:

```bash
ansible web -m dnf \
  -a "name=tree state=absent" -b
```

If `tree` existed before the lab, leave it installed.

---

## 14. Final Verification

### Confirm that temporary remote paths are absent

```bash
ansible three_tier_app -m stat \
  -a "path=/tmp/ansible-lab"
```

Expected:

```text
"exists": false
```

### Confirm that the temporary user and group are absent

```bash
ansible app -m shell \
  -a "getent passwd ansiblelab || true; getent group ansible_lab || true"
```

No matching account or group should be displayed.

### Confirm that the mount is absent

```bash
ansible db -m shell \
  -a "findmnt /mnt/ansible-lab || true"
```

No mounted filesystem should be displayed.

### Final connectivity test

```bash
ansible three_tier_app -m ping
```

All nodes should still return `SUCCESS`.

---

## 15. Module Summary

| Module | Change expected on first run? | Typical second run |
|---|---:|---|
| `ping` | No | `changed=false` |
| `command` | Depends on the command; often reported as changed in older versions | Depends |
| `raw` | Depends on the command | Depends |
| `shell` | Depends on the command | Depends |
| `file` | Yes when creating/removing a path | `changed=false` after state matches |
| `copy` | Yes when content or metadata differs | `changed=false` |
| `fetch` | Copies remote content locally | Depends on local destination state |
| `get_url` | Yes when download is required | Usually no change when current |
| `lineinfile` | Yes when the line is missing | `changed=false` |
| `replace` | Yes when the expression matches | `changed=false` after replacement |
| `group` | Yes when creating/removing the group | `changed=false` |
| `user` | Yes when creating/removing the user | `changed=false` |
| `dnf`, `yum`, `package` | Yes when package state differs | `changed=false` |
| `stat` | No | `changed=false` |
| `mount` | Yes when mount state differs | `changed=false` |
| `setup` | No | `changed=false` |
| `debug` | No | `changed=false` |

---

## 16. Practice Questions

1. What is the difference between `copy` and `fetch`?
2. Why is `command` preferred over `shell` for ordinary commands?
3. When is `raw` useful?
4. What is the difference between `lineinfile` and `replace`?
5. Why was `-b` required for package, user, group, and mount operations?
6. What is the difference between `dnf` and `package`?
7. What does `state=present` mean?
8. What does `state=absent` mean?
9. Which module gathers system facts?
10. What did the second execution of each idempotent task report?
11. Why must the original package state be recorded before cleanup?
12. Why is a playbook preferable when this entire lab needs to be repeated?

## Completion Checklist

- [ ] All three nodes returned `pong`
- [ ] Read-only commands were tested
- [ ] Remote files and directories were created
- [ ] File content was edited and verified
- [ ] A file was fetched to the control node
- [ ] Package modules were compared
- [ ] Temporary user and group were created
- [ ] Temporary mount was created
- [ ] Facts and variables were displayed
- [ ] Idempotency was observed
- [ ] All temporary resources were removed
- [ ] Final connectivity test succeeded
