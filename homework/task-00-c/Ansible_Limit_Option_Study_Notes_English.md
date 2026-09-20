# Ansible `--limit` Option — Study Notes

The `--limit` option restricts the target hosts of an Ansible command or playbook to a selected host, group, or host pattern.

## Index

1. [What is `--limit`?](#1-what-is---limit)
2. [Basic syntax](#2-basic-syntax)
3. [Lab inventory](#3-lab-inventory)
4. [Limit execution to one host](#4-limit-execution-to-one-host)
5. [Limit a playbook](#5-limit-a-playbook)
6. [Select multiple hosts](#6-select-multiple-hosts)
7. [Limit execution to a group](#7-limit-execution-to-a-group)
8. [Exclude hosts or groups](#8-exclude-hosts-or-groups)
9. [Use an intersection](#9-use-an-intersection)
10. [Use wildcard patterns](#10-use-wildcard-patterns)
11. [Preview selected hosts](#11-preview-selected-hosts)
12. [Relationship with inventory and original target](#12-relationship-with-inventory-and-original-target)
13. [Safe rollout strategy](#13-safe-rollout-strategy)
14. [SSH banner example](#14-ssh-banner-example)
15. [Common mistakes](#15-common-mistakes)
16. [Quick-reference table](#16-quick-reference-table)
17. [Practice exercises](#17-practice-exercises)
18. [Review questions](#18-review-questions)

---

## 1. What is `--limit`?

`--limit` tells Ansible:

> From the original target, run the automation only on the specified host, group, or matching pattern.

Example:

```bash
ansible three_tier_app --limit node1 -m ping
```

| Part | Meaning |
|---|---|
| `three_tier_app` | Original target group |
| `--limit node1` | Restrict the target to `node1` |
| `-m ping` | Test Ansible connectivity |

If `three_tier_app` contains `node1`, `node2`, and `node3`, this command runs only on `node1`.

## 2. Basic syntax

Ad-hoc command:

```bash
ansible ORIGINAL_TARGET --limit LIMIT_PATTERN -m MODULE
```

Playbook:

```bash
ansible-playbook PLAYBOOK.yml --limit LIMIT_PATTERN
```

The short form is `-l`:

```bash
ansible all -l node1 -m ping
```

These commands are equivalent:

```bash
ansible all --limit node1 -m ping
ansible all -l node1 -m ping
```

The long form is generally easier to read in study notes and demonstrations.

## 3. Lab inventory

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
```

| Pattern | Selected hosts |
|---|---|
| `web` | `node1` |
| `app` | `node2` |
| `db` | `node3` |
| `three_tier_app` | `node1`, `node2`, `node3` |

## 4. Limit execution to one host

```bash
ansible three_tier_app --limit node1 -m ping
```

Only `node1` is targeted. `node2` and `node3` are not contacted.

Test package installation on one host:

```bash
ansible three_tier_app -b --limit node1 -m dnf -a \
"name=tree state=present"
```

## 5. Limit a playbook

Example playbook:

```yaml
---
- name: Configure SSH banner
  hosts: three_tier_app
  become: true

  tasks:
    - name: Create the banner
      copy:
        content: "Authorized access only\n"
        dest: /etc/ssh/banner.txt
        owner: root
        group: root
        mode: "0644"
```

Run the complete play only on `node1`:

```bash
ansible-playbook configure-banner.yml --limit node1
```

The playbook still contains `hosts: three_tier_app`, but the command-line limit temporarily reduces its final host selection.

## 6. Select multiple hosts

Select `node1` or `node2`:

```bash
ansible three_tier_app --limit 'node1:node2' -m ping
```

The colon means **OR**:

```text
node1 OR node2
```

Quote complex patterns so the local shell does not interpret special characters.

## 7. Limit execution to a group

Target `all`, but restrict execution to the `web` group:

```bash
ansible all --limit web -m ping
```

Only the `app` group:

```bash
ansible all --limit app -m ping
```

The `web` or `app` groups:

```bash
ansible all --limit 'web:app' -m ping
```

## 8. Exclude hosts or groups

Select the application hosts except `node3`:

```bash
ansible three_tier_app --limit 'all:!node3' -m ping
```

Expected targets:

```text
node1
node2
```

The exclamation mark means **NOT** or exclusion.

Exclude the `db` group:

```bash
ansible three_tier_app --limit 'all:!db' -m ping
```

Always quote patterns containing `!`, because interactive shells may interpret it as history expansion.

## 9. Use an intersection

An intersection selects hosts that belong to both patterns. The `&` character represents **AND**:

```bash
ansible all --limit 'three_tier_app:&web' -m ping
```

Meaning:

```text
Host belongs to three_tier_app AND web
```

In this inventory, the result is `node1`.

## 10. Use wildcard patterns

Select hosts whose inventory names start with `node`:

```bash
ansible all --limit 'node*' -m ping
```

Expected matches:

```text
node1
node2
node3
```

Quote wildcards to prevent the local shell from expanding them against filenames in the current directory.

## 11. Preview selected hosts

Preview a single-host limit:

```bash
ansible three_tier_app --limit node1 --list-hosts
```

Preview multiple hosts:

```bash
ansible three_tier_app --limit 'node1:node2' --list-hosts
```

Preview an exclusion:

```bash
ansible three_tier_app --limit 'all:!node3' --list-hosts
```

Preview a playbook's hosts:

```bash
ansible-playbook configure-banner.yml \
--limit node1 --list-hosts
```

`--list-hosts` displays matched hosts without executing the tasks.

## 12. Relationship with inventory and original target

`--limit` does not add a new host outside the inventory or original target.

The final selection can be understood as:

```text
Inventory hosts ∩ Original target ∩ Limit pattern
```

Example:

```bash
ansible web --limit node2 -m ping
```

In this inventory:

- The `web` group contains only `node1`.
- `node2` belongs to the `app` group.
- The original target and the limit do not overlap.
- Therefore, no hosts match.

Possible output includes:

```text
Could not match supplied host pattern
```

or:

```text
No hosts matched
```

## 13. Safe rollout strategy

### Step 1: Preview the target

```bash
ansible three_tier_app --limit node1 --list-hosts
```

### Step 2: Use check mode

```bash
ansible-playbook configure-banner.yml \
--check --diff --limit node1
```

### Step 3: Run on one host

```bash
ansible-playbook configure-banner.yml --limit node1
```

### Step 4: Verify the result

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node1
```

### Step 5: Roll out to the complete group

```bash
ansible-playbook configure-banner.yml
```

This is a limited or **canary rollout**: test on a small target before applying the change everywhere.

## 14. SSH banner example

Create the banner on `node1` first:

```bash
ansible three_tier_app -b --limit node1 -m copy -a \
'content="Authorized access only\nWelcome to {{ inventory_hostname }}\n" dest=/etc/ssh/banner.txt owner=root group=root mode=0644'
```

Verify it:

```bash
ansible three_tier_app --limit node1 -m command -a \
"cat /etc/ssh/banner.txt"
```

After confirming the result, apply it to all hosts:

```bash
ansible three_tier_app -b -m copy -a \
'content="Authorized access only\nWelcome to {{ inventory_hostname }}\n" dest=/etc/ssh/banner.txt owner=root group=root mode=0644'
```

`--limit node1` provided a safe first test without permanently changing the playbook or inventory.

## 15. Common mistakes

### Incorrect space in the option

Incorrect:

```bash
-- limit node1
```

Correct:

```bash
--limit node1
```

There is no space between `--` and `limit`.

### Host does not exist in inventory

```bash
ansible all --limit server99 -m ping
```

If `server99` is not in the inventory, no host will match.

### Original target and limit do not overlap

```bash
ansible web --limit node2 -m ping
```

If `node2` is not in `web`, the final target is empty.

### Complex pattern is not quoted

Less safe:

```bash
--limit all:!node3
```

Recommended:

```bash
--limit 'all:!node3'
```

### Confusing host limits with task selection

`--limit` restricts hosts, not tasks. Use tags to select tasks:

```bash
ansible-playbook site.yml --limit node1 --tags banner
```

## 16. Quick-reference table

| Requirement | Option |
|---|---|
| Only `node1` | `--limit node1` |
| `node1` or `node2` | `--limit 'node1:node2'` |
| Only the `web` group | `--limit web` |
| `web` or `app` | `--limit 'web:app'` |
| Everything except `node3` | `--limit 'all:!node3'` |
| Everything except `db` | `--limit 'all:!db'` |
| Hosts in both `three_tier_app` and `web` | `--limit 'three_tier_app:&web'` |
| Inventory names beginning with `node` | `--limit 'node*'` |
| Preview the selected hosts | `--limit node1 --list-hosts` |
| Short form | `-l node1` |

## 17. Practice exercises

### Exercise 1: Test only `node1`

```bash
ansible three_tier_app --limit node1 -m ping
```

### Exercise 2: Check uptime on two hosts

```bash
ansible three_tier_app --limit 'node1:node2' \
-m command -a "uptime"
```

### Exercise 3: Exclude `node3` and preview

```bash
ansible three_tier_app --limit 'all:!node3' --list-hosts
```

### Exercise 4: Preview banner changes on one host

```bash
ansible-playbook configure-banner.yml \
--check --diff --limit node1
```

### Exercise 5: Combine two groups

```bash
ansible all --limit 'web:app' -m ping
```

## 18. Review questions

1. What is the main purpose of `--limit`?
2. How do `hosts: three_tier_app` and `--limit node1` determine the final target?
3. What does the colon mean in `node1:node2`?
4. What does `!node3` do?
5. What operation does `&web` represent?
6. Why should complex patterns be quoted?
7. Can `--limit` add a host that is not in the inventory?
8. Why is `--list-hosts` useful?
9. What is the difference between `--limit` and `--tags`?
10. Why should a risky playbook be tested with `--limit node1` first?

---

## Final definition

> `--limit` temporarily restricts the original inventory targets of an Ansible command or playbook to a selected host, group, or host pattern.

Recommended safe workflow:

```text
Preview targets → Check mode → Test node1 → Verify → Full rollout
```
