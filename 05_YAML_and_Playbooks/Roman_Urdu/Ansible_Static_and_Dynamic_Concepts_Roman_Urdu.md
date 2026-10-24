# Ansible Static aur Dynamic Concepts

## Roman Urdu Study Notes — Personal Lab

## Fehrist

1. [One-line definition](#1-one-line-definition)
2. [Static inventory](#2-static-inventory)
3. [Aap ke lab ki static inventory](#3-aap-ke-lab-ki-static-inventory)
4. [Dynamic inventory](#4-dynamic-inventory)
5. [Static aur dynamic inventory ka comparison](#5-static-aur-dynamic-inventory-ka-comparison)
6. [Inventory verify karne ke commands](#6-inventory-verify-karne-ke-commands)
7. [Static imports aur dynamic includes](#7-static-imports-aur-dynamic-includes)
8. [`import_tasks` ka static example](#8-import_tasks-ka-static-example)
9. [`include_tasks` ka dynamic example](#9-include_tasks-ka-dynamic-example)
10. [Imports aur includes ka comparison](#10-imports-aur-includes-ka-comparison)
11. [Kab kya use karein?](#11-kab-kya-use-karein)
12. [Common confusion](#12-common-confusion)
13. [Practice questions](#13-practice-questions)
14. [Quick reference](#14-quick-reference)

---

## 1. One-line definition

> **Static** cheez pehle se fixed hoti hai aur Ansible ko execution shuru hone
> se pehle maloom hoti hai. **Dynamic** cheez run time par discover ya decide
> hoti hai.

Ansible mein yeh terms do important contexts mein milti hain:

1. Static inventory aur dynamic inventory
2. Static imports aur dynamic includes

In dono contexts ka maqsad alag hai, is liye unhein mix na karein.

---

## 2. Static inventory

Static inventory mein managed nodes, IP addresses aur groups manually inventory
file mein define kiye jate hain.

```ini
[web]
node1 ansible_host=192.168.1.154

[app]
node2 ansible_host=192.168.1.185

[db]
node3 ansible_host=192.168.1.190
```

Isay **static** is liye kehte hain kyun ke:

- hosts manually likhe jate hain;
- naya server automatically inventory mein add nahi hota;
- IP ya hostname badalne par file manually update karni parti hai;
- inventory ka data tab tak same rehta hai jab tak administrator usay edit na kare.

Static inventory INI ya YAML format mein ho sakti hai.

### INI format

```ini
[web]
node1 ansible_host=192.168.1.154
```

### YAML format

```yaml
---
all:
  children:
    web:
      hosts:
        node1:
          ansible_host: 192.168.1.154
```

Dono examples static inventory hain. File extension `.ini`, `.yaml` ya bina
extension ke `nodes` hone se inventory static ya dynamic decide nahi hoti.
Uska data kahan se aata hai, yeh asal farq hai.

---

## 3. Aap ke lab ki static inventory

Aap ka environment:

| Group | Host | IP address | Role |
|---|---|---:|---|
| `web` | `node1` | `192.168.1.154` | Web server |
| `app` | `node2` | `192.168.1.185` | Application server |
| `db` | `node3` | `192.168.1.190` | Database server |

Aap ki inventory file ka practical example:

```ini
# /home/ansibleadmin/automation/inventory/nodes

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

Aap ka three-node LAN lab stable aur chhota hai, is liye **static inventory is
environment ke liye simple aur munasib choice hai**.

---

## 4. Dynamic inventory

Dynamic inventory managed hosts ki list kisi external source se automatically
hasil karti hai.

External sources ki examples:

- AWS EC2
- Microsoft Azure
- Google Cloud
- VMware vCenter
- OpenStack
- Kubernetes
- Configuration Management Database (CMDB)

Dynamic inventory aam tor par inventory plugin use karti hai. Purane environments
mein executable inventory scripts bhi mil sakte hain.

### AWS EC2 plugin ki simplified example

```yaml
---
plugin: amazon.aws.aws_ec2
regions:
  - us-east-1
filters:
  instance-state-name: running
```

Jab Ansible is source ko process karta hai to AWS API se running EC2 instances
discover karta hai. Agar naya matching EC2 instance ban jaye, to uska IP manually
static file mein add karne ki zarurat nahi hoti.

### Dynamic ka matlab random nahi

Dynamic inventory random hosts nahi banati. Woh defined plugin, credentials,
filters aur external system ke current data ke mutabiq hosts return karti hai.

### Requirements

Dynamic inventory ko aam tor par yeh cheezen chahiye hoti hain:

- relevant collection ya plugin;
- API access;
- authorized credentials;
- region, datacenter ya project ki settings;
- filters taa-ke sirf required hosts select hon.

Credentials ko inventory file mein plain text mein hard-code na karein. Secure
credential mechanism, environment variables, Ansible Vault ya automation
platform credentials use karein.

---

## 5. Static aur dynamic inventory ka comparison

| Static inventory | Dynamic inventory |
|---|---|
| Hosts manually define hote hain | Hosts external source se discover hote hain |
| INI ya YAML inventory file aam hai | Inventory plugin ya script use hota hai |
| Manual update zaroori hoti hai | Current infrastructure data automatically milta hai |
| Chhote aur stable labs ke liye behtar | Cloud aur frequently changing environments ke liye behtar |
| Setup simple hota hai | API, credentials aur plugin configuration chahiye |
| Aap ke three-node LAN lab ke liye suitable | AWS/VMware production environment ke liye useful |

### Important point

Dynamic inventory bhi groups aur variables bana sakti hai. Farq yeh nahi ke
groups mojood hain ya nahi; farq yeh hai ke hosts ka data manually likha gaya
hai ya external source se dynamically mila hai.

---

## 6. Inventory verify karne ke commands

Project directory mein jayein:

```bash
cd /home/ansibleadmin/automation
```

Inventory graph:

```bash
ansible-inventory --graph
```

Tamam inventory data:

```bash
ansible-inventory --list
```

`node1` ki resolved variables:

```bash
ansible-inventory --host node1
```

Parent group ke hosts:

```bash
ansible three_tier_app --list-hosts
```

Connectivity:

```bash
ansible three_tier_app -m ping
```

Specific inventory source dene ke liye:

```bash
ansible-inventory -i ./inventory/nodes --graph
ansible three_tier_app -i ./inventory/nodes -m ping
```

`ansible.cfg` mein inventory path configured ho to `-i` har command ke saath
likhna zaroori nahi.

---

## 7. Static imports aur dynamic includes

Static aur dynamic terms playbook reuse mein bhi use hoti hain.

### Static reuse

- `import_playbook`
- `import_tasks`
- `import_role`

Ansible imported content ko playbook processing ke waqt pehle hi load aur expand
kar leta hai. Is liye isay static kaha jata hai.

### Dynamic reuse

- `include_tasks`
- `include_role`

Ansible included content ko run time par process karta hai. Is liye conditions,
loops aur run-time variables ke mutabiq inclusion decide ki ja sakti hai.

> `import_playbook` sirf playbook ke top level par use hota hai. Task list ke
> andar doosri task file ke liye `import_tasks` ya `include_tasks` use karein.

---

## 8. `import_tasks` ka static example

Project structure:

```text
playbooks/
├── static-demo.yml
└── tasks/
    └── install-tools.yml
```

Task file:

```yaml
# playbooks/tasks/install-tools.yml
---
- name: Install Git
  dnf:
    name: git
    state: present

- name: Install Curl
  dnf:
    name: curl
    state: present
```

Main playbook:

```yaml
# playbooks/static-demo.yml
---
- name: Demonstrate static task import
  hosts: three_tier_app
  become: true
  gather_facts: false

  tasks:
    - name: Import tool-installation tasks
      import_tasks: tasks/install-tools.yml
```

Validate aur run:

```bash
ansible-playbook --syntax-check playbooks/static-demo.yml
ansible-playbook playbooks/static-demo.yml --limit node1
```

`import_tasks` ki file Ansible ko processing ke waqt maloom hoti hai aur uske
tasks pehle se playbook structure ka hissa ban jate hain.

---

## 9. `include_tasks` ka dynamic example

Project structure:

```text
playbooks/
├── dynamic-demo.yml
└── tasks/
    ├── web-tasks.yml
    └── db-tasks.yml
```

Web task file:

```yaml
# playbooks/tasks/web-tasks.yml
---
- name: Install Nginx
  dnf:
    name: nginx
    state: present
```

Database task file:

```yaml
# playbooks/tasks/db-tasks.yml
---
- name: Install MariaDB server
  dnf:
    name: mariadb-server
    state: present
```

Main playbook:

```yaml
# playbooks/dynamic-demo.yml
---
- name: Demonstrate dynamic task inclusion
  hosts: three_tier_app
  become: true
  gather_facts: false

  tasks:
    - name: Include web tasks at run time
      include_tasks: tasks/web-tasks.yml
      when: "'web' in group_names"

    - name: Include database tasks at run time
      include_tasks: tasks/db-tasks.yml
      when: "'db' in group_names"
```

Validate aur run:

```bash
ansible-playbook --syntax-check playbooks/dynamic-demo.yml
ansible-playbook playbooks/dynamic-demo.yml
```

Expected behavior:

- `node1` par `web-tasks.yml` include hogi;
- `node3` par `db-tasks.yml` include hogi;
- `node2` par dono includes skip ho sakte hain;
- `skipped` error nahi, false condition ka expected result hai.

---

## 10. Imports aur includes ka comparison

| Static import | Dynamic include |
|---|---|
| `import_tasks` / `import_role` | `include_tasks` / `include_role` |
| Content pehle process hota hai | Content run time par process hota hai |
| Structure pehle se known hoti hai | Run-time decision mumkin hota hai |
| Simple, fixed reuse ke liye acha | Conditions aur loops ke liye flexible |
| Imported tasks aksar listing mein pehle nazar aate hain | Included tasks execute hone par expand hote hain |

### `--list-tasks` se observe karein

```bash
ansible-playbook playbooks/static-demo.yml --list-tasks
ansible-playbook playbooks/dynamic-demo.yml --list-tasks
```

Static import ke individual tasks Ansible ko pehle se maloom ho sakte hain.
Dynamic include ke andar ke tasks run time tak fully expand na hon.

---

## 11. Kab kya use karein?

### Static inventory use karein jab:

- hosts ki tadaad chhoti ho;
- IPs aur hostnames stable hon;
- personal LAN ya classroom lab ho;
- simple troubleshooting aur readability important ho.

### Dynamic inventory use karein jab:

- cloud instances frequently create/delete hote hon;
- VMware ya cloud platform source of truth ho;
- tags, regions ya metadata se hosts group karne hon;
- manual inventory jaldi outdated ho sakti ho.

### `import_tasks` use karein jab:

- task structure fixed ho;
- content ko hamesha reuse karna ho;
- predictable parsing aur task listing chahiye.

### `include_tasks` use karein jab:

- file selection run time par karni ho;
- inclusion par `when` condition lagani ho;
- include ko loop ke saath chalana ho;
- run-time variable ke mutabiq different task file chahiye.

---

## 12. Common confusion

### Kya `nodes.yaml` dynamic inventory hai?

Zaroori nahi. Agar `nodes.yaml` mein hosts manually likhe hain to woh YAML
format ki **static inventory** hai.

### Kya `inventory` directory dynamic inventory hai?

Nahi. Directory ka naam inventory source ko organize karta hai. Uske andar
static files, dynamic plugin configuration, ya dono ho sakte hain.

### Kya variables use karne se playbook dynamic ho jati hai?

Variables playbook ko flexible banati hain, lekin har variable use ko “dynamic
inventory” nahi kehte. Dynamic inventory ka specific matlab external source se
hosts discover karna hai.

### Kya static ka matlab hard-coded aur hamesha bura hai?

Nahi. Chhote stable lab ke liye static inventory simple, readable aur reliable
hai. Dynamic inventory tab faida deti hai jab infrastructure frequently change ho.

### Kya `include_tasks` aur dynamic inventory aik hi cheez hain?

Nahi. `include_tasks` playbook ke task reuse ka feature hai, jab ke dynamic
inventory managed hosts discover karne ka feature hai.

---

## 13. Practice questions

1. Static ka one-line matlab kya hai?
2. Dynamic ka one-line matlab kya hai?
3. Aap ke three-node LAN lab mein kaunsi inventory use ho rahi hai?
4. Static inventory ko manually update kyun karna parta hai?
5. Dynamic inventory hosts kahan se hasil karti hai?
6. Dynamic inventory ke chaar possible external sources batayein.
7. Kya `.yaml` extension file ko automatically dynamic banati hai?
8. `ansible-inventory --graph` kya dikhata hai?
9. `ansible-inventory --host node1` kya dikhata hai?
10. `-i` option ka kya kaam hai?
11. Static reuse ke teen keywords kaun se hain?
12. Dynamic reuse ke do keywords kaun se hain?
13. `import_tasks` ko static kyun kaha jata hai?
14. `include_tasks` ko dynamic kyun kaha jata hai?
15. `include_tasks` ke saath `when` kyun useful hai?
16. `skipped` result ka kya matlab hai?
17. `import_playbook` kahan use hota hai?
18. `--list-tasks` se kya observe kiya ja sakta hai?
19. Aap ke current lab ke liye static inventory kyun better hai?
20. AWS environment mein dynamic inventory kyun useful ho sakti hai?

---

## 14. Quick reference

```bash
# Inventory graph
ansible-inventory --graph

# Complete inventory
ansible-inventory --list

# One host ki resolved information
ansible-inventory --host node1

# Parent group ke hosts
ansible three_tier_app --list-hosts

# Connectivity
ansible three_tier_app -m ping

# Explicit inventory source
ansible-inventory -i ./inventory/nodes --graph

# Static import ke tasks
ansible-playbook playbooks/static-demo.yml --list-tasks

# Dynamic include ke tasks
ansible-playbook playbooks/dynamic-demo.yml --list-tasks

# Syntax checks
ansible-playbook --syntax-check playbooks/static-demo.yml
ansible-playbook --syntax-check playbooks/dynamic-demo.yml

# Safe one-node test
ansible-playbook playbooks/static-demo.yml --limit node1
```

## Khulasa

- Static inventory mein hosts manually define hote hain.
- Dynamic inventory external source se current hosts discover karti hai.
- Aap ke stable three-node LAN lab ke liye static inventory munasib hai.
- `import_tasks` aur `import_role` static reuse hain.
- `include_tasks` aur `include_role` dynamic reuse hain.
- Inventory discovery aur task inclusion alag concepts hain.
