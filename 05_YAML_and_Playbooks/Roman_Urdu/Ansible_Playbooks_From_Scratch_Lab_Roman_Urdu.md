# Ansible Playbooks from Scratch - Roman Urdu Study Notes aur Hands-On Lab

<img src="./Ansible-Playbook -tructure-at-a-Glance.png" width="700">


Yeh guide YAML data types se shuru hoti hai, Ansible playbook ka complete structure samjhati hai, aur aapke Rocky Linux environment ke mutabiq safe hands-on labs provide karti hai.

Is guide mein aapki preference ke mutabiq short module names, jaise `file`, `copy`, `debug` aur `service`, use kiye gaye hain.

## Index

1. [Learning objectives](#1-learning-objectives)
2. [Lab environment](#2-lab-environment)
3. [Ansible playbook kya hai?](#3-ansible-playbook-kya-hai)
4. [Ad-hoc commands aur playbooks ka farq](#4-ad-hoc-commands-aur-playbooks-ka-farq)
5. [YAML ki bunyadi maloomat](#5-yaml-ki-bunyadi-maloomat)
6. [Playbooks mein use hone wale data types](#6-playbooks-mein-use-hone-wale-data-types)
7. [Playbook ka structure](#7-playbook-ka-structure)
8. [Playbook ko kaise parhein](#8-playbook-ko-kaise-parhein)
9. [Project tayyar karein](#9-project-tayyar-karein)
10. [Lab 1 - Pehla playbook](#10-lab-1---pehla-playbook)
11. [Lab 2 - Variables, lists, mappings, loops, facts aur conditions](#11-lab-2---variables-lists-mappings-loops-facts-aur-conditions)
12. [Playbook validate aur run karein](#12-playbook-validate-aur-run-karein)
13. [Play recap ko samjhein](#13-play-recap-ko-samjhein)
14. [Idempotency test karein](#14-idempotency-test-karein)
15. [Playbook execution ke useful options](#15-playbook-execution-ke-useful-options)
16. [Lab 3 - Handlers aur notifications](#16-lab-3---handlers-aur-notifications)
17. [Verification commands](#17-verification-commands)
18. [Cleanup playbook](#18-cleanup-playbook)
19. [Common mistakes aur troubleshooting](#19-common-mistakes-aur-troubleshooting)
20. [Practice assignment](#20-practice-assignment)
21. [Quick-reference tables](#21-quick-reference-tables)
22. [Suggested learning path](#22-suggested-learning-path)

---

## 1. Learning objectives

Is lab ko complete karne ke baad aap:

- Playbook, play, task, module, argument, variable, fact, condition, loop aur handler explain kar sakein ge.
- YAML ke common data types pehchan sakein ge.
- Sahi indentation ke sath YAML playbook likh sakein ge.
- Playbook se inventory group target kar sakein ge.
- Run karne se pehle playbook validate kar sakein ge.
- Check mode aur diff mode use kar sakein ge.
- Playbook run karke uska result verify kar sakein ge.
- Playbook ki idempotency test kar sakein ge.
- Lab mein create ki hui cheezein cleanup playbook se remove kar sakein ge.

---

## 2. Lab environment

Yeh notes aapke is environment ke mutabiq hain:

| Component | Value |
|---|---|
| Control node | `ansible-server.nitclasses.com` |
| Control-node user | `ansibleadmin` |
| Project directory | `/home/ansibleadmin/automation` |
| Inventory source | `/home/ansibleadmin/automation/inventory` |
| Managed-node group | `three_tier_app` |
| Managed nodes | `node1`, `node2` aur `node3` |
| Operating system | Rocky Linux 9 |
| Remote user | `ansibleadmin` |
| Python interpreter | `/usr/bin/python3` |

Example inventory:

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

Example project-level `ansible.cfg`:

```ini
[defaults]
inventory = ./inventory
host_key_checking = False
remote_user = ansibleadmin
ask_pass = False
private_key_file = /home/ansibleadmin/.ssh/ansible-key

[privilege_escalation]
become_method = sudo
become_user = root
become_ask_pass = False
```

> Commands `/home/ansibleadmin/automation` directory se run karein, taa-ke Ansible project-level `ansible.cfg` ko discover kar sake.

---

## 3. Ansible playbook kya hai?

Ansible playbook ek YAML file hoti hai jo repeatable automation ko describe karti hai. Yeh Ansible ko batati hai:

- kin hosts ko manage karna hai;
- kaun se tasks perform karne hain;
- kaun se modules use karne hain;
- modules ko kaun se arguments aur variables dene hain;
- root privileges ki zarurat hai ya nahi;
- aur system ki desired final state kya honi chahiye.

Playbook file ke naam ke end par aam tor par `.yml` ya `.yaml` extension hoti hai.

Example:

```text
site.yml
```

### One-line definition

> Ansible playbook ek YAML file hai jisme managed nodes par perform hone wale plays aur tasks likhe jate hain.

---

## 4. Ad-hoc commands aur playbooks ka farq

| Ad-hoc command | Playbook |
|---|---|
| Quick ya one-time task run karti hai | Reusable automation file mein save karta hai |
| Aam tor par ek module invocation hota hai | Multiple tasks aur plays ho sakte hain |
| Testing aur troubleshooting ke liye useful hai | Repeatable work ke liye behtar hai |
| Complete workflow document karna mushkil hota hai | Names, variables, loops, conditions, tags aur handlers rakh sakta hai |
| Example: `ansible all -m ping` | Example: `ansible-playbook site.yml` |

Quick operation ke liye ad-hoc command use karein. Agar kaam repeat, review, share ya version control mein save karna ho to playbook use karein.

---

## 5. YAML ki bunyadi maloomat

YAML ek human-readable data-serialization language hai. Ansible isay plays, tasks, variables aur module arguments define karne ke liye use karta hai.

### Important YAML rules

1. Indentation ke liye spaces use karein; tabs use na karein.
2. Ek hi level ki lines ko barabar align karein.
3. `key: value` mein colon ke baad ek space dein.
4. Hyphen aur uske baad space, yani `- `, list item start karta hai.
5. YAML case-sensitive hai.
6. Comment `#` se start hota hai.
7. Special characters wali ya confusing values ko quotes mein rakhein.
8. Boolean ke liye `true` aur `false` ko preference dein.
9. `---` YAML document ke start ko show karta hai; Ansible ke liye lazmi nahi lekin recommended hai.
10. `...` YAML document ke end ko show kar sakta hai, lekin aam tor par use nahi hota.

Sahi indentation:

```yaml
tasks:
  - name: Create a directory
    file:
      path: /tmp/example
      state: directory
```

Ghalat indentation:

```yaml
tasks:
- name: Create a directory
  file:
  path: /tmp/example
    state: directory
```

YAML mein indentation sirf decoration nahi hai. Is se parent-child relationship define hota hai.

---

## 6. Playbooks mein use hone wale data types

### 6.1 String

String text value hoti hai.

```yaml
course_name: Ansible Fundamentals
lab_directory: /tmp/ansible-playbook-lab
```

Agar value mein special character ho to quotes use karna behtar hai:

```yaml
message: "Welcome: this file was managed by Ansible"
```

### 6.2 Integer

Integer whole number hota hai.

```yaml
student_count: 25
file_mode_decimal: 644
```

File mode ko quotes mein rakhna chahiye taa-ke YAML usay kisi aur number format mein interpret na kare:

```yaml
mode: "0644"
```

### 6.3 Floating-point number

Decimal number ko floating-point value kehte hain.

```yaml
course_version: 1.5
```

### 6.4 Boolean

Boolean `true` ya `false` ko represent karta hai.

```yaml
become: true
gather_facts: false
```

`yes`, `no`, `on` aur `off` ki jagah `true` aur `false` use karna zyada clear hai, kyun ke mukhtalif YAML parsers purane words ko mukhtalif tareeqe se interpret kar sakte hain.

### 6.5 Null value

Null ka matlab hai ke koi value assign nahi ki gayi.

```yaml
optional_value: null
```

### 6.6 List

List ordered values ka collection hoti hai. Har item `-` se start hota hai.

```yaml
lab_files:
  - introduction.txt
  - inventory.txt
  - facts.txt
```

Inline format bhi mumkin hai:

```yaml
lab_files: [introduction.txt, inventory.txt, facts.txt]
```

Block format aam tor par zyada readable hota hai.

### 6.7 Mapping ya dictionary

Mapping key-value pairs ko store karti hai.

```yaml
file_settings:
  owner: ansibleadmin
  group: ansibleadmin
  mode: "0644"
```

Yahan `file_settings` parent key hai aur `owner`, `group` aur `mode` uske andar child keys hain.

### 6.8 List of mappings

Jab har list item ki multiple properties hon to list of mappings use hoti hai.

```yaml
managed_files:
  - name: introduction.txt
    content: "Ansible playbook lab"
  - name: inventory.txt
    content: "Inventory host information"
```

Yeh loops mein bohat common format hai.

### 6.9 Variables aur Jinja expressions

Variable ki value read karne ke liye double curly braces use hote hain:

```yaml
path: "{{ lab_directory }}"
```

Agar Jinja expression value ke start par ho to poori value ko quote karein:

```yaml
content: "{{ lab_message }}"
```

---

## 7. Playbook ka structure

Relationship ko is tarah samjhein:

```text
Playbook
  -> ek ya zyada plays
      -> host pattern aur play-level settings
      -> ek ya zyada tasks
          -> har task mein aam tor par ek module
              -> module ke arguments
```

### Main terms

| Term | Meaning |
|---|---|
| Playbook | YAML file jisme ek ya zyada plays hote hain |
| Play | Tasks ka set jo kisi host ya group pattern par apply hota hai |
| `name` | Play, task ya handler ki readable description |
| `hosts` | Inventory host ya group jisko play target karta hai |
| `gather_facts` | Managed nodes ke facts automatically collect karne ko control karta hai |
| `become` | Aam tor par `sudo` ke zariye privilege escalation enable karta hai |
| `vars` | Play ke variables define karta hai |
| `tasks` | Actions ki ordered list |
| Task | Automation ka ek named unit of work |
| Module | Ansible ka unit of work, jaise `file`, `copy` ya `service` |
| Module arguments | Module ko diye gaye options, jaise `path` aur `state` |
| `loop` | Ek task ko multiple items ke liye repeat karta hai |
| `when` | Task ko sirf condition true hone par run karta hai |
| `register` | Task ka result variable mein save karta hai |
| `notify` | Task change hone par handler ko request karta hai |
| `handlers` | Special tasks jo notification milne par run hote hain |
| `tags` | Playbook ke selected parts run ya skip karne ke labels |

### Skeleton playbook

```yaml
---
- name: Descriptive name of the play
  hosts: three_tier_app
  become: false
  gather_facts: true

  vars:
    example_variable: example value

  tasks:
    - name: Descriptive name of the task
      debug:
        msg: "{{ example_variable }}"

  handlers:
    - name: Example handler
      debug:
        msg: Handler executed
```

Important: Keyword `tasks` aur `handlers` plural hote hain.

---

## 8. Playbook ko kaise parhein

Is example ko dekhein:

```yaml
---
- name: Create a lab directory
  hosts: three_tier_app
  become: false
  gather_facts: false

  tasks:
    - name: Ensure the lab directory exists
      file:
        path: /tmp/ansible-playbook-lab
        state: directory
        mode: "0755"
```

Isay upar se neeche is tarah parhein:

1. `---` YAML document start karta hai.
2. Pehla `-` ek play start karta hai, kyun ke playbook plays ki list hota hai.
3. `name` play ki readable description hai.
4. `hosts` inventory ke `three_tier_app` group ko target karta hai.
5. `become: false` ka matlab task root privileges request nahi kare ga.
6. `gather_facts: false` automatic fact gathering ko skip karta hai.
7. `tasks` ordered task list start karta hai.
8. Doosra `- name` ek task start karta hai.
9. `file` task ka module hai.
10. `path`, `state` aur `mode`, `file` module ke arguments hain.
11. `state: directory` desired state batata hai ke directory exist karni chahiye.

### Playbook execution flow

1. Ansible inventory load karta hai.
2. `hosts` pattern se targets select karta hai.
3. Zarurat ho to facts collect karta hai.
4. Tasks ko upar se neeche order mein run karta hai.
5. Change wali tasks handlers ko notify kar sakti hain.
6. Aam tor par notified handlers play ke end mein run hote hain.
7. Ansible aakhir mein play recap show karta hai.

---

## 9. Project tayyar karein

Project directory mein jayein:

```bash
cd /home/ansibleadmin/automation
```

Active configuration file confirm karein:

```bash
ansible --version
```

Configured inventory confirm karein:

```bash
ansible-inventory --graph
```

Confirm karein ke target group mein expected nodes hain:

```bash
ansible three_tier_app --list-hosts
```

Connectivity test karein:

```bash
ansible three_tier_app -m ping
```

Playbooks ke liye directory banayein:

```bash
mkdir -p playbooks
```

Expected structure:

```text
automation/
├── ansible.cfg
├── inventory/
│   └── nodes
└── playbooks/
```

---

## 10. Lab 1 - Pehla playbook

File create karein:

```bash
vim playbooks/01-first-playbook.yml
```

Yeh content add karein:

```yaml
---
- name: First Ansible playbook
  hosts: three_tier_app
  gather_facts: false

  tasks:
    - name: Test Ansible connectivity
      ping:

    - name: Display a message
      debug:
        msg: "Hello from Ansible on {{ inventory_hostname }}"
```

Yeh playbook managed nodes par permanent change nahi karta. `ping` module Ansible connectivity aur Python execution test karta hai. `debug` module message display karta hai.

Syntax validate karein:

```bash
ansible-playbook playbooks/01-first-playbook.yml --syntax-check
```

Playbook run karein:

```bash
ansible-playbook playbooks/01-first-playbook.yml
```

Har node ke liye `pong` aur uska inventory hostname nazar aana chahiye.

---

## 11. Lab 2 - Variables, lists, mappings, loops, facts aur conditions

File create karein:

```bash
vim playbooks/02-playbook-fundamentals-lab.yml
```

Yeh content add karein:

```yaml
---
- name: Practice Ansible playbook fundamentals
  hosts: three_tier_app
  become: false
  gather_facts: true

  vars:
    lab_directory: /tmp/ansible-playbook-lab
    lab_owner: ansibleadmin
    lab_group: ansibleadmin
    lab_mode: "0755"
    course_title: Ansible Playbook Fundamentals
    managed_files:
      - name: introduction.txt
        description: This file introduces the playbook lab.
      - name: inventory-host.txt
        description: This file records the Ansible inventory hostname.
      - name: operating-system.txt
        description: This file records selected operating-system facts.

  tasks:
    - name: Display the current managed node
      debug:
        msg: "Running on {{ inventory_hostname }} at {{ ansible_host }}"

    - name: Ensure the lab directory exists
      file:
        path: "{{ lab_directory }}"
        state: directory
        owner: "{{ lab_owner }}"
        group: "{{ lab_group }}"
        mode: "{{ lab_mode }}"

    - name: Create files from a list of mappings
      copy:
        content: |
          Course: {{ course_title }}
          Host: {{ inventory_hostname }}
          Purpose: {{ item.description }}
        dest: "{{ lab_directory }}/{{ item.name }}"
        owner: "{{ lab_owner }}"
        group: "{{ lab_group }}"
        mode: "0644"
      loop: "{{ managed_files }}"

    - name: Store operating-system facts in a file
      copy:
        content: |
          Hostname: {{ ansible_hostname }}
          Distribution: {{ ansible_distribution }}
          Version: {{ ansible_distribution_version }}
          Architecture: {{ ansible_architecture }}
          Default IPv4: {{ ansible_default_ipv4.address | default('not available') }}
        dest: "{{ lab_directory }}/facts.txt"
        owner: "{{ lab_owner }}"
        group: "{{ lab_group }}"
        mode: "0644"
      when: ansible_os_family == "RedHat"

    - name: Inspect the lab directory
      command: "ls -la {{ lab_directory }}"
      register: lab_listing
      changed_when: false

    - name: Display the saved command output
      debug:
        var: lab_listing.stdout_lines
```

### Is playbook mein kya demonstrate hua?

| Feature | Example aur explanation |
|---|---|
| String variable | `course_title` mein text save hai |
| List | `managed_files` multiple items rakhti hai |
| Mapping | Har item ke andar `name` aur `description` keys hain |
| Variable expression | `{{ lab_directory }}` variable ki value read karta hai |
| Loop | `loop: "{{ managed_files }}"` har item ke liye task repeat karta hai |
| Current loop item | `item.name` aur `item.description` current item ko access karte hain |
| Facts | `ansible_distribution` aur `ansible_hostname` remote system ki maloomat hain |
| Condition | `when` task ko sirf Red Hat family par chalata hai |
| Registered result | `register` command ka result `lab_listing` mein save karta hai |
| Debug output | `lab_listing.stdout_lines` output ko line-by-line show karta hai |
| Idempotency correction | Read-only command par `changed_when: false` false change report ko rokta hai |

### `inventory_hostname` aur `ansible_host`

- `inventory_hostname` woh naam hai jo inventory mein host ke liye likha gaya hai, jaise `node1`.
- `ansible_host` actual address hai jahan Ansible connect karta hai, jaise `192.168.1.154`.

### Facts kahan se aate hain?

`gather_facts: true` ki wajah se play ke start mein Ansible `setup` module ke zariye managed node ki system information collect karta hai.

---

## 12. Playbook validate aur run karein

### Step 1: YAML aur Ansible syntax check karein

```bash
ansible-playbook playbooks/02-playbook-fundamentals-lab.yml --syntax-check
```

Yeh playbook ka structure check karta hai. Syntax check pass hona yeh guarantee nahi karta ke har task runtime par bhi successful hoga.

### Step 2: Target hosts list karein

```bash
ansible-playbook playbooks/02-playbook-fundamentals-lab.yml --list-hosts
```

Expected hosts: `node1`, `node2` aur `node3`.

### Step 3: Tasks list karein

```bash
ansible-playbook playbooks/02-playbook-fundamentals-lab.yml --list-tasks
```

### Step 4: Changes ka preview dekhein

```bash
ansible-playbook playbooks/02-playbook-fundamentals-lab.yml --check --diff
```

- `--check` simulation ya dry-run ki koshish karta hai.
- `--diff` supported modules ke liye before aur after difference show karta hai.

Check mode har module ke liye complete support nahi rakhta. Isay guarantee ke bajaye useful preview samjhein.

### Step 5: Actual playbook run karein

```bash
ansible-playbook playbooks/02-playbook-fundamentals-lab.yml
```

### Step 6: Extra detail ke sath run karein

```bash
ansible-playbook playbooks/02-playbook-fundamentals-lab.yml -v
```

Troubleshooting ke liye zarurat ke mutabiq `-vv`, `-vvv` ya `-vvvv` use kiya ja sakta hai.

---

## 13. Play recap ko samjhein

Example:

```text
PLAY RECAP
node1 : ok=7 changed=2 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

| Field | Meaning |
|---|---|
| `ok` | Successfully complete hui tasks; changed tasks bhi `ok` total mein shamil hoti hain |
| `changed` | Tasks jinhon ne managed-node state change report ki |
| `unreachable` | Ansible host se connect nahi kar saka |
| `failed` | Connection ke baad koi task fail hui |
| `skipped` | Condition ya selection ki wajah se task run nahi hui |
| `rescued` | Failed task ko `rescue` section ne handle kiya |
| `ignored` | Failure hui lekin play ko continue karne diya gaya |

`changed=2` error nahi hota. Iska matlab do tasks ne required changes perform kiye.

---

## 14. Idempotency test karein

Idempotency ka matlab hai ke desired state achieve hone ke baad same automation dobara run karne par unnecessary changes na hon.

Playbook doosri baar run karein:

```bash
ansible-playbook playbooks/02-playbook-fundamentals-lab.yml
```

Doosri run par aam tor par yeh result aana chahiye:

```text
changed=0
```

Is lab ki idempotency ki wajah:

- `file` directory ko sirf us waqt change karta hai jab state ya properties different hon.
- `copy` file ko sirf us waqt change karta hai jab content ya properties different hon.
- Read-only `command` task par `changed_when: false` laga hua hai.

Har module naturally idempotent nahi hota. `command`, `shell` aur `raw` modules aam tor par desired state khud determine nahi karte, is liye run hone par `CHANGED` report kar sakte hain.

---

## 15. Playbook execution ke useful options

### Sirf ek node par run karein

```bash
ansible-playbook playbooks/02-playbook-fundamentals-lab.yml --limit node1
```

Playbook ka `hosts` allowed target pattern define karta hai. `--limit node1` current execution ko us pattern ke andar sirf `node1` tak restrict karta hai.

### Har task se pehle confirmation lein

```bash
ansible-playbook playbooks/02-playbook-fundamentals-lab.yml --step
```

### Kisi named task se execution start karein

```bash
ansible-playbook playbooks/02-playbook-fundamentals-lab.yml \
  --start-at-task "Store operating-system facts in a file"
```

Task ka naam exactly match hona chahiye.

### Sudo password poochna ho

```bash
ansible-playbook playbooks/example.yml --ask-become-pass
```

### Different inventory explicitly dena ho

```bash
ansible-playbook -i ./inventory/nodes playbooks/01-first-playbook.yml
```

Agar project directory ke `ansible.cfg` mein `inventory = ./inventory` defined hai to project directory se command chalate waqt `-i` dena zaroori nahi.

---

## 16. Lab 3 - Handlers aur notifications

Handler ek special task hai jo aam tor par tabhi run hota hai jab koi task change report karke usay notify kare. Configuration change ke baad service restart ya reload karna handler ka common use case hai.

Is introductory lab mein service restart karne ke bajaye safe files use ki gayi hain.

File create karein:

```bash
vim playbooks/03-handler-demo.yml
```

Content:

```yaml
---
- name: Demonstrate notifications and handlers
  hosts: three_tier_app
  gather_facts: false

  vars:
    lab_directory: /tmp/ansible-playbook-lab

  tasks:
    - name: Ensure the lab directory exists
      file:
        path: "{{ lab_directory }}"
        state: directory
        mode: "0755"

    - name: Manage the demonstration configuration
      copy:
        content: |
          training_mode=enabled
          managed_by=ansible
        dest: "{{ lab_directory }}/demo.conf"
        mode: "0644"
      notify: Create handler marker

  handlers:
    - name: Create handler marker
      copy:
        content: "The configuration task notified this handler.\n"
        dest: "{{ lab_directory }}/handler-ran.txt"
        mode: "0644"
```

Do baar run karein:

```bash
ansible-playbook playbooks/03-handler-demo.yml
ansible-playbook playbooks/03-handler-demo.yml
```

Pehli run mein:

1. `demo.conf` create hoti hai.
2. `copy` task change report karti hai.
3. Task `Create handler marker` ko notify karti hai.
4. Handler `handler-ran.txt` create karta hai.

Doosri run mein configuration unchanged hoti hai, is liye task handler ko notify nahi karti.

Production example mein handler `service` ya `systemd` module se service restart kar sakta hai. Is beginner lab mein accidental service interruption se bachne ke liye restart use nahi kiya gaya.

---

## 17. Verification commands

Sab managed nodes par directory list karein:

```bash
ansible three_tier_app -m command \
  -a "ls -la /tmp/ansible-playbook-lab"
```

Facts file display karein:

```bash
ansible three_tier_app -m command \
  -a "cat /tmp/ansible-playbook-lab/facts.txt"
```

Handler marker display karein:

```bash
ansible three_tier_app -m command \
  -a "cat /tmp/ansible-playbook-lab/handler-ran.txt"
```

Yahan `command` module sahi choice hai, kyun ke pipe, redirection, wildcard expansion ya kisi aur shell feature ki zarurat nahi.

---

## 18. Cleanup playbook

File create karein:

```bash
vim playbooks/99-cleanup-playbook-lab.yml
```

Content:

```yaml
---
- name: Remove files created by the playbook lab
  hosts: three_tier_app
  gather_facts: false

  tasks:
    - name: Ensure the lab directory is absent
      file:
        path: /tmp/ansible-playbook-lab
        state: absent
```

Cleanup ka preview dekhein:

```bash
ansible-playbook playbooks/99-cleanup-playbook-lab.yml --check --diff
```

Actual cleanup run karein:

```bash
ansible-playbook playbooks/99-cleanup-playbook-lab.yml
```

Verify karein:

```bash
ansible three_tier_app -m stat \
  -a "path=/tmp/ansible-playbook-lab"
```

Output mein yeh dekhein:

```text
"exists": false
```

Cleanup playbook dobara run karein. Ab `changed=0` aana chahiye, kyun ke directory pehle hi absent hai. Yeh bhi idempotency hai.

---

## 19. Common mistakes aur troubleshooting

### YAML syntax error

Possible causes:

- indentation ghalat hai;
- tab use hui hai;
- colon missing hai;
- list item ke start par `-` missing hai;
- special value quote nahi ki gayi.

Check karein:

```bash
ansible-playbook playbooks/02-playbook-fundamentals-lab.yml --syntax-check
```

### `conflicting action statements`

Aam tor par ek task mein sirf ek module invoke hota hai. Yeh invalid hai:

```yaml
- name: Invalid task
  file:
    path: /tmp/example
    state: directory
  copy:
    content: example
    dest: /tmp/example/file.txt
```

`file` aur `copy` ke liye do separate tasks banayein.

### `no hosts matched`

Group name aur inventory check karein:

```bash
ansible-inventory --graph
ansible three_tier_app --list-hosts
```

### Host `UNREACHABLE` hai

Pehle direct SSH test karein, phir Ansible verbosity use karein:

```bash
ssh -i /home/ansibleadmin/.ssh/ansible-key ansibleadmin@node1
ansible node1 -m ping -vvvv
```

### `Permission denied`

Task ko privilege escalation chahiye ho sakti hai. Jab root access genuinely required ho to play level par add karein:

```yaml
become: true
```

Agar sudo password required ho:

```bash
ansible-playbook playbooks/example.yml --ask-become-pass
```

### Variable undefined hai

Variable ka spelling aur scope check karein. Agar fact use ho raha hai to confirm karein:

```yaml
gather_facts: true
```

### Read-only command `CHANGED` show karti hai

`command` aur `shell` modules aam tor par sirf yeh jaante hain ke command run hui hai; woh system ki desired state automatically compare nahi karte. Truly read-only task par use karein:

```yaml
changed_when: false
```

### `--check` har cheez predict nahi karta

Check mode ka result module support par depend karta hai. Safe process yeh hai:

1. Syntax check karein.
2. Hosts aur tasks list karein.
3. Check mode use karein.
4. Pehle lab ya limited host par actual run karein.
5. Result verify karein.
6. Dobara run karke idempotency check karein.

---

## 20. Practice assignment

`playbooks/04-student-practice.yml` create karein jo:

1. `three_tier_app` ko target kare.
2. Fact gathering enable kare.
3. `/tmp/student-playbook-practice` ko variable mein define kare.
4. Directory mode `0755` ke sath create kare.
5. Loop se yeh teen empty files create kare:
   - `node.txt`
   - `os.txt`
   - `memory.txt`
6. `inventory_hostname` aur `ansible_host` ko `node.txt` mein likhe.
7. Distribution name aur version ko `os.txt` mein likhe.
8. `ansible_memtotal_mb` ko `memory.txt` mein likhe.
9. Condition use kare taa-ke file-writing tasks sirf Red Hat OS family par run hon.
10. `ls -la /tmp/student-playbook-practice` ka output register kare.
11. Registered `stdout_lines` ko `debug` se display kare.
12. Doosri run par `changed=0` produce kare.
13. Separate cleanup playbook bhi banaye.

Required evidence:

```bash
ansible-playbook playbooks/04-student-practice.yml --syntax-check
ansible-playbook playbooks/04-student-practice.yml --check --diff
ansible-playbook playbooks/04-student-practice.yml
ansible-playbook playbooks/04-student-practice.yml
```

Dono actual runs ka play recap document karein aur explain karein ke second run par changes kyun nahi honi chahiye.

---

## 21. Quick-reference tables

### Common desired-state values

| Value | Aam meaning |
|---|---|
| `present` | Package, user ya doosra resource exist karna chahiye |
| `absent` | Resource exist nahi karna chahiye |
| `latest` | Package repository ka newest available version installed hona chahiye |
| `directory` | Path directory ki form mein exist karna chahiye |
| `file` | Path regular file hona chahiye; exact behavior module par depend karta hai |
| `touch` | File absent ho to create aur present ho to timestamps update karta hai |
| `started` | Service running honi chahiye |
| `stopped` | Service running nahi honi chahiye |
| `restarted` | Task run hone par service restart hoti hai |
| `reloaded` | Task run hone par service configuration reload hoti hai |

Har module ke accepted `state` values different ho sakte hain. Documentation check karein:

```bash
ansible-doc file
ansible-doc copy
ansible-doc service
```

### Beginner playbook practice ke common modules

| Module | Purpose |
|---|---|
| `ping` | Ansible connectivity aur Python execution test karta hai |
| `debug` | Message ya variable value display karta hai |
| `file` | Files, directories, links, permissions aur absence manage karta hai |
| `copy` | Local file copy ya managed text file create karta hai |
| `lineinfile` | Text file ki specific line manage karta hai |
| `command` | Shell ke baghair command run karta hai |
| `shell` | Jab pipe ya redirection jaise shell features chahiye hon to command shell se run karta hai |
| `dnf` | Rocky Linux 9 ke packages manage karta hai |
| `service` | Services ko portable tareeqe se manage karta hai |
| `systemd` | Systemd services aur units manage karta hai |
| `uri` | HTTP ya HTTPS request bhejta hai |
| `stat` | Path ki information check karta hai, usay change nahi karta |
| `setup` | Managed-node facts gather karta hai |

### Recommended validation sequence

```bash
ansible-inventory --graph
ansible three_tier_app -m ping
ansible-playbook playbooks/example.yml --syntax-check
ansible-playbook playbooks/example.yml --list-hosts
ansible-playbook playbooks/example.yml --list-tasks
ansible-playbook playbooks/example.yml --check --diff
ansible-playbook playbooks/example.yml
ansible-playbook playbooks/example.yml
```

Is sequence ka maqsad:

1. Inventory structure check karna.
2. Connectivity test karna.
3. Syntax validate karna.
4. Target hosts confirm karna.
5. Tasks review karna.
6. Possible changes preview karna.
7. Actual execution karna.
8. Second run se idempotency test karna.

---

## 22. Suggested learning path

Foundation lab ke baad topics is order mein parhein:

1. Variables aur variable precedence
2. Facts aur custom facts
3. Loops
4. Conditions
5. Registered results
6. Handlers aur notifications
7. Tags
8. Blocks, rescue aur always
9. Jinja2 templates
10. Task imports aur includes
11. Roles
12. Collections
13. Ansible Vault
14. Verbosity ke sath troubleshooting

Yeh order basic syntax se reusable aur production-oriented automation ki taraf le jata hai.

---

## Final summary

- Playbook ek YAML list hai jisme ek ya zyada plays hote hain.
- Play inventory hosts ko target karta hai aur ordered tasks rakhta hai.
- Ek task aam tor par ek module ko uske arguments ke sath invoke karta hai.
- Variables reusable values store karte hain.
- Lists aur mappings structured data organize karti hain.
- Loops tasks repeat karte hain.
- Conditions execution control karti hain.
- Handlers changes ke response mein run hote hain.
- Run se pehle syntax validate karein aur check mode ko carefully use karein.
- Result verify karein aur playbook dobara run karke idempotency test karein.
- Repeatable practice ke liye cleanup playbook zaroor rakhein.
