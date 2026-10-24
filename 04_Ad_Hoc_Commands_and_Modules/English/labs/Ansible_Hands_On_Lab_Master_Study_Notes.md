# Ansible Hands-On Lab — Master Study Notes

## Lab Environment

- **Control node:** `ansible-server`
- **User:** `ansibleadmin`
- **Inventory:** `/home/ansibleadmin/automation/inventory/nodes`
- **node1:** `192.168.1.154` → `node1.nitclasses.com`
- **node2:** `192.168.1.185` → `node2.nitclasses.com`
- **node3:** `192.168.1.190` → `node3.nitclasses.com`
- Parent group: `three_tier_app` contains `web`, `app`, and `db`.

## 1. Ad-Hoc Command Structure

```bash
ansible TARGET -m MODULE -a "ARGUMENTS" -i INVENTORY
```

- `TARGET` = host/group
- `-m` = module
- `-a` = module arguments
- `-i` = inventory

## 2. Ping Module

```bash
ansible web -m ping -i ./automation/inventory/nodes
```

Ansible `ping` is not ICMP ping. It verifies that Ansible can connect and execute its module successfully.

Custom data:

```bash
ansible web -m ping -a "data=hello" -i ./automation/inventory/nodes
```

Intentional failure:

```bash
ansible web -m ping -a "data=crash" -i ./automation/inventory/nodes
```

Use `-vvv` for detailed troubleshooting.

## 3. ansible-doc

```bash
ansible-doc ping
ansible-doc dnf
ansible-doc service
ansible-doc -l
ansible-doc -s dnf
ansible-doc -l | grep firewalld
```

Think of `ansible-doc MODULE` like `man COMMAND` in Linux.

## 4. Inventory Example

