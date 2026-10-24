# SSH Login Banner — Manual and Ansible Three-Node Lab

This study guide explains how to configure an SSH pre-login banner manually and automate it across `node1`, `node2`, and `node3` with Ansible.

## Index

1. [Learning objectives](#1-learning-objectives)
2. [Lab environment](#2-lab-environment)
3. [What is an SSH banner?](#3-what-is-an-ssh-banner)
4. [SSH Banner vs MOTD](#4-ssh-banner-vs-motd)
5. [Important corrections and safety rules](#5-important-corrections-and-safety-rules)
6. [Part 1 — Manual demonstration on node1](#6-part-1--manual-demonstration-on-node1)
7. [Part 2 — Automate all three nodes with Ansible](#7-part-2--automate-all-three-nodes-with-ansible)
8. [Playbook explanation](#8-playbook-explanation)
9. [Validate the result with Ansible](#9-validate-the-result-with-ansible)
10. [Test from the control node](#10-test-from-the-control-node)
11. [Demonstrate idempotency](#11-demonstrate-idempotency)
12. [Rollback procedure](#12-rollback-procedure)
13. [Troubleshooting](#13-troubleshooting)
14. [Suggested classroom demonstration order](#14-suggested-classroom-demonstration-order)
15. [Quick command reference](#15-quick-command-reference)

---

## 1. Learning objectives

After completing this lab, you should be able to:

- Explain the purpose of an SSH pre-login banner.
- Explain the difference between an SSH banner and `/etc/motd`.
- Configure an SSH banner manually.
- Safely validate `/etc/ssh/sshd_config`.
- Reload the SSH service without unnecessarily terminating sessions.
- Automate the configuration on three managed nodes with Ansible.
- Use a handler to reload `sshd` only when its configuration changes.
- Verify the configuration and demonstrate Ansible idempotency.
- Roll back the change if necessary.

---

## 2. Lab environment

| Role | Host | IP address |
|---|---|---|
| Control node | `ansible-server` | `192.168.1.233` |
| Managed node | `node1` | `192.168.1.154` |
| Managed node | `node2` | `192.168.1.185` |
| Managed node | `node3` | `192.168.1.190` |

SSH user:

```text
ansibleadmin
```

SSH private key:

```text
/home/ansibleadmin/.ssh/ansible-key
```

Example Ansible project directory:

```text
/home/ansibleadmin/automation
```

The examples use the inventory hosts `node1`, `node2`, and `node3`. The Ansible pattern below combines them:

```text
node1:node2:node3
```

In an Ansible host pattern, the colon acts as an OR operation.

---

## 3. What is an SSH banner?

An SSH banner is text sent to an SSH client **before user authentication**. It is commonly used to display:

- An authorized-use warning.
- A monitoring notice.
- A legal or organizational notice.
- A lab identification message.

The SSH server configuration directive is:

```text
Banner /etc/ssh/banner.txt
```

The `Banner` directive tells `sshd` which file it should display before authentication.

For a personal lab, a friendly welcome message is acceptable. Production systems should normally use approved security or legal language rather than exposing unnecessary system details.

---

## 4. SSH Banner vs MOTD

| Feature | SSH banner | MOTD |
|---|---|---|
| Common file | Custom file such as `/etc/ssh/banner.txt` | `/etc/motd` |
| Display time | Before authentication | After successful login |
| SSH setting | `Banner` in `/etc/ssh/sshd_config` | Controlled by PAM/login configuration |
| Common purpose | Warning or legal notice | News, maintenance information, or welcome message |
| User authenticated yet? | No | Yes |

This lab configures an SSH **pre-login banner**, not an MOTD.

---

## 5. Important corrections and safety rules

### Use the absolute directory path

Correct:

```bash
cd /etc/ssh
```

Incorrect:

```bash
cd etc/ssh
```

Without the leading `/`, the second command looks for `etc/ssh` inside the current directory.

### Spell the directive correctly

Correct:

```text
Banner /etc/ssh/banner.txt
```

### Back up the configuration

Before a manual change:

```bash
sudo cp -p /etc/ssh/sshd_config \
/etc/ssh/sshd_config.bak.$(date +%F_%H%M%S)
```

### Validate before reloading

```bash
sudo /usr/sbin/sshd -t
```

- No output normally means the syntax is valid.
- An error message means the configuration must be corrected.
- Do not reload or restart `sshd` when validation fails.

### Keep the current SSH session open

Keep the working session open and test the new configuration from a second terminal. This reduces the risk of losing access if something is wrong.

### Prefer reload for a configuration change

```bash
sudo systemctl reload sshd
```

A reload applies the configuration without a full service restart. A restart can also work, but a reload is less disruptive for this change.

---

## 6. Part 1 — Manual demonstration on node1

### Step 1: Connect to node1

From the control node:

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node1
```

### Step 2: Change to the SSH configuration directory

```bash
cd /etc/ssh
```

### Step 3: Back up sshd_config

```bash
sudo cp -p /etc/ssh/sshd_config \
/etc/ssh/sshd_config.bak.$(date +%F_%H%M%S)
```

Check the backup:

```bash
ls -l /etc/ssh/sshd_config*
```

### Step 4: Create the banner file

```bash
sudo vim /etc/ssh/banner.txt
```

Add:

```text
**************************************************
WARNING: Authorized access only

Welcome to node1 — NIT Classes Ansible Lab
All activities may be monitored.
**************************************************
```

Save and exit:

```vim
:wq
```

Set the ownership and permissions:

```bash
sudo chown root:root /etc/ssh/banner.txt
sudo chmod 0644 /etc/ssh/banner.txt
```

### Step 5: Configure sshd

```bash
sudo vim /etc/ssh/sshd_config
```

Search for a banner directive:

```vim
/Banner
```

Set it to:

```text
Banner /etc/ssh/banner.txt
```

Save and exit:

```vim
:wq
```

> If the file contains `#Banner none`, replace it with the active line shown above. Do not leave conflicting active `Banner` directives in different configuration files.

### Step 6: Validate sshd_config

```bash
sudo /usr/sbin/sshd -t
```

Continue only if the command returns no errors.

### Step 7: Reload SSH

```bash
sudo systemctl reload sshd
```

### Step 8: Verify the service and effective value

```bash
sudo systemctl is-active sshd
sudo /usr/sbin/sshd -T | grep -i '^banner'
```

Expected output:

```text
active
banner /etc/ssh/banner.txt
```

### Step 9: Test from another terminal

Keep the original session open. From another terminal, run:

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node1
```

The banner should appear before authentication completes.

---

## 7. Part 2 — Automate all three nodes with Ansible

After demonstrating the manual process, automate it on `node1`, `node2`, and `node3`.

### Step 1: Verify connectivity

```bash
cd /home/ansibleadmin/automation
ansible 'node1:node2:node3' -m ping
```

Every node should return `SUCCESS` and `pong`.

### Step 2: Create the playbook

```bash
vim ssh-banner.yml
```

Add:

```yaml
---
- name: Configure SSH login banner on three nodes
  hosts: "node1:node2:node3"
  become: true

  tasks:
    - name: Create a customized SSH banner
      copy:
        dest: /etc/ssh/banner.txt
        owner: root
        group: root
        mode: "0644"
        content: |
          **************************************************
          WARNING: Authorized access only

          Welcome to {{ inventory_hostname }} — NIT Classes Ansible Lab
          All activities may be monitored.
          **************************************************

    - name: Configure the SSH Banner directive
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^\s*#?\s*Banner\s+'
        line: 'Banner /etc/ssh/banner.txt'
        backup: true
        validate: '/usr/sbin/sshd -t -f %s'
      notify: Reload sshd

  handlers:
    - name: Reload sshd
      service:
        name: sshd
        state: reloaded
```

### Step 3: Check YAML and playbook syntax

```bash
ansible-playbook --syntax-check ssh-banner.yml
```

Expected result:

```text
playbook: ssh-banner.yml
```

### Step 4: Preview the changes

```bash
ansible-playbook --check --diff ssh-banner.yml
```

Check mode predicts changes without normally applying them. Some modules and commands may not fully simulate every action, so it is a useful preview rather than a replacement for testing.

### Step 5: Run the playbook

```bash
ansible-playbook ssh-banner.yml
```

Review the play recap and confirm that all three nodes have `failed=0` and `unreachable=0`.

---

## 8. Playbook explanation

### Play name

```yaml
- name: Configure SSH login banner on three nodes
```

This provides a readable description of the play.

### Host pattern

```yaml
hosts: "node1:node2:node3"
```

This targets any host matching `node1`, `node2`, or `node3`.

If the inventory already has a group containing exactly those three nodes, its group name can be used instead.

### Privilege escalation

```yaml
become: true
```

Root privileges are required to modify files under `/etc/ssh` and reload `sshd`.

### `copy` module

The `copy` task:

- Creates `/etc/ssh/banner.txt`.
- Sets ownership to `root:root`.
- Sets permissions to `0644`.
- Creates host-specific content with `inventory_hostname`.

```yaml
Welcome to {{ inventory_hostname }} — NIT Classes Ansible Lab
```

The variable resolves separately on each node.

### `lineinfile` module

The task searches for an active or commented `Banner` line and replaces it with:

```text
Banner /etc/ssh/banner.txt
```

Important parameters:

| Parameter | Purpose |
|---|---|
| `path` | File being managed |
| `regexp` | Finds an existing active or commented Banner line |
| `line` | Required final configuration line |
| `backup` | Saves a timestamped backup before changing the file |
| `validate` | Tests the temporary configuration before replacing the real file |

If validation fails, Ansible does not install the invalid temporary file.

### Handler

```yaml
notify: Reload sshd
```

The handler runs only if the `lineinfile` task reports a change. If the configuration already contains the correct line, the handler is not triggered.

---

## 9. Validate the result with Ansible

### Display every banner file

```bash
ansible 'node1:node2:node3' -b -m command \
-a "cat /etc/ssh/banner.txt"
```

### Validate sshd_config on every node

```bash
ansible 'node1:node2:node3' -b -m command \
-a "/usr/sbin/sshd -t"
```

A successful command normally produces no configuration error.

### Display the effective Banner setting

The `command` module does not interpret pipes, so use `shell` for this pipeline:

```bash
ansible 'node1:node2:node3' -b -m shell \
-a "/usr/sbin/sshd -T | grep -i '^banner'"
```

Expected output on each node:

```text
banner /etc/ssh/banner.txt
```

### Check service status

```bash
ansible 'node1:node2:node3' -b -m command \
-a "systemctl is-active sshd"
```

Expected output:

```text
active
```

---

## 10. Test from the control node

Test each managed node:

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node1
ssh -i ~/.ssh/ansible-key ansibleadmin@node2
ssh -i ~/.ssh/ansible-key ansibleadmin@node3
```

Expected customized messages:

- `Welcome to node1 — NIT Classes Ansible Lab`
- `Welcome to node2 — NIT Classes Ansible Lab`
- `Welcome to node3 — NIT Classes Ansible Lab`

Exit each session with:

```bash
exit
```

---

## 11. Demonstrate idempotency

Run the same playbook again:

```bash
ansible-playbook ssh-banner.yml
```

If nothing was changed manually after the first run, the second run should normally show:

```text
changed=0
failed=0
```

This demonstrates idempotency: Ansible recognizes that the requested state already exists and does not repeat unnecessary changes.

The `copy` task remains unchanged because the content, ownership, and permissions are already correct. The `lineinfile` task remains unchanged because the required Banner directive already exists.

---

## 12. Rollback procedure

Create a rollback playbook:

```bash
vim remove-ssh-banner.yml
```

Add:

```yaml
---
- name: Remove the SSH login banner configuration
  hosts: "node1:node2:node3"
  become: true

  tasks:
    - name: Disable the SSH Banner directive
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^\s*#?\s*Banner\s+'
        line: 'Banner none'
        backup: true
        validate: '/usr/sbin/sshd -t -f %s'
      notify: Reload sshd

    - name: Remove the custom banner file
      file:
        path: /etc/ssh/banner.txt
        state: absent

  handlers:
    - name: Reload sshd
      service:
        name: sshd
        state: reloaded
```

Check and run it:

```bash
ansible-playbook --syntax-check remove-ssh-banner.yml
ansible-playbook --check --diff remove-ssh-banner.yml
ansible-playbook remove-ssh-banner.yml
```

Verify:

```bash
ansible 'node1:node2:node3' -b -m shell \
-a "/usr/sbin/sshd -T | grep -i '^banner'"
```

Expected effective value:

```text
banner none
```

---

## 13. Troubleshooting

### Permission denied while modifying files

Ensure privilege escalation is enabled:

```yaml
become: true
```

Test passwordless sudo:

```bash
ansible 'node1:node2:node3' -m command -a "sudo -n whoami"
```

Expected result:

```text
root
```

### The SSH banner does not appear

Check the effective setting:

```bash
sudo /usr/sbin/sshd -T | grep -i '^banner'
```

Check the file:

```bash
sudo ls -l /etc/ssh/banner.txt
sudo cat /etc/ssh/banner.txt
```

Check whether the service is active:

```bash
sudo systemctl status sshd --no-pager
```

### Validation fails

Run:

```bash
sudo /usr/sbin/sshd -t
```

Read the reported filename and line number, correct the configuration, and validate again. Do not reload `sshd` until validation succeeds.

### Ansible reports an unreachable host

Test:

```bash
ansible 'node1:node2:node3' -m ping
```

Then verify direct SSH access:

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node1
```

Check:

- Host IP address or name resolution.
- Network connectivity.
- SSH service status.
- SSH private-key path and permissions.
- Whether the public key exists in the remote user's `authorized_keys`.

### The playbook changes every time

Run with diff mode:

```bash
ansible-playbook --diff ssh-banner.yml
```

Inspect what changes repeatedly. Common causes include:

- Another process modifying the file.
- Different whitespace or content.
- Multiple conflicting Banner directives.
- A configuration-management tool enforcing another state.

---

## 14. Suggested classroom demonstration order

1. Explain what an SSH pre-login banner is.
2. Compare it with `/etc/motd`.
3. Connect to `node1` and configure the banner manually.
4. Back up and validate `sshd_config`.
5. Reload `sshd` and test from a second terminal.
6. Explain why repeating the same manual steps on many servers is inefficient.
7. Show the Ansible playbook.
8. Run `--syntax-check`.
9. Run `--check --diff`.
10. Apply the playbook to all three nodes.
11. Verify the banner, effective SSH configuration, and service state.
12. Run the playbook again to demonstrate `changed=0`.
13. Demonstrate the rollback playbook if time permits.

This order shows the value of automation clearly: first perform the task manually, then replace repeated work with a safe and reusable playbook.

---

## 15. Quick command reference

### Manual node1 configuration

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node1
cd /etc/ssh
sudo cp -p /etc/ssh/sshd_config \
/etc/ssh/sshd_config.bak.$(date +%F_%H%M%S)
sudo vim /etc/ssh/banner.txt
sudo chown root:root /etc/ssh/banner.txt
sudo chmod 0644 /etc/ssh/banner.txt
sudo vim /etc/ssh/sshd_config
sudo /usr/sbin/sshd -t
sudo systemctl reload sshd
sudo systemctl is-active sshd
sudo /usr/sbin/sshd -T | grep -i '^banner'
```

### Ansible deployment and validation

```bash
cd /home/ansibleadmin/automation
ansible 'node1:node2:node3' -m ping
ansible-playbook --syntax-check ssh-banner.yml
ansible-playbook --check --diff ssh-banner.yml
ansible-playbook ssh-banner.yml
ansible-playbook ssh-banner.yml

ansible 'node1:node2:node3' -b -m command \
-a "cat /etc/ssh/banner.txt"

ansible 'node1:node2:node3' -b -m command \
-a "/usr/sbin/sshd -t"

ansible 'node1:node2:node3' -b -m shell \
-a "/usr/sbin/sshd -T | grep -i '^banner'"

ansible 'node1:node2:node3' -b -m command \
-a "systemctl is-active sshd"
```

## Final recommendation

For the demonstration, configure `node1` manually and then use Ansible for all three nodes. Always create a backup, validate with `sshd -t`, keep the current SSH session open, and prefer `reload` over `restart` for this configuration-only change.
