# Ansible `--limit` Option — Study Notes (Roman Urdu)

`--limit` Ansible command ya playbook ke target hosts ko ek selected host, group ya host pattern tak restrict karta hai.

## Index

1. [`--limit` kya hai?](#1---limit-kya-hai)
2. [Basic syntax](#2-basic-syntax)
3. [Aapka lab environment](#3-aapka-lab-environment)
4. [Single host ko limit karna](#4-single-host-ko-limit-karna)
5. [Playbook ko single host par chalana](#5-playbook-ko-single-host-par-chalana)
6. [Multiple hosts select karna](#6-multiple-hosts-select-karna)
7. [Group ko limit karna](#7-group-ko-limit-karna)
8. [Host exclude karna](#8-host-exclude-karna)
9. [Intersection use karna](#9-intersection-use-karna)
10. [Wildcard patterns](#10-wildcard-patterns)
11. [Target preview karna](#11-target-preview-karna)
12. [`--limit` aur inventory ka relation](#12---limit-aur-inventory-ka-relation)
13. [Safe rollout strategy](#13-safe-rollout-strategy)
14. [Banner lab example](#14-banner-lab-example)
15. [Common mistakes](#15-common-mistakes)
16. [Quick-reference table](#16-quick-reference-table)
17. [Practice exercises](#17-practice-exercises)
18. [Review questions](#18-review-questions)

---

## 1. `--limit` kya hai?

`--limit` Ansible ko batata hai:

> Original target mein jitne bhi hosts hon, automation sirf specified host, group ya pattern par run karo.

Example:

```bash
ansible three_tier_app --limit node1 -m ping
```

Yahan:

| Hissa | Matlab |
|---|---|
| `three_tier_app` | Original target group |
| `--limit node1` | Target ko sirf `node1` tak restrict karo |
| `-m ping` | Ansible connectivity test karo |

Agar `three_tier_app` mein `node1`, `node2` aur `node3` hain, command sirf `node1` par chalegi.

## 2. Basic syntax

Ad-hoc command:

```bash
ansible ORIGINAL_TARGET --limit LIMIT_PATTERN -m MODULE
```

Playbook:

```bash
ansible-playbook PLAYBOOK.yml --limit LIMIT_PATTERN
```

Short option bhi available hai:

```bash
-l node1
```

Yeh dono same hain:

```bash
ansible all --limit node1 -m ping
ansible all -l node1 -m ping
```

Study notes aur demonstrations mein `--limit` zyada readable hai.

## 3. Aapka lab environment

Example inventory groups:

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

Is inventory ke mutabiq:

| Pattern | Selected hosts |
|---|---|
| `web` | `node1` |
| `app` | `node2` |
| `db` | `node3` |
| `three_tier_app` | `node1`, `node2`, `node3` |

## 4. Single host ko limit karna

```bash
ansible three_tier_app --limit node1 -m ping
```

Expected target:

```text
node1
```

`node2` aur `node3` par command run nahin hogi.

Package installation ko pehle `node1` par test karna:

```bash
ansible three_tier_app -b --limit node1 -m dnf -a \
"name=tree state=present"
```

## 5. Playbook ko single host par chalana

Agar playbook mein yeh ho:

```yaml
---
- name: Configure SSH banner
  hosts: three_tier_app
  become: true

  tasks:
    - name: Create banner
      copy:
        content: "Authorized access only\n"
        dest: /etc/ssh/banner.txt
        owner: root
        group: root
        mode: "0644"
```

To yeh command puri playbook ko sirf `node1` par run karegi:

```bash
ansible-playbook configure-banner.yml --limit node1
```

Playbook ka `hosts: three_tier_app` change nahin hota. Command-line limit final target ko temporarily restrict karti hai.

## 6. Multiple hosts select karna

`node1` ya `node2` select karne ke liye:

```bash
ansible three_tier_app --limit 'node1:node2' -m ping
```

Colon `:` ka matlab yahan **OR** hai:

```text
node1 OR node2
```

Expected targets:

```text
node1
node2
```

Shell ko special characters interpret karne se rokne ke liye complex patterns ko single quotes mein rakhein.

## 7. Group ko limit karna

Original target `all` ho, lekin sirf `web` group par command chalani ho:

```bash
ansible all --limit web -m ping
```

Sirf `app` group:

```bash
ansible all --limit app -m ping
```

Do groups:

```bash
ansible all --limit 'web:app' -m ping
```

## 8. Host exclude karna

`three_tier_app` ke tamam hosts select karein, lekin `node3` ko exclude karein:

```bash
ansible three_tier_app --limit 'all:!node3' -m ping
```

Expected targets:

```text
node1
node2
```

`!` ka matlab **NOT** ya exclusion hai.

Group exclude karna:

```bash
ansible three_tier_app --limit 'all:!db' -m ping
```

Is example mein `db` group ka `node3` exclude ho jayega.

> Complex patterns ko quote zaroor karein, kyun ke interactive shell `!` ko history expansion ke liye interpret kar sakta hai.

## 9. Intersection use karna

Intersection ka matlab hai host dono groups mein hona chahiye.

Ansible pattern mein `&` intersection ko represent karta hai:

```bash
ansible all --limit 'three_tier_app:&web' -m ping
```

Matlab:

```text
Host three_tier_app mein bhi ho AND web mein bhi ho
```

Aapke inventory mein expected result:

```text
node1
```

## 10. Wildcard patterns

`node` se shuru hone wale hosts:

```bash
ansible all --limit 'node*' -m ping
```

Expected matches:

```text
node1
node2
node3
```

Wildcard ko quote karein, warna local shell usay current directory ke filenames ke against expand kar sakta hai.

## 11. Target preview karna

Koi change karne se pehle selected hosts preview karein:

```bash
ansible three_tier_app --limit node1 --list-hosts
```

Multiple hosts:

```bash
ansible three_tier_app --limit 'node1:node2' --list-hosts
```

Exclude pattern:

```bash
ansible three_tier_app --limit 'all:!node3' --list-hosts
```

Playbook ke selected hosts preview karne ke liye:

```bash
ansible-playbook configure-banner.yml --limit node1 --list-hosts
```

`--list-hosts` tasks execute nahin karta; sirf matched hosts dikhata hai.

## 12. `--limit` aur inventory ka relation

`--limit` inventory ke bahar naya host add nahin karta.

Final target aam tor par yeh hota hai:

```text
Inventory hosts ∩ Original target ∩ Limit pattern
```

Example:

```bash
ansible web --limit node2 -m ping
```

Aapke inventory mein:

- `web` mein sirf `node1` hai.
- `node2` `app` group mein hai.
- Is liye koi host match nahin karega.

Possible warning:

```text
Could not match supplied host pattern
```

Ya:

```text
No hosts matched
```

## 13. Safe rollout strategy

Nayi ya risky automation ke liye recommended sequence:

### Step 1: Target preview

```bash
ansible three_tier_app --limit node1 --list-hosts
```

### Step 2: Check mode

```bash
ansible-playbook configure-banner.yml \
--check --diff --limit node1
```

### Step 3: Ek node par actual run

```bash
ansible-playbook configure-banner.yml --limit node1
```

### Step 4: Result verify karein

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node1
```

### Step 5: Complete group par rollout

```bash
ansible-playbook configure-banner.yml
```

Is approach ko **canary rollout** ya limited rollout kaha ja sakta hai.

## 14. Banner lab example

Banner file ko pehle `node1` par create karein:

```bash
ansible three_tier_app -b --limit node1 -m copy -a \
'content="Authorized access only\nWelcome to {{ inventory_hostname }}\n" dest=/etc/ssh/banner.txt owner=root group=root mode=0644'
```

Verify:

```bash
ansible three_tier_app --limit node1 -m command -a \
"cat /etc/ssh/banner.txt"
```

Result correct ho to tamam nodes par run karein:

```bash
ansible three_tier_app -b -m copy -a \
'content="Authorized access only\nWelcome to {{ inventory_hostname }}\n" dest=/etc/ssh/banner.txt owner=root group=root mode=0644'
```

Yahan `--limit node1` ne pehle safe test provide kiya, lekin actual command ko permanently change nahin kiya.

## 15. Common mistakes

### Mistake 1: Space dena

Incorrect:

```bash
-- limit node1
```

Correct:

```bash
--limit node1
```

`--limit` ek complete option name hai; double hyphen aur word ke darmiyan space nahin hoti.

### Mistake 2: Host inventory mein maujood nahin

```bash
ansible all --limit server99 -m ping
```

Agar `server99` inventory mein nahin hai to koi host match nahin karega.

### Mistake 3: Original target aur limit overlap nahin karte

```bash
ansible web --limit node2 -m ping
```

Agar `node2` `web` group mein nahin hai, command ka final target empty hoga.

### Mistake 4: Complex pattern quote nahin kiya

Less safe:

```bash
--limit all:!node3
```

Recommended:

```bash
--limit 'all:!node3'
```

### Mistake 5: `--limit` ko task limit samajhna

`--limit` hosts ko restrict karta hai, tasks ko nahin. Tasks select karne ke liye tags use kiye ja sakte hain:

```bash
ansible-playbook site.yml --limit node1 --tags banner
```

## 16. Quick-reference table

| Requirement | Example |
|---|---|
| Sirf `node1` | `--limit node1` |
| `node1` ya `node2` | `--limit 'node1:node2'` |
| Sirf `web` group | `--limit web` |
| `web` ya `app` | `--limit 'web:app'` |
| `node3` ke ilawa sab | `--limit 'all:!node3'` |
| `db` group ke ilawa sab | `--limit 'all:!db'` |
| `three_tier_app` aur `web` dono | `--limit 'three_tier_app:&web'` |
| `node` se shuru hone wale hosts | `--limit 'node*'` |
| Selected hosts preview | `--limit node1 --list-hosts` |
| Short form | `-l node1` |

## 17. Practice exercises

### Exercise 1

Sirf `node1` ki connectivity test karein:

```bash
ansible three_tier_app --limit node1 -m ping
```

### Exercise 2

`node1` aur `node2` ki uptime check karein:

```bash
ansible three_tier_app --limit 'node1:node2' \
-m command -a "uptime"
```

### Exercise 3

`node3` ko exclude karke targets preview karein:

```bash
ansible three_tier_app --limit 'all:!node3' --list-hosts
```

### Exercise 4

Banner playbook ko check mode mein sirf `node1` par run karein:

```bash
ansible-playbook configure-banner.yml \
--check --diff --limit node1
```

### Exercise 5

`web` aur `app` groups ko combine karke ping karein:

```bash
ansible all --limit 'web:app' -m ping
```

## 18. Review questions

1. `--limit` ka basic purpose kya hai?
2. `--limit node1` aur `hosts: three_tier_app` mil kar final target kaise banate hain?
3. `node1:node2` mein colon ka kya matlab hai?
4. `!node3` kya karta hai?
5. `&web` kis operation ko represent karta hai?
6. Complex patterns ko quotes mein kyun rakhna chahiye?
7. Kya `--limit` inventory ke bahar host add kar sakta hai?
8. `--list-hosts` kyun useful hai?
9. `--limit` aur `--tags` mein kya farq hai?
10. Risky playbook ko pehle `--limit node1` ke saath kyun chalana chahiye?

---

## Final definition

> `--limit` Ansible command ya playbook ke original inventory targets ko selected host, group ya pattern tak temporarily restrict karta hai.

Recommended safe workflow:

```text
Preview targets → Check mode → node1 test → Verify → Full rollout
```