```ini
[control]
ansible-server ansible_connection=local

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

## 5. Inventory Patterns

```bash
ansible web:app --list-hosts -i ./automation/inventory/nodes
```

Output uses inventory aliases such as `node1` and `node2`, not necessarily their IP addresses.

## 6. inventory_hostname vs ansible_host

For:

```ini
node1 ansible_host=192.168.1.154
```

Ansible sees:

```text
inventory_hostname = node1
ansible_host        = 192.168.1.154
```

Display both:

```bash
ansible web:app -i ./automation/inventory/nodes -m debug -a 'msg="{{ inventory_hostname }} -> {{ ansible_host }}"'
```

Lab result:

```text
node1 -> 192.168.1.154
node2 -> 192.168.1.185
```

The inner quotes around the `msg` value are important because the message contains spaces.

## 7. Inventory Inspection

```bash
ansible-inventory --graph -i ./automation/inventory/nodes
ansible-inventory --list -i ./automation/inventory/nodes
ansible-inventory --host node1 -i ./automation/inventory/nodes
```

## 8. Hostname and FQDN Lab

```bash
ansible three_tier_app -m command -a "hostname" -i ./automation/inventory/nodes
```

Your nodes returned their full configured names:

```text
node1.nitclasses.com
node2.nitclasses.com
node3.nitclasses.com
```

FQDN:

```bash
ansible three_tier_app -m command -a "hostname -f" -i ./automation/inventory/nodes
```

Here `-f` belongs to the Linux `hostname` command, not Ansible.

Useful comparison:

```bash
hostname
hostname -s
hostname -f
hostnamectl
```

- `hostname` = current configured hostname
- `hostname -s` = short hostname
- `hostname -f` = FQDN

## 9. command Module

```bash
ansible three_tier_app -m command -a "hostname -f" -i ./automation/inventory/nodes
```

Breakdown:

```text
three_tier_app             → target
command    → module
hostname -f                → command being executed
-i .../nodes               → inventory
```

`rc=0` normally means the Linux command completed successfully.

The `command` module can report `CHANGED` even for a read-only command such as `hostname -f`; this does not mean the hostname was modified.

## 10. Create a Directory

Your lab command:

```bash
ansible three_tier_app -m file -a "path=/tmp/ansible-lab state=directory" -i ./automation/inventory/nodes
```

First run:

```text
CHANGED
"changed": true
```

Reason: `/tmp/ansible-lab` did not exist, so Ansible created it.

## 11. Idempotency

You ran the exact same command again:

```bash
ansible three_tier_app -m file -a "path=/tmp/ansible-lab state=directory" -i ./automation/inventory/nodes
```

Second run:

```text
SUCCESS
"changed": false
```

Flow:

```text
First run  → directory missing        → create it → CHANGED
Second run → directory already exists → no action → changed=false
```

**Idempotency:** once the managed system already matches the desired state, rerunning an idempotent task does not make unnecessary changes.

Interview answer:

> Ansible modules are generally designed to be idempotent. If the system already matches the desired state, Ansible does not make an unnecessary change and reports `changed: false`.

## 12. Directory Output

Your results included:

```text
owner = ansibleadmin
group = ansibleadmin
mode  = 0755
state = directory
```

`0755`:

```text
Owner  → rwx
Group  → r-x
Others → r-x
```

Your `ansibleadmin` numeric UID differed between nodes:

```text
node1 → 3005
node2 → 1000
node3 → 1001
```

That is possible because separate Linux systems can assign different numeric UIDs to the same username.

You also saw:

```text
secontext = unconfined_u:object_r:user_tmp_t:s0
```

`secontext` means SELinux security context.

## 13. Remove the Directory

You ran:

```bash
ansible three_tier_app -m file -a "path=/tmp/ansible-lab state=absent" -i ./automation/inventory/nodes
```

Result:

```text
CHANGED
"changed": true
"state": "absent"
```

Because the directory existed, Ansible removed it.

## 14. file Module States

```text
state=directory → directory should exist
state=touch     → touch/create a file
state=absent    → resource should not exist
```

Roman Urdu memory aid:

```text
directory → directory honi chahiye
touch     → file ko touch/create karo
absent    → file/directory nahi honi chahiye
```

Note: `state=touch` can update timestamps on an existing file, so it is not the best demonstration of `changed=false` idempotency.

## 15. Create an Empty File

```bash
ansible three_tier_app -m file -a "path=/tmp/ansible-test.txt state=touch" -i ./automation/inventory/nodes
```

Verify:

```bash
ansible three_tier_app -m command -a "ls -l /tmp/ansible-test.txt" -i ./automation/inventory/nodes
```

## 16. Create a File with Content

```bash
ansible three_tier_app -m copy -a 'content="Hello from Ansible
" dest=/tmp/ansible-test.txt' -i ./automation/inventory/nodes
```

Verify:

```bash
ansible three_tier_app -m command -a "cat /tmp/ansible-test.txt" -i ./automation/inventory/nodes
```

Run the same `copy` command again. If the file already has exactly that content, it should normally report `changed: false`.

## 17. Directory with Permissions

```bash
ansible three_tier_app -m file -a "path=/tmp/devops state=directory mode=0755" -i ./automation/inventory/nodes
```

Verify:

```bash
ansible three_tier_app -m command -a "ls -ld /tmp/devops" -i ./automation/inventory/nodes
```

## 18. Delete a File

```bash
ansible three_tier_app -m file -a "path=/tmp/ansible-test.txt state=absent" -i ./automation/inventory/nodes
```

If it exists: `changed=true`.  
Run it again after deletion: normally `changed=false`.

## 19. Output Status

```text
GREEN  → SUCCESS / OK
YELLOW → CHANGED
BLUE   → SKIPPED
RED    → FAILED
```

Exact colors can vary, so trust the actual status text.

- `SUCCESS`, `changed=false` → successful; no modification needed
- `CHANGED`, `changed=true` → successful; managed node changed
- `FAILED` → task/module failed
- `UNREACHABLE` → Ansible could not establish the required connection

For failures, inspect fields such as `msg`, `rc`, `stdout`, and `stderr`.

## 20. Complete Practice Exercise

Create:

```bash
ansible three_tier_app -m file -a "path=/tmp/ansible-practice state=directory mode=0755" -i ./automation/inventory/nodes
```

Run it again and observe idempotency.

Verify:

```bash
ansible three_tier_app -m command -a "ls -ld /tmp/ansible-practice" -i ./automation/inventory/nodes
```

Add content:

```bash
ansible three_tier_app -m copy -a 'content="Ansible practice lab
" dest=/tmp/ansible-practice/readme.txt' -i ./automation/inventory/nodes
```

Read it:

```bash
ansible three_tier_app -m command -a "cat /tmp/ansible-practice/readme.txt" -i ./automation/inventory/nodes
```

Clean up:

```bash
ansible three_tier_app -m file -a "path=/tmp/ansible-practice state=absent" -i ./automation/inventory/nodes
```

## 21. Modules Practiced

| Module | Purpose |
|---|---|
| `ping` | Test Ansible connectivity/module execution |
| `command` | Execute commands |
| `debug` | Display variables/messages |
| `file` | Manage files/directories/permissions |
| `copy` | Copy files or manage file content |

## 22. Command-Line Options

| Option | Meaning |
|---|---|
| `-m` | module |
| `-a` | module arguments |
| `-i` | inventory |
| `-vvv` | verbose troubleshooting |
| `--list-hosts` | show hosts matching the target |

## 23. Mental Model

```text
Inventory
   ↓
Target/group
   ↓
Module
   ↓
Arguments / desired state
   ↓
Compare actual state
   ↓
Already correct?
   ├── YES → SUCCESS / changed=false
   └── NO  → make change → CHANGED
```

For every command ask:

1. **WHO?** Which host/group am I targeting?
2. **WHAT?** Which module am I using?
3. **HOW?** Which arguments am I passing?
4. **WHAT CHANGED?** `changed=true` or `false`?
5. **HOW DO I VERIFY?**
6. **IS IT IDEMPOTENT?** What happens on the second run?

## 24. Interview Quick Review

**What is inventory?**  
A definition of managed hosts and groups Ansible can target.

**What is `-m`?**  
The module to use.

**What is `-a`?**  
Arguments supplied to that module.

**What is `-i`?**  
The inventory source.

**What is `ansible_host`?**  
The actual address Ansible uses to connect.

**What is `inventory_hostname`?**  
The host's inventory name/alias.

**What is idempotency?**  
Repeatedly applying the same desired state does not cause unnecessary changes once the system already matches it.

**`CHANGED` vs `SUCCESS`?**  
`CHANGED` means the operation succeeded and made a change. `SUCCESS` with `changed:false` means it succeeded without needing a change.

**What is `state=absent`?**  
The resource should not exist.

**What is `rc=0`?**  
The executed command normally completed successfully.

## Next Hands-On Labs

Continue this master file as you learn:

1. ownership and permissions
2. copying local files to managed nodes
3. users and groups
4. `dnf` package management
5. service management
6. Ansible facts / `setup`
7. `become` and sudo
8. first Ansible playbook

---
**Last updated:** September 10, 2026
