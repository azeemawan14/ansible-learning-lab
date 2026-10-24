# Ansible Basic Terms — Roman Urdu Indexed Study Notes

> In notes mein tez hands-on practice ke liye short module names use kiye gaye hain.

## Index

1. [Ansible ka ta'aruf](#1-ansible-ka-taaruf)
2. [Control node](#2-control-node)
3. [Managed nodes](#3-managed-nodes)
4. [Inventory file](#4-inventory-file)
5. [Ansible configuration file](#5-ansible-configuration-file)
6. [Ad-hoc commands](#6-ad-hoc-commands)
7. [Modules](#7-modules)
8. [Module arguments](#8-module-arguments)
9. [State values](#9-state-values)
10. [YAML basics](#10-yaml-basics)
11. [Task](#11-task)
12. [Play](#12-play)
13. [Playbook](#13-playbook)
14. [Variables](#14-variables)
15. [Facts](#15-facts)
16. [Loops](#16-loops)
17. [Conditions](#17-conditions)
18. [Register](#18-register)
19. [Handlers aur notify](#19-handlers-aur-notify)
20. [Become](#20-become)
21. [Idempotency](#21-idempotency)
22. [Templates](#22-templates)
23. [Roles](#23-roles)
24. [Collections](#24-collections)
25. [Ansible Vault](#25-ansible-vault)
26. [Verification commands](#26-verification-commands)
27. [Recommended learning order](#27-recommended-learning-order)

---

## Quick-reference table

| Term | Asaan matlab | Example |
|---|---|---|
| Control node | Machine jahan Ansible install aur commands run hoti hain | `ansible-server` |
| Managed node | Remote machine jise Ansible manage karta hai | `node1`, `node2`, `node3` |
| Inventory | Managed hosts, groups aur connection variables ki file | `inventory/nodes` |
| Configuration file | Ansible ka default behavior control karti hai | `ansible.cfg` |
| Ad-hoc command | Aik quick task ke liye single Ansible command | `ansible all -m ping` |
| Module | Aik khaas operation perform karne wala Ansible tool | `dnf`, `copy`, `file` |
| Argument | Module ko di jane wali information | `name=httpd state=present` |
| YAML | Playbooks likhne ki language | `.yml` ya `.yaml` |
| Task | Play ke andar aik action | HTTPD install karna |
| Play | Hosts ko tasks ki list ke saath jorta hai | `web` hosts configure karna |
| Playbook | Aik ya zyada plays wali YAML file | `install-httpd.yml` |
| Variable | Dobara use hone wali named value | `web_package: httpd` |
| Fact | Managed node se collect ki gayi system information | OS, memory, IP |
| Loop | Multiple items par task repeat karta hai | Kai users banana |
| Condition | Faisla karti hai task run ho ya nahi | `when:` |
| Register | Task ka result variable mein save karta hai | `register: result` |
| Handler | Change hone par trigger hone wala task | HTTPD restart karna |
| Template | Variables wali dynamic file | `httpd.conf.j2` |
| Role | Reusable automation ka standard structure | `roles/webserver/` |
| Become | Privilege escalation use karta hai | `become: true` |
| Idempotency | Bila-zaroorat changes ke baghair desired state maintain karna | Installed package installed rahe |

---

## 1. Ansible ka ta'aruf

Ansible aik agentless automation aur configuration-management tool hai. Control node aam tor par SSH ke zariye managed nodes se connect hota hai aur unhein desired state mein lata hai.

Is ke common uses:

- Packages install ya remove karna
- Services manage karna
- Users aur groups banana
- Files aur configurations deploy karna
- Cron jobs aur firewalls manage karna
- Applications deploy karna

[Wapas Index par](#index)

## 2. Control node

Control node woh machine hai jahan Ansible install hota hai aur jahan se commands aur playbooks run kiye jate hain.

```text
ansible-server
```

```bash
ansible all -m ping
ansible-playbook install-httpd.yml
```

[Wapas Index par](#index)

## 3. Managed nodes

Managed nodes woh remote machines hain jinhein Ansible control karta hai:

```text
node1
node2
node3
```

Ansible aam tor par SSH ke zariye connect hota hai. Linux managed nodes par Ansible install karna zaroori nahi, lekin suitable Python interpreter aam tor par required hota hai.

[Wapas Index par](#index)

## 4. Inventory file

Inventory hosts, groups aur connection variables define karti hai.

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

```ini
node1 ansible_host=192.168.1.154
```

| Value | Matlab |
|---|---|
| `node1` | `inventory_hostname` — Ansible mein host ka naam |
| `192.168.1.154` | `ansible_host` — asal connection address |

```bash
ansible-inventory --graph
ansible-inventory --host node1
ansible-inventory --list
```

[Wapas Index par](#index)

## 5. Ansible configuration file

`ansible.cfg` default settings deta hai taa-ke har command mein unhein repeat na karna pare.

```ini
[defaults]
inventory = ./inventory/nodes
remote_user = ansibleadmin
host_key_checking = True
ask_pass = False
private_key_file = /home/ansibleadmin/.ssh/ansible-key

[privilege_escalation]
become_method = sudo
become_user = root
become_ask_pass = False
```

```bash
ansible --version
ansible-config dump --only-changed
```

Configuration search order:

1. `ANSIBLE_CONFIG` environment variable wali file
2. Current directory ki `ansible.cfg`
3. `~/.ansible.cfg`
4. `/etc/ansible/ansible.cfg`

Ansible pehli milne wali configuration file use karta hai.

[Wapas Index par](#index)

## 6. Ad-hoc commands

Ad-hoc command aik quick, one-time task ko playbook banaye baghair perform karti hai.

```bash
ansible TARGET -m MODULE -a "ARGUMENTS"
```

```bash
ansible all -m ping
ansible web -m dnf -a "name=httpd state=present" -b
ansible all -m command -a "uptime"
```

Quick checks aur troubleshooting ke liye ad-hoc commands use karein. Repeatable ya multi-step automation ke liye playbook behtar hai.

[Wapas Index par](#index)

## 7. Modules

Module aik khaas qisam ka operation perform karta hai.

| Module | Kaam |
|---|---|
| `ping` | Ansible connectivity aur Python execution test karna |
| `command` | Normal command run karna |
| `shell` | Shell features wali command run karna |
| `file` | Files, directories, links aur permissions manage karna |
| `copy` | File copy ya direct content write karna |
| `dnf` | Rocky/RHEL packages manage karna |
| `service` | Services manage karna |
| `user` | Users manage karna |
| `group` | Groups manage karna |
| `cron` | Cron jobs manage karna |
| `debug` | Messages aur variables display karna |
| `setup` | System facts collect karna |

```bash
ansible-doc file
ansible-doc -s file
```

[Wapas Index par](#index)

## 8. Module arguments

Arguments module ko batate hain ke kis resource ko kis desired state mein lana hai.

```bash
ansible web -m dnf -a "name=httpd state=present" -b
```

| Part | Matlab |
|---|---|
| `web` | Target group |
| `dnf` | Module |
| `name=httpd` | Package ka naam |
| `state=present` | Desired state |
| `-b` | Privilege escalation |

Har module ke arguments alag ho sakte hain:

```bash
ansible-doc -s MODULE
```

[Wapas Index par](#index)

## 9. State values

`state` required final condition batata hai. Is ki allowed values module par depend karti hain.

### Package states

| State | Matlab |
|---|---|
| `present` | Package installed hona chahiye |
| `absent` | Package installed nahi hona chahiye |
| `latest` | Latest available repository version installed honi chahiye |

```bash
ansible web -m dnf -a "name=httpd state=present" -b
ansible web -m dnf -a "name=httpd state=latest" -b
ansible web -m dnf -a "name=httpd state=absent" -b
```

Production mein `latest` ehtiyat se use karein kyun ke yeh unplanned upgrade la sakta hai.

### File states

| State | Matlab |
|---|---|
| `file` | Path regular file honi chahiye; missing file create nahi karta |
| `touch` | Zaroorat par empty file create karta hai |
| `directory` | Directory exist karni chahiye |
| `link` | Symbolic link exist karna chahiye |
| `hard` | Hard link exist karna chahiye |
| `absent` | File, directory ya link exist nahi karna chahiye |

### Service states

| State | Matlab |
|---|---|
| `started` | Service running honi chahiye |
| `stopped` | Service running nahi honi chahiye |
| `restarted` | Task run hone par service restart kare |
| `reloaded` | Service configuration reload kare |

```yaml
service:
  name: httpd
  state: started
  enabled: true
```

`state: started` service ko abhi run karta hai. `enabled: true` reboot ke baad automatic startup configure karta hai.

[Wapas Index par](#index)

## 10. YAML basics

- Tabs nahi, spaces use karein.
- Indentation structure define karti hai.
- List item ke liye `-` use hota hai.
- Mapping ke liye `key: value` use hota hai.
- Do-space indentation consistent rakhein.

```yaml
---
- name: Configure web servers
  hosts: web
  become: true

  tasks:
    - name: Install HTTPD
      dnf:
        name: httpd
        state: present
```

[Wapas Index par](#index)

## 11. Task

Task aik module ke zariye perform hone wala aik action hai.

```yaml
- name: Install HTTPD
  dnf:
    name: httpd
    state: present
```

Task ka `name` action ko saaf taur par describe karna chahiye.

[Wapas Index par](#index)

## 12. Play

Play target hosts ko tasks aur doosri settings ki list ke saath jorta hai.

```yaml
- name: Configure web servers
  hosts: web
  become: true

  tasks:
    - name: Install HTTPD
      dnf:
        name: httpd
        state: present

    - name: Start HTTPD
      service:
        name: httpd
        state: started
        enabled: true
```

Yeh poora block aik play hai.

[Wapas Index par](#index)

## 13. Playbook

Playbook aik YAML file hai jis mein aik ya zyada plays ho sakte hain.

```yaml
---
- name: Configure web servers
  hosts: web
  tasks:
    # Web tasks

- name: Configure database servers
  hosts: db
  tasks:
    # Database tasks
```

```bash
ansible-playbook site.yml
```

[Wapas Index par](#index)

## 14. Variables

Variable aik named value hai jise dobara use kiya ja sakta hai.

```yaml
vars:
  web_package: httpd
  web_service: httpd

tasks:
  - name: Install the web package
    dnf:
      name: "{{ web_package }}"
      state: present
```

Agar value Jinja2 expression se shuru ho to usay quotes mein rakhein:

```yaml
name: "{{ web_package }}"
```

Variables inventory, playbook, `group_vars`, `host_vars`, roles, facts, registered output aur command-line extra variables se aa sakte hain.

[Wapas Index par](#index)

## 15. Facts

Facts managed nodes se collect ki gayi system information hoti hai.

| Fact | Example information |
|---|---|
| `ansible_distribution` | `Rocky` |
| `ansible_distribution_version` | `9.8` |
| `ansible_os_family` | `RedHat` |
| `ansible_hostname` | `node1` |
| `ansible_fqdn` | `node1.nitclasses.com` |
| `ansible_architecture` | `x86_64` |
| `ansible_kernel` | Running kernel version |

```bash
ansible all -m setup
ansible all -m setup -a "filter=ansible_distribution*"
```

```yaml
- name: Display operating system
  debug:
    msg: "{{ inventory_hostname }} runs {{ ansible_distribution }}"
```

Playbooks default taur par facts gather karte hain jab tak `gather_facts: false` na diya jaye.

[Wapas Index par](#index)

## 16. Loops

Loop aik task ko multiple items ke liye repeat karta hai.

```yaml
- name: Create application users
  user:
    name: "{{ item }}"
    state: present
  loop:
    - alice
    - bob
    - carol
```

Packages ke liye direct list loop se behtar hoti hai:

```yaml
- name: Install required packages
  dnf:
    name:
      - httpd
      - git
      - vim
    state: present
```

[Wapas Index par](#index)

## 17. Conditions

`when` decide karta hai ke task run hona chahiye ya nahi.

```yaml
- name: Install HTTPD on Red Hat-family systems
  dnf:
    name: httpd
    state: present
  when: ansible_os_family == "RedHat"
```

Normal `when` expression ke gird `{{ }}` braces na lagayein.

[Wapas Index par](#index)

## 18. Register

`register` task ka result variable mein save karta hai.

```yaml
- name: Check system uptime
  command: uptime
  register: uptime_result
  changed_when: false

- name: Display uptime
  debug:
    var: uptime_result.stdout
```

| Field | Matlab |
|---|---|
| `stdout` | Normal output |
| `stderr` | Error output |
| `rc` | Return code |
| `changed` | Kya Ansible ne change report kiya |
| `failed` | Kya task fail hua |

[Wapas Index par](#index)

## 19. Handlers aur notify

Handler aik special task hai jo aam tor par tab run hota hai jab notify karne wala task change report kare.

```yaml
tasks:
  - name: Deploy HTTPD configuration
    copy:
      src: httpd.conf
      dest: /etc/httpd/conf/httpd.conf
    notify: Restart HTTPD

handlers:
  - name: Restart HTTPD
    service:
      name: httpd
      state: restarted
```

Agar configuration file change na ho to handler run nahi hota.

[Wapas Index par](#index)

## 20. Become

`become: true` privilege escalation enable karta hai, aam tor par `sudo` ke zariye.

```yaml
- name: Configure web servers
  hosts: web
  become: true
```

Packages, services, users, firewalls aur system files manage karne ke liye aksar is ki zaroorat hoti hai. Ansible `ansibleadmin` ke taur par login karke `sudo` use kar sakta hai; direct root SSH login zaroori nahi.

[Wapas Index par](#index)

## 21. Idempotency

Idempotency ka matlab hai ke automation ko baar baar run karne par desired state maintain rahe aur bila-zaroorat changes na hon.

```yaml
- name: Ensure HTTPD is installed
  dnf:
    name: httpd
    state: present
```

```text
Pehli run  → Package missing hai → install → changed
Doosri run → Package mojood hai  → no change → ok
```

Task dobara bhi state check karta hai, lekin package ko bila-zaroorat reinstall nahi karta.

[Wapas Index par](#index)

## 22. Templates

Template aik dynamic text file hoti hai jo aam tor par `.j2` par khatam hoti hai aur variables ya Jinja2 expressions rakh sakti hai.

```html
<h1>Welcome to {{ inventory_hostname }}</h1>
```

```yaml
- name: Deploy website page
  template:
    src: index.html.j2
    dest: /var/www/html/index.html
    mode: "0644"
```

[Wapas Index par](#index)

## 23. Roles

Role reusable automation ko standard directory structure mein organize karta hai.

```text
roles/webserver/
├── defaults/main.yml
├── files/
├── handlers/main.yml
├── tasks/main.yml
├── templates/
└── vars/main.yml
```

```bash
ansible-galaxy role init roles/webserver
```

```yaml
- name: Configure web servers
  hosts: web
  become: true
  roles:
    - webserver
```

[Wapas Index par](#index)

## 24. Collections

Collection related modules, plugins, roles aur documentation ka package hota hai.

Built-in modules jaise `copy`, `file` aur `dnf` ko aap ki preference ke mutabiq short names se use kiya ja sakta hai. Kuch external modules ke liye pehle un ki collection install karni hoti hai.

```bash
ansible-galaxy collection list
ansible-galaxy collection install ansible.posix
```

[Wapas Index par](#index)

## 25. Ansible Vault

Ansible Vault passwords jaisi sensitive Ansible information ko encrypt karta hai.

```bash
ansible-vault create secrets.yml
ansible-vault edit secrets.yml
ansible-vault view secrets.yml
ansible-playbook site.yml --ask-vault-pass
```

Real passwords, private keys aur tokens ko Git mein unencrypted plaintext ki shakal mein kabhi store na karein.

[Wapas Index par](#index)

## 26. Verification commands

| Maqsad | Command |
|---|---|
| Ansible version aur config path check karna | `ansible --version` |
| Changed configuration dekhna | `ansible-config dump --only-changed` |
| Inventory graph dekhna | `ansible-inventory --graph` |
| Host variables dekhna | `ansible-inventory --host node1` |
| Connectivity test karna | `ansible all -m ping` |
| Playbook syntax check karna | `ansible-playbook --syntax-check playbook.yml` |
| Supported changes ka preview | `ansible-playbook --check --diff playbook.yml` |
| Target hosts list karna | `ansible-playbook playbook.yml --list-hosts` |
| Tasks list karna | `ansible-playbook playbook.yml --list-tasks` |
| Detailed troubleshooting | Command ke saath `-vvv` lagayein |

[Wapas Index par](#index)

## 27. Recommended learning order

```text
Control node aur managed nodes
            ↓
Inventory aur ansible.cfg
            ↓
Ad-hoc command syntax
            ↓
Modules, arguments aur state
            ↓
YAML
            ↓
Tasks, plays aur playbooks
            ↓
Variables aur facts
            ↓
Loops aur conditions
            ↓
Register aur debug
            ↓
Handlers aur templates
            ↓
Roles, collections aur Vault
```

Pehle inventory, configuration, ad-hoc commands, modules, arguments, state, tasks, plays, playbooks, variables aur facts par focus karein. Foundation clear hone ke baad loops, conditions, registered results, handlers, templates aur roles par jayein.

[Wapas Index par](#index)
