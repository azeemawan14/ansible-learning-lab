# YAML aur Ansible Playbook Basics — Roman Urdu Study Notes

> Yeh notes YAML ki basic structure aur Ansible playbook ko parent, child, mapping, list aur indentation ke zariye samajhne ke liye tayyar kiye gaye hain.

---

## Index

1. [Learning objectives](#1-learning-objectives)
2. [YAML kya hai?](#2-yaml-kya-hai)
3. [YAML ke bunyadi rules](#3-yaml-ke-bunyadi-rules)
4. [Key aur value](#4-key-aur-value)
5. [Parent aur child keys](#5-parent-aur-child-keys)
6. [Mapping ya dictionary](#6-mapping-ya-dictionary)
7. [Sequence ya list](#7-sequence-ya-list)
8. [Mapping aur list mein farq](#8-mapping-aur-list-mein-farq)
9. [Scalar values](#9-scalar-values)
10. [Nested data structure](#10-nested-data-structure)
11. [Multiline text: pipe aur greater-than](#11-multiline-text-pipe-aur-greater-than)
12. [Ansible playbook kya hai?](#12-ansible-playbook-kya-hai)
13. [Playbook ke important components](#13-playbook-ke-important-components)
14. [Module ki value blank kyun nazar aati hai?](#14-module-ki-value-blank-kyun-nazar-aati-hai)
15. [Complete playbook example](#15-complete-playbook-example)
16. [Complete example ka parent-child structure](#16-complete-example-ka-parent-child-structure)
17. [Ansible variables](#17-ansible-variables)
18. [File permissions ko quotes mein kyun likhein?](#18-file-permissions-ko-quotes-mein-kyun-likhein)
19. [Playbook validation aur safe testing](#19-playbook-validation-aur-safe-testing)
20. [Idempotency](#20-idempotency)
21. [Common mistakes](#21-common-mistakes)
22. [Quick-reference table](#22-quick-reference-table)
23. [Practice exercises](#23-practice-exercises)
24. [Quick revision summary](#24-quick-revision-summary)

---

## 1. Learning objectives

In notes ko parhne ke baad aap:

- YAML indentation ko samajh sakein ge.
- Parent aur child keys identify kar sakein ge.
- Mapping aur list mein farq kar sakein ge.
- Scalar aur nested values ko pehchan sakein ge.
- Ansible play, task, module aur arguments samajh sakein ge.
- Basic Ansible playbook likh aur validate kar sakein ge.

[Back to Index](#index)

---

## 2. YAML kya hai?

**YAML** ka recursive full form hai:

> **YAML Ain't Markup Language**

YAML ek human-readable **data-serialization format** hai. Iska matlab hai ke YAML data ko structured form mein likhne aur applications ke darmiyan represent karne ka tareeqa provide karta hai.

Ansible YAML ko playbooks likhne ke liye use karta hai. YAML khud automation tool ya programming language nahi hai.

### Simple relationship

| Component | Kaam |
|---|---|
| Ansible | Automation engine |
| Inventory | Managed nodes identify karta hai |
| Playbook | Automation instructions rakhta hai |
| YAML | Instructions ko structured format deta hai |

[Back to Index](#index)

---

## 3. YAML ke bunyadi rules

### Rule 1: Indentation spaces se karein

```yaml
student:
  name: Khalid
  course: Ansible
```

`name` aur `course` ke shuru mein do spaces hain. Yeh spaces batati hain ke dono keys `student` ke neeche belong karti hain.

### Rule 2: Tabs use na karein

YAML mein tabs parsing errors ka sabab ban sakti hain. Hamesha spaces use karein.

### Rule 3: Same level par same indentation

```yaml
student:
  name: Khalid
  course: Ansible
```

`name` aur `course` ek hi level par hain, is liye dono ki indentation same hai.

### Rule 4: Colon ke baad space

Sahi:

```yaml
name: Khalid
```

Ghalat:

```yaml
name:Khalid
```

### Rule 5: List item hyphen se shuru hota hai

```yaml
packages:
  - git
  - curl
  - tree
```

### One-line definition

> **Indentation line ke shuru mein spaces hoti hain jo YAML ka structure aur parent-child relationship dikhati hain.**

[Back to Index](#index)

---

## 4. Key aur value

YAML mein data aam tor par `key: value` form mein hota hai.

```yaml
course: Ansible
```

- `course` = key
- `Ansible` = value
- `:` = key aur value ko separate karta hai

Ek aur example:

```yaml
state: present
```

- `state` key hai.
- `present` value hai.

[Back to Index](#index)

---

## 5. Parent aur child keys

### Definition

- **Parent key:** Aisi key jiske neeche indented data ho.
- **Child key:** Parent ke neeche indented key.

### Example

```yaml
student:
  name: Khalid
  course: Ansible
```

Structure:

```text
student (parent)
├── name (child) → Khalid (value)
└── course (child) → Ansible (value)
```

### Important point

Ek key ek level par child aur aglay level par parent bhi ho sakti hai.

```yaml
students:
  student1:
    name: Khalid
    course: Ansible
```

Yahan:

- `students` main parent hai.
- `student1`, `students` ka child hai.
- `student1`, `name` aur `course` ka parent bhi hai.

[Back to Index](#index)

---

## 6. Mapping ya dictionary

Mapping key-value pairs ka collection hoti hai.

```yaml
student:
  name: Khalid
  course: Ansible
```

Yeh ek nested mapping hai. Is mein hyphens nahi hain.

### Mapping ka sawal

Mapping yeh batati hai:

> Kaunsi value kis key ke saath belong karti hai?

### Ansible example

```yaml
file:
  path: /tmp/yaml-study-lab
  state: directory
  mode: "0755"
```

- `file` parent aur Ansible module hai.
- `path`, `state` aur `mode` uske child arguments hain.

[Back to Index](#index)

---

## 7. Sequence ya list

Sequence ordered items ka collection hoti hai. Har list item hyphen (`-`) se shuru hota hai.

```yaml
packages:
  - git
  - curl
  - tree
```

Yahan:

- `packages` parent key hai.
- `git`, `curl` aur `tree` list items hain.

### Ansible module example

```yaml
dnf:
  name:
    - git
    - curl
    - tree
  state: present
```

Structure:

```text
dnf (parent/module)
├── name (child/argument)
│   ├── git  (list item)
│   ├── curl (list item)
│   └── tree (list item)
└── state (child/argument) → present (value)
```

[Back to Index](#index)

---

## 8. Mapping aur list mein farq

| Feature | Mapping | List/Sequence |
|---|---|---|
| Purpose | Key ko value se associate karti hai | Ordered items rakhti hai |
| Common syntax | `key: value` | `- item` |
| Example | `name: Khalid` | `- git` |
| Order | Key-value relationship important | Items ka order preserved hota hai |

### Mapping-based students

```yaml
students:
  student1:
    name: Khalid
    course: Ansible
  student2:
    name: Ahmed
    course: Linux
```

Yahan `student1` aur `student2` keys hain; yeh list items nahi hain.

### List-based students

```yaml
students:
  - name: Khalid
    course: Ansible
  - name: Ahmed
    course: Linux
```

Yahan har hyphen ek naya student list item shuru karta hai.

[Back to Index](#index)

---

## 9. Scalar values

Scalar ek single value hoti hai.

| Scalar type | Example |
|---|---|
| String | `Ansible` |
| Integer | `200` |
| Boolean | `true` ya `false` |
| Null | `null` |

Example:

```yaml
course: Ansible
gather_facts: false
port: 80
```

- `Ansible`, `false` aur `80` scalar values hain.

[Back to Index](#index)

---

## 10. Nested data structure

Jab mapping ya list kisi doosri mapping ya list ke andar ho to use nested structure kehte hain.

```yaml
department:
  students:
    - name: Khalid
      course: Ansible
    - name: Ahmed
      course: Linux
```

Is example mein:

- `department` ke andar `students` hai.
- `students` ki value ek list hai.
- Har list item khud ek mapping hai.

[Back to Index](#index)

---

## 11. Multiline text: pipe aur greater-than

### Pipe `|`

Pipe multiline text ki line breaks preserve karta hai.

```yaml
content: |
  YAML is a data format.
  Ansible uses YAML to structure playbooks.
```

Result mein dono lines alag rahengi.

### Greater-than `>`

Greater-than folded multiline string banata hai. Aam line breaks ko spaces mein convert kar deta hai.

```yaml
message: >
  This is a long
  message written on
  multiple YAML lines.
```

Result aam tor par ek continuous line ki tarah hota hai.

| Symbol | Behavior |
|---|---|
| `|` | Line breaks preserve karta hai |
| `>` | Lines ko fold karke spaces ke saath join karta hai |

[Back to Index](#index)

---

## 12. Ansible playbook kya hai?

Ansible playbook ek YAML file hoti hai jismein automation instructions likhi hoti hain.

Playbook specify karta hai:

1. Automation kin hosts par chalegi.
2. Privilege escalation chahiye ya nahi.
3. Facts gather karne hain ya nahi.
4. Kaun se tasks kis order mein execute honge.

### One-line definition

> **Ansible playbook YAML mein likhi hui repeatable automation instructions ka collection hai.**

[Back to Index](#index)

---

## 13. Playbook ke important components

| Term | Definition | Example |
|---|---|---|
| Playbook | Ek ya zyada plays ki YAML file | `site.yml` |
| Play | Hosts ko tasks ke saath connect karta hai | `- name: Configure servers` |
| `name` | Play ya task ka readable description | `name: Install Nginx` |
| `hosts` | Inventory target select karta hai | `hosts: three_tier_app` |
| `become` | Privilege escalation request karta hai | `become: true` |
| `gather_facts` | Automatic facts enable/disable karta hai | `gather_facts: false` |
| `tasks` | Ordered task list shuru karta hai | `tasks:` |
| Task | Kaam ka ek unit | Create a directory |
| Module | Actual operation perform karta hai | `file`, `copy`, `dnf` |
| Argument | Module ko input deta hai | `path`, `state`, `mode` |

### Playbook list kyun hai?

```yaml
---
- name: First play
  hosts: all
```

Top-level hyphen ek play shuru karta hai. Playbook ek ya zyada plays ki list hoti hai.

### Tasks list kyun hai?

```yaml
tasks:
  - name: First task
    ping:

  - name: Second task
    command: uptime
```

`tasks` ke neeche har hyphen ek naya task shuru karta hai.

[Back to Index](#index)

---

## 14. Module ki value blank kyun nazar aati hai?

Example:

```yaml
file:
  path: /tmp/yaml-study-lab
  state: directory
  mode: "0755"
```

`file:` ke same line par value nazar nahi aa rahi, lekin value blank nahi hai. Iski value neeche wali nested mapping hai:

- `path`
- `state`
- `mode`

Isi tarah:

```yaml
ping:
```

`ping` module arguments ke baghair bhi chal sakta hai, is liye iske neeche arguments dena zaroori nahi.

### Important rule

> Module ki value hamesha blank nahi hoti. Kabhi arguments nested mapping ke roop mein neeche hotay hain, aur kuch modules arguments ke baghair bhi chal sakte hain.

[Back to Index](#index)

---

## 15. Complete playbook example

```yaml
---
- name: Create a study file on all managed nodes
  hosts: three_tier_app
  gather_facts: false

  tasks:
    - name: Ensure the lab directory exists
      file:
        path: /tmp/yaml-study-lab
        state: directory
        mode: "0755"

    - name: Create a study file
      copy:
        content: |
          YAML is a data format.
          Ansible uses YAML to structure playbooks.
          Inventory host: {{ inventory_hostname }}
        dest: /tmp/yaml-study-lab/notes.txt
        mode: "0644"
```

### Playbook kya karega?

1. `three_tier_app` group ko target karega.
2. Automatic fact gathering skip karega.
3. `/tmp/yaml-study-lab` directory banaye ya ensure karega.
4. Directory permission `0755` set karega.
5. Har managed node par `notes.txt` file create karega.
6. File mein us node ka inventory hostname likhega.
7. File permission `0644` set karega.

[Back to Index](#index)

---

## 16. Complete example ka parent-child structure

```text
Playbook
└── Play (top-level hyphen)
    ├── name
    ├── hosts
    ├── gather_facts
    └── tasks
        ├── Task 1 (pehla hyphen under tasks)
        │   ├── name
        │   └── file (module)
        │       ├── path
        │       ├── state
        │       └── mode
        └── Task 2 (doosra hyphen under tasks)
            ├── name
            └── copy (module)
                ├── content
                ├── dest
                └── mode
```

### List items kaun se hain?

- Top-level pehla hyphen ek **play list item** shuru karta hai.
- `tasks` ke neeche pehla hyphen Task 1 shuru karta hai.
- `tasks` ke neeche doosra hyphen Task 2 shuru karta hai.

### Parents aur direct children

| Parent | Direct children |
|---|---|
| Play | `name`, `hosts`, `gather_facts`, `tasks` |
| `tasks` | Task 1, Task 2 |
| Task 1 | `name`, `file` |
| `file` | `path`, `state`, `mode` |
| Task 2 | `name`, `copy` |
| `copy` | `content`, `dest`, `mode` |

[Back to Index](#index)

---

## 17. Ansible variables

Example:

```yaml
Inventory host: {{ inventory_hostname }}
```

`{{ inventory_hostname }}` ek Jinja variable expression hai.

Ansible runtime par isko current inventory hostname se replace karega:

- Node1 ki file mein `node1`
- Node2 ki file mein `node2`
- Node3 ki file mein `node3`

### Common variables

| Variable | Meaning |
|---|---|
| `inventory_hostname` | Inventory mein current host ka naam |
| `ansible_host` | Host se connect karne ke liye IP ya address |
| `ansible_user` | SSH connection user |
| `ansible_python_interpreter` | Managed node par Python executable ka path |

[Back to Index](#index)

---

## 18. File permissions ko quotes mein kyun likhein?

Recommended:

```yaml
mode: "0755"
mode: "0644"
```

Quotes YAML ko permission value ki exact representation preserve karne mein madad karti hain aur unwanted numeric interpretation se bachati hain.

| Mode | Common meaning |
|---|---|
| `"0755"` | Owner: rwx, Group: r-x, Others: r-x |
| `"0644"` | Owner: rw-, Group: r--, Others: r-- |

[Back to Index](#index)

---

## 19. Playbook validation aur safe testing

Assume playbook ka naam `yaml-study.yml` hai.

### Step 1: Syntax check

```bash
ansible-playbook yaml-study.yml --syntax-check
```

Yeh YAML aur Ansible playbook structure check karta hai. Tasks ka normal execution nahi karta.

### Step 2: Dry run / check mode

```bash
ansible-playbook yaml-study.yml --check
```

Check mode possible changes ko simulate karta hai. Har module check mode ko ek jaisi support nahi deta.

### Step 3: Diff ke saath check mode

```bash
ansible-playbook yaml-study.yml --check --diff
```

`--diff` supported files/templates mein before aur after difference dikhata hai.

### Step 4: Verbose output

```bash
ansible-playbook yaml-study.yml -v
ansible-playbook yaml-study.yml -vv
ansible-playbook yaml-study.yml -vvv
```

| Option | Detail level |
|---|---|
| `-v` | Thori extra information |
| `-vv` | Zyada details |
| `-vvv` | Connection aur troubleshooting details |
| `-vvvv` | Bohat detailed connection debugging |

### Step 5: Normal run

```bash
ansible-playbook yaml-study.yml
```

### Step 6: Limited host par run

```bash
ansible-playbook yaml-study.yml --limit node1
```

Pehle ek node par test karna production-style safe practice hai.

[Back to Index](#index)

---

## 20. Idempotency

Idempotency ka matlab hai ke playbook ko dobara run karne par, agar desired state pehle se maujood ho, to unnecessary change na ho.

Pehla run:

```text
changed=2
```

Doosra run:

```text
changed=0
```

Doosray run par `changed=0` aam tor par demonstrate karta hai ke resources pehle se desired state mein hain.

### Note

`shell` aur `command` modules aam tor par run honay par `changed` report kar sakte hain, kyun ke Ansible automatically nahi jaanta ke command ne actual system change kiya ya nahi.

[Back to Index](#index)

---

## 21. Common mistakes

### Mistake 1: Tabs use karna

**Solution:** Editor ko spaces use karne ke liye configure karein.

### Mistake 2: Same level par different indentation

Ghalat:

```yaml
student:
  name: Khalid
   course: Ansible
```

Sahi:

```yaml
student:
  name: Khalid
  course: Ansible
```

### Mistake 3: Colon ke baad space na dena

Ghalat:

```yaml
name:Khalid
```

Sahi:

```yaml
name: Khalid
```

### Mistake 4: List item ka hyphen bhool jana

Ghalat:

```yaml
packages:
  git
  curl
```

Sahi:

```yaml
packages:
  - git
  - curl
```

### Mistake 5: Play aur task ki indentation mix karna

`hosts` aur `tasks` play ke children hain. Modules task ke children hain. Module arguments module ke children hain.

### Mistake 6: Har valid YAML ko valid playbook samajhna

YAML syntactically valid ho sakti hai lekin Ansible playbook schema ke mutabiq invalid ho sakti hai.

### Mistake 7: File modes unquoted likhna

Permission modes ko strings ki tarah quote karna behtar hai:

```yaml
mode: "0644"
```

[Back to Index](#index)

---

## 22. Quick-reference table

| Term/Symbol | Roman Urdu meaning |
|---|---|
| Indentation | Structure dikhane wali starting spaces |
| Parent | Key jiske neeche nested data ho |
| Child | Parent ke neeche indented key |
| Key | Colon se pehle label |
| Value | Key ko assigned data |
| Mapping | Key-value pairs ka collection |
| Sequence/List | Ordered items ka collection |
| `-` | Naya list item shuru karta hai |
| `:` | Key ko value se separate karta hai |
| `|` | Multiline line breaks preserve karta hai |
| `>` | Multiline text ko fold karta hai |
| Scalar | Single string, number, Boolean ya null value |
| Playbook | Plays ki YAML file |
| Play | Hosts aur tasks ka connection |
| Task | Automation ka ek unit of work |
| Module | Actual operation perform karta hai |
| Argument | Module ko diya gaya input |
| `{{ variable }}` | Runtime Jinja expression |
| `---` | YAML document start marker |

[Back to Index](#index)

---

## 23. Practice exercises

### Exercise 1: Parent aur children identify karein

```yaml
service:
  name: nginx
  state: started
  enabled: true
```

Identify karein:

1. Parent key
2. Child keys
3. Scalar values

### Exercise 2: Package list likhein

`httpd`, `git` aur `tree` ko `dnf` module se install karne wali YAML task likhein.

### Exercise 3: Mapping ko list mein convert karein

```yaml
students:
  student1:
    name: Khalid
    course: Ansible
  student2:
    name: Ahmed
    course: Linux
```

Isko students ki list mein convert karein.

### Exercise 4: Error find karein

```yaml
tasks:
  - name: Create directory
    file:
      path: /tmp/lab
       state: directory
      mode: "0755"
```

Hint: `state` ki indentation check karein.

### Exercise 5: Commands run karein

```bash
ansible-playbook yaml-study.yml --syntax-check
ansible-playbook yaml-study.yml --check --diff
ansible-playbook yaml-study.yml --limit node1
ansible-playbook yaml-study.yml
```

[Back to Index](#index)

---

## 24. Quick revision summary

1. YAML structure indentation se banti hai.
2. Tabs ke bajaye consistent spaces use karein.
3. Parent ke neeche indented keys uske children hotay hain.
4. Mapping `key: value` pairs ka collection hoti hai.
5. List ka har item hyphen se shuru hota hai.
6. Scalar ek single value hoti hai.
7. Playbook top level par plays ki list hoti hai.
8. `tasks` ke neeche har hyphen ek naya task shuru karta hai.
9. Module actual kaam karta hai; arguments us module ko instructions dete hain.
10. `|` multiline line breaks preserve karta hai.
11. `{{ inventory_hostname }}` runtime variable expression hai.
12. File modes ko quotes mein likhna recommended hai.
13. `--syntax-check` execution se pehle syntax validate karta hai.
14. `--check` dry run provide karta hai.
15. Second run par `changed=0` aam tor par idempotency dikhata hai.

---

## Final memory line

> **Playbook batata hai automation kya kare; hosts batata hai kahan kare; task kaam ka step hai; module kaam karta hai; arguments module ko details dete hain; aur YAML indentation in sab ka structure dikhati hai.**

[Back to Index](#index)

