# YAML for Ansible Beginners - Roman Urdu Study Notes

<img src="YAML-for-beginners.png" width="700">


Yeh notes YAML ko bilkul shuru se samjhate hain aur har important concept ko Ansible playbooks ke sath connect karte hain. 

## Index

1. [Learning objectives](#1-learning-objectives)
2. [YAML kya hai?](#2-yaml-kya-hai)
3. [Configuration file kya hoti hai?](#3-configuration-file-kya-hoti-hai)
4. [YAML popular kyun hai?](#4-yaml-popular-kyun-hai)
5. [YAML, JSON aur XML](#5-yaml-json-aur-xml)
6. [YAML file extensions](#6-yaml-file-extensions)
7. [YAML ke zaroori rules](#7-yaml-ke-zaroori-rules)
8. [Key-value pairs](#8-key-value-pairs)
9. [Scalar data types](#9-scalar-data-types)
10. [Strings aur quotation marks](#10-strings-aur-quotation-marks)
11. [Lists ya sequences](#11-lists-ya-sequences)
12. [Mappings ya dictionaries](#12-mappings-ya-dictionaries)
13. [Nested data](#13-nested-data)
14. [List of mappings](#14-list-of-mappings)
15. [Comments](#15-comments)
16. [Multiline strings](#16-multiline-strings)
17. [YAML document markers](#17-yaml-document-markers)
18. [YAML ka Ansible se relation](#18-yaml-ka-ansible-se-relation)
19. [Ansible playbook structure](#19-ansible-playbook-structure)
20. [Module values aur arguments](#20-module-values-aur-arguments)
21. [Practical Ansible example](#21-practical-ansible-example)
22. [Variables, lists aur loops](#22-variables-lists-aur-loops)
23. [Ansible mein Booleans aur file modes](#23-ansible-mein-booleans-aur-file-modes)
24. [YAML aur tool-specific keywords ka farq](#24-yaml-aur-tool-specific-keywords-ka-farq)
25. [Validation methods](#25-validation-methods)
26. [Common errors aur troubleshooting](#26-common-errors-aur-troubleshooting)
27. [Hands-on practice lab](#27-hands-on-practice-lab)
28. [Practice questions aur answers](#28-practice-questions-aur-answers)
29. [Ansible dry run aur Check Mode](#29-ansible-dry-run-aur-check-mode)
30. [Ansible verbosity options](#30-ansible-verbosity-options)
31. [Quick-reference tables](#31-quick-reference-tables)
32. [Final summary](#32-final-summary)

---

## 1. Learning objectives

In notes ko complete karne ke baad aap:

- YAML ko define aur uska purpose explain kar sakein ge.
- Configuration file ka software behavior se relation samajh sakein ge.
- String, integer, float, Boolean, null, list aur mapping pehchan sakein ge.
- YAML indentation sahi use kar sakein ge.
- Nested YAML data likh sakein ge.
- Ansible playbook ka YAML structure samajh sakein ge.
- Play, task, module aur arguments identify kar sakein ge.
- YAML aur Ansible syntax validate kar sakein ge.
- Common YAML errors diagnose kar sakein ge.

---

## 2. YAML kya hai?

YAML ek human-readable data-serialization format hai. Isay structured data organize karne aur configuration files likhne ke liye use kiya jata hai.

> Data serialization is the process of converting data into a structured, storable, and transferable format.

Examples of serialization formats include:
- YAML
- JSON
- XML
YAML represents data; it does not execute automation itself. Ansible reads the YAML and performs the specified automation.

YAML ka modern full form hai:

> YAML Ain't Markup Language

Is naam ka maqsad yeh batana hai ke YAML document ki visual formatting ke bajaye data ko represent karta hai.

### One-line definition

> YAML ek human-readable format hai jo structured data aur configuration instructions ko organize karne ke liye use hota hai.

YAML programming language nahi hai. YAML data describe karta hai jise koi doosra program read aur interpret karta hai.

---

## 3. Configuration file kya hoti hai?

Configuration file woh settings aur instructions rakhti hai jo software ya tool ko batati hain ke usay kaise behave karna hai.

Software ko yeh maloomat chahiye ho sakti hai:

- kaun sa port use karna hai;
- kis server se connect karna hai;
- kaun se users allowed hain;
- kaun si service start karni hai;
- kaun si file create karni hai;
- kin hosts ko configure karna hai.

Software ke andar kaam karne ki logic hoti hai. Configuration file selected settings provide karti hai.

### Simple analogy

Software ko driver samjhein aur configuration file ko route instructions. Driver gaari chala sakta hai, lekin instructions usay batati hain ke jana kahan hai.

Ansible mein:

- Ansible automation engine hai.
- Inventory managed nodes identify karti hai.
- Playbook automation instructions rakhta hai.
- YAML un instructions ka structure provide karta hai.

---

## 4. YAML popular kyun hai?

YAML popular hai kyun ke yeh:

- insaan ke liye readable hai;
- relatively asani se likhi ja sakti hai;
- XML se kam cluttered nazar aati hai;
- nested data support karti hai;
- modern DevOps tools mein commonly use hoti hai;
- Git jaise version-control systems mein asani se manage hoti hai.

YAML use karne wale common tools:

- Ansible;
- Docker Compose;
- Kubernetes;
- GitHub Actions;
- GitLab CI/CD;
- cloud aur infrastructure tools.

YAML readable zaroor hai, lekin iska matlab yeh nahi ke indentation optional hai. Syntax phir bhi bilkul sahi honi chahiye.

> Indentation uses spaces at the beginning of YAML lines to represent the structure and parent-child relationship of data.

---

## 5. YAML, JSON aur XML

Ek hi structured data ko YAML, JSON ya XML mein represent kiya ja sakta hai.

### YAML

```yaml
student:
  name: Khalid
  course: Ansible
```

### JSON

```json
{
  "student": {
    "name": "Khalid",
    "course": "Ansible"
  }
}
```

### XML

```xml
<student>
  <name>Khalid</name>
  <course>Ansible</course>
</student>
```

| Format | Main characteristic |
|---|---|
| YAML | Indentation use karti hai aur punctuation kam hoti hai |
| JSON | Braces, brackets, commas aur quoted keys use karta hai |
| XML | Opening aur closing tags use karta hai |

Configuration ke liye YAML aksar zyada readable hoti hai. APIs mein JSON bohat common hai. XML ab bhi kai established systems mein use hoti hai.

---

## 6. YAML file extensions

Dono extensions valid hain:

```text
.yml
.yaml
```

Examples:

```text
site.yml
deploy.yaml
```

Ansible dono ko accept karta hai. Project mein ek convention choose karke consistently use karna behtar hai.

---

## 7. YAML ke zaroori rules

### Rule 1: Spaces use karein, tabs nahi

YAML indentation par depend karti hai. Tabs parser errors aur inconsistent behavior cause kar sakti hain.

```yaml
student:
  name: Khalid
  course: Ansible
```

Aam tor par har level ke liye do spaces use ki jati hain. Exact number se zyada consistency important hai.

### Rule 2: Indentation relationship show karti hai

```yaml
student:
  name: Khalid
  course: Ansible
```

`name` aur `course`, `student` ke andar hain kyun ke woh uske neeche indented hain.

### Rule 3: Colon ke baad space dein

Sahi:

```yaml
name: Khalid
```

Ghalat:

```yaml
name:Khalid
```

### Rule 4: List item ke liye hyphen aur space use karein

```yaml
subjects:
  - Linux
  - Ansible
```

### Rule 5: Same level ki keys align karein

```yaml
student:
  name: Khalid
  city: Chicago
```

`name` aur `city` siblings hain, is liye dono ki indentation same honi chahiye.

### Rule 6: YAML case-sensitive hai

```yaml
name: Khalid
Name: Muhammad
```

Yeh do different keys hain.

### Rule 7: Same mapping level par duplicate keys na likhein

Avoid:

```yaml
name: Khalid
name: Ahmed
```

Kuch parsers sirf last value rakhte hain aur kuch error dete hain. Multiple values ke liye list ya separate mappings use karein.

---

## 8. Key-value pairs

YAML ka basic structure key-value pair hai:

```yaml
key: value
```

Example:

```yaml
package: nginx
state: present
```

Key setting ko identify karti hai aur value uska assigned data hoti hai.

Ansible example:

```yaml
dnf:
  name: nginx
  state: present
```

- `dnf` module ka naam hai.
- `dnf` ki value uske neeche indented mapping hai.
- `name` aur `state` module arguments hain.

---

## 9. Scalar data types

Scalar ek single value hoti hai, collection nahi.

### String

```yaml
name: Khalid Khan
```

### Integer

```yaml
age: 25
```

### Floating-point number

```yaml
version: 1.5
```

### Boolean

```yaml
enabled: true
```

### Null

```yaml
optional_value: null
```

| Data type | Example | Meaning |
|---|---|---|
| String | `course: Ansible` | Text |
| Integer | `students: 25` | Whole number |
| Float | `version: 1.5` | Decimal number |
| Boolean | `enabled: true` | True ya false |
| Null | `value: null` | Koi assigned value nahi |

---

## 10. Strings aur quotation marks

Simple string ko aam tor par quotes ki zarurat nahi:

```yaml
name: Khalid Khan
```

Quotes useful hain jab:

- string mein YAML special character ho;
- leading ya trailing spaces important hon;
- value number ya Boolean jaisi nazar aaye;
- value Jinja expression se start ho;
- ambiguity avoid karni ho.

Colon wali string:

```yaml
message: "Warning: authorized access only"
```

Numeric-looking string:

```yaml
postal_code: "01234"
```

Jinja expression:

```yaml
path: "{{ lab_directory }}"
```

### Single aur double quotes ka farq

```yaml
single_quoted: 'Hello\nWorld'
double_quoted: "Hello\nWorld"
```

Double-quoted string mein `\n` newline represent kar sakta hai. Single-quoted YAML string mein yeh aam tor par literal text rehta hai.

---

## 11. Lists ya sequences

List multiple ordered values store karti hai.

### Block format

```yaml
subjects:
  - Linux
  - Ansible
  - Docker
```

Har hyphen ek list item represent karta hai.

### Inline format

```yaml
subjects: [Linux, Ansible, Docker]
```

Dono formats valid hain, lekin playbooks mein block format zyada readable hota hai.

### Ansible package list

```yaml
dnf:
  name:
    - git
    - curl
    - tree
  state: present
```

Yahan `name` ki value teen package names ki list hai.

---

## 12. Mappings ya dictionaries

Mapping related key-value pairs store karti hai.

```yaml
student:
  name: Khalid
  city: Chicago
  course: Ansible
```

Programming terminology mein isay dictionary, object ya associative array bhi kaha ja sakta hai.

### Ansible example

```yaml
file:
  path: /tmp/ansible-lab
  state: directory
  mode: "0755"
```

`file` ki value ek mapping hai jisme `path`, `state` aur `mode` arguments hain.

---

## 13. Nested data

YAML mein mapping ke andar doosri mapping ho sakti hai:

```yaml
student:
  name: Khalid
  marks:
    Linux: 90
    Ansible: 85
```

Relationship:

```text
student
├── name
└── marks
    ├── Linux
    └── Ansible
```

Har deeper level ko mazeed indent kiya jata hai.

### Multiple students

```yaml
students:
  student1:
    name: Khalid
    course: Ansible
  student2:
    name: Ahmed
    course: Linux
```

Is structure se same mapping level par duplicate `name` keys ka issue nahi hota.

---

## 14. List of mappings

Jab har list item ki multiple properties hon to list of mappings use hoti hai:

```yaml
students:
  - name: Khalid
    course: Ansible
    city: Chicago
  - name: Ahmed
    course: Linux
    city: Dallas
```

Har hyphen ek nayi student mapping start karta hai.

Ansible loops mein yeh structure common hai:

```yaml
users:
  - name: ali
    shell: /bin/bash
  - name: sara
    shell: /bin/bash
```

---

## 15. Comments

Comment `#` se start hota hai:

```yaml
# Install the web-server package
package_name: nginx
```

Inline comment:

```yaml
state: present  # Ensure the package is installed
```

Comments ka maqsad intent explain karna hai. Har obvious line ko dobara comment mein likhne ki zarurat nahi.

Useful comment:

```yaml
# Quote the mode so YAML treats it as a string
mode: "0644"
```

---

## 16. Multiline strings

### Literal block `|`

Pipe line breaks preserve karta hai:

```yaml
message: |
  Welcome to the Ansible lab.
  This file is managed automatically.
```

Result:

```text
Welcome to the Ansible lab.
This file is managed automatically.
```

### Folded block `>`

Greater-than sign aam tor par line breaks ko spaces mein fold karta hai:

```yaml
message: >
  Welcome to the Ansible lab.
  This sentence will normally be folded.
```

### Ansible copy example

```yaml
copy:
  content: |
    WARNING: AUTHORIZED ACCESS ONLY.
    Activity may be monitored.
  dest: /tmp/banner.txt
  mode: "0644"
```

---

## 17. YAML document markers

`---` YAML document ka start show karta hai:

```yaml
---
- name: Example play
  hosts: all
```

`...` document ka end show kar sakta hai:

```yaml
...
```

Ordinary Ansible playbooks mein dono required nahi. Start mein `---` use karna common aur clear convention hai. Ending marker aam tor par omit kiya jata hai.

---

## 18. YAML ka Ansible se relation

YAML Ansible playbook ko data structure deti hai. Ansible in keys ko specific meaning deta hai:

- `name`;
- `hosts`;
- `become`;
- `gather_facts`;
- `vars`;
- `tasks`;
- `handlers`;
- `loop`;
- `when`;
- `register`;
- `file`, `copy`, `dnf` jaise module names.

YAML khud nahi jaanti ke `hosts` ya `tasks` ka kya matlab hai. Ansible YAML ko read karke in keys ko apne rules ke mutabiq interpret karta hai.

> YAML format define karti hai; Ansible documentation supported automation keywords aur module arguments define karti hai.

---

## 19. Ansible playbook structure

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

### Structure

```text
Playbook
└── Play
    ├── name
    ├── hosts
    ├── become
    ├── gather_facts
    └── tasks
        └── Task
            ├── name
            └── file module
                ├── path
                ├── state
                └── mode
```

| Term | Definition |
|---|---|
| Playbook | YAML file jisme ek ya zyada plays hote hain |
| Play | Tasks jo host ya inventory group par apply hote hain |
| Task | Automation ka ek named unit of work |
| Module | Ansible component jo action perform karta hai |
| Argument | Module behavior control karne ke liye di gayi value |

---

## 20. Module values aur arguments

Yeh example dekhein:

```yaml
file:
  path: /tmp/ansible-playbook-lab
  state: directory
  mode: "0755"
```

Pehli nazar mein lag sakta hai ke `file:` ki value blank hai. Lekin uski value neeche wali complete indented mapping hai:

```yaml
path: /tmp/ansible-playbook-lab
state: directory
mode: "0755"
```

Is liye:

- `file` module hai.
- `path`, `state` aur `mode` arguments hain.
- Arguments ki poori mapping `file` ki value hai.

### Module without arguments

Kuch modules arguments ke baghair use ho sakte hain:

```yaml
- name: Test connectivity
  ping:
```

Yahan `ping:` ke neeche argument mapping nahi, is liye uski YAML value empty ya null hai.

### Module with arguments

```yaml
- name: Create a directory
  file:
    path: /tmp/demo
    state: directory
```

Yahan `file:` blank nahi. Uski value indented argument mapping hai.

### Yaad rakhne wali definition

> Module ki value hamesha same line par nahi hoti. Agar arguments module ke neeche indented hon, to woh arguments mil kar module ki value bante hain.

---

## 21. Practical Ansible example

Aapke Rocky Linux inventory group ka example:

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

Play-level data:

- `name` string hai.
- `hosts` inventory pattern wali string hai.
- `gather_facts` Boolean hai.
- `tasks` list hai.

Task-level data:

- Har `- name` task mapping start karta hai.
- `file` aur `copy` module names hain.
- Module arguments nested mappings hain.
- `content: |` multiline string hai.

---

## 22. Variables, lists aur loops

```yaml
---
- name: Demonstrate variables and a loop
  hosts: three_tier_app
  gather_facts: false

  vars:
    lab_directory: /tmp/yaml-study-lab
    filenames:
      - introduction.txt
      - lists.txt
      - mappings.txt

  tasks:
    - name: Ensure the lab directory exists
      file:
        path: "{{ lab_directory }}"
        state: directory
        mode: "0755"

    - name: Create each study file
      file:
        path: "{{ lab_directory }}/{{ item }}"
        state: touch
        mode: "0644"
      loop: "{{ filenames }}"
```

Explanation:

- `vars` mapping hai.
- `lab_directory` string hai.
- `filenames` list hai.
- `tasks` bhi list hai.
- `loop` filenames list ko read karta hai.
- Har iteration mein `item` current filename ko represent karta hai.

> `state: touch` repeated runs par timestamps update karta hai, is liye task dobara `changed` report kar sakti hai. Strong idempotency demonstration ke liye stable content ke sath `copy` use karein.

---

## 23. Ansible mein Booleans aur file modes

### Clear Boolean values use karein

```yaml
become: true
gather_facts: false
enabled: true
```

Lowercase `true` aur `false` recommended hain.

### File modes quote karein

```yaml
mode: "0644"
mode: "0755"
```

Quotes numeric interpretation problems avoid karti hain aur permission notation ko clear rakhti hain.

---

## 24. YAML aur tool-specific keywords ka farq

YAML seekhne se data structure samajh aata hai, lekin Ansible, Docker Compose ya Kubernetes ki har supported key automatically nahi seekhi jati.

Example:

```yaml
file:
  path: /tmp/demo
  state: directory
```

YAML yeh explain karti hai:

- `path` aur `state`, `file` ke neeche kyun hain;
- colon key aur value ko kyun separate karta hai;
- indentation kyun important hai.

Ansible documentation yeh explain karti hai:

- `file` module kya karta hai;
- module kaun se arguments accept karta hai;
- `state` ki valid values kya hain;
- module check mode support karta hai ya nahi.

Documentation dekhein:

```bash
ansible-doc file
ansible-doc copy
ansible-doc dnf
ansible-doc -l
```

---

## 25. Validation methods

### Ansible syntax check

```bash
ansible-playbook playbooks/example.yml --syntax-check
```

### Target hosts list karein

```bash
ansible-playbook playbooks/example.yml --list-hosts
```

### Tasks list karein

```bash
ansible-playbook playbooks/example.yml --list-tasks
```

### Supported changes ka preview

```bash
ansible-playbook playbooks/example.yml --check --diff
```

### YAML-aware editor use karein

Vim syntax support ya Visual Studio Code ka YAML extension indentation aur syntax errors highlight kar sakta hai.

### Security recommendation

Production playbooks jin mein passwords, private keys, tokens, internal hostnames ya confidential data ho, unhein random online validators mein paste na karein.

---

## 26. Common errors aur troubleshooting

### Error 1: Tabs use karna

```text
found character '\t' that cannot start any token
```

Tabs ko spaces se replace karein.

Vim mein whitespace show karein:

```vim
:set list
```

Tabs ko spaces mein convert karein:

```vim
:set expandtab
:retab
```

### Error 2: Ghalat indentation

Ghalat:

```yaml
tasks:
  - name: Create directory
    file:
    path: /tmp/demo
      state: directory
```

Sahi:

```yaml
tasks:
  - name: Create directory
    file:
      path: /tmp/demo
      state: directory
```

### Error 3: Colon ke baad space missing

Ghalat:

```yaml
name:Khalid
```

Sahi:

```yaml
name: Khalid
```

### Error 4: Unquoted string mein colon

Ghalat ya confusing:

```yaml
message: Warning: authorized users only
```

Sahi:

```yaml
message: "Warning: authorized users only"
```

### Error 5: Duplicate keys

Ghalat design:

```yaml
student: Khalid
student: Ahmed
```

List use karein:

```yaml
students:
  - Khalid
  - Ahmed
```

### Error 6: `mapping values are not allowed here`

Aam tor par wajah:

- ghalat indentation;
- unquoted colon;
- malformed key-value syntax.

### Error 7: `did not find expected '-' indicator`

List item ka hyphen missing ho sakta hai ya indentation inconsistent hai.

### Error 8: YAML valid hai lekin Ansible invalid

Yeh valid YAML ho sakti hai:

```yaml
favorite_color: blue
```

Lekin valid Ansible playbook nahi, kyun ke expected playbook structure nahi hai.

YAML validation aur Ansible syntax validation do related magar different checks hain.

---

## 27. Hands-on practice lab

### Objective

Safe playbook create aur run karein jo demonstrate kare:

- play;
- task list;
- module argument mappings;
- variables;
- list;
- loop;
- multiline content;
- idempotency;
- cleanup.

### Step 1: Project directory mein jayein

```bash
cd /home/ansibleadmin/automation
mkdir -p playbooks
```

### Step 2: Environment verify karein

```bash
ansible --version
ansible-inventory --graph
ansible three_tier_app -m ping
```

### Step 3: Playbook create karein

```bash
vim playbooks/yaml-fundamentals-lab.yml
```

Content:

```yaml
---
- name: Practice YAML structures with Ansible
  hosts: three_tier_app
  gather_facts: false

  vars:
    lab_directory: /tmp/yaml-fundamentals-lab
    study_files:
      - name: strings.txt
        topic: YAML strings and quotation marks
      - name: lists.txt
        topic: YAML lists and loop items
      - name: mappings.txt
        topic: YAML mappings and nested arguments

  tasks:
    - name: Ensure the lab directory exists
      file:
        path: "{{ lab_directory }}"
        state: directory
        mode: "0755"

    - name: Create the study files
      copy:
        content: |
          YAML Study Lab
          Host: {{ inventory_hostname }}
          Topic: {{ item.topic }}
        dest: "{{ lab_directory }}/{{ item.name }}"
        mode: "0644"
      loop: "{{ study_files }}"

    - name: Verify the directory contents
      command: "ls -la {{ lab_directory }}"
      register: directory_listing
      changed_when: false

    - name: Display the verification output
      debug:
        var: directory_listing.stdout_lines
```

### Step 4: Syntax check karein

```bash
ansible-playbook playbooks/yaml-fundamentals-lab.yml --syntax-check
```

### Step 5: Hosts aur tasks list karein

```bash
ansible-playbook playbooks/yaml-fundamentals-lab.yml --list-hosts
ansible-playbook playbooks/yaml-fundamentals-lab.yml --list-tasks
```

### Step 6: Preview dekhein

```bash
ansible-playbook playbooks/yaml-fundamentals-lab.yml --check --diff
```

### Step 7: Playbook run karein

```bash
ansible-playbook playbooks/yaml-fundamentals-lab.yml
```

### Step 8: Idempotency ke liye dobara run karein

```bash
ansible-playbook playbooks/yaml-fundamentals-lab.yml
```

Second run par aam tor par `changed=0` aana chahiye, kyun ke desired files aur content pehle se exist karte hain.

### Step 9: Ad-hoc command se verify karein

```bash
ansible three_tier_app -m command \
  -a "ls -la /tmp/yaml-fundamentals-lab"
```

### Step 10: Cleanup playbook create karein

```bash
vim playbooks/yaml-fundamentals-cleanup.yml
```

Content:

```yaml
---
- name: Clean the YAML fundamentals lab
  hosts: three_tier_app
  gather_facts: false

  tasks:
    - name: Ensure the lab directory is absent
      file:
        path: /tmp/yaml-fundamentals-lab
        state: absent
```

Run karein:

```bash
ansible-playbook playbooks/yaml-fundamentals-cleanup.yml
```

Cleanup idempotency ke liye dobara run karein:

```bash
ansible-playbook playbooks/yaml-fundamentals-cleanup.yml
```

Second cleanup run par `changed=0` aana chahiye.

---

## 28. Practice questions aur answers

### 1. YAML ka full form kya hai?

YAML ka full form **YAML Ain't Markup Language** hai. Yeh recursive acronym hai kyun ke pehla letter YAML ko hi refer karta hai.

### 2. Kya YAML programming language hai?

Nahi. YAML human-readable **data-serialization language** hai jo structured data represent karti hai. Ismein apni programming logic nahi hoti.

### 3. YAML mein spaces kyun important hain?

Spaces indentation banati hain. YAML indentation se nesting, structure aur parent-child relationships identify karti hai.

### 4. Tabs avoid kyun karni chahiye?

YAML indentation ke liye tabs allow nahi karti. Tabs parsing aur syntax errors cause kar sakti hain, is liye consistently spaces use karein.

### 5. Key aur value ko kaun sa symbol separate karta hai?

Colon ke baad space (`: `) key aur value ko separate karta hai.

```yaml
name: Khalid
```

### 6. List item kaun se symbol se start hota hai?

Har list item hyphen ke baad space (`- `) se start hota hai.

```yaml
packages:
  - nginx
  - git
```

### 7. List aur mapping mein kya farq hai?

List ordered items ka collection hoti hai, jabke mapping key-value pairs ka collection hoti hai.

### 8. String ko kab quote karna chahiye?

String ko quote karein jab usmein special characters hon, woh number ya Boolean jaisi nazar aaye, ya exact format preserve karna ho.

### 9. Multiline string mein `|` kya karta hai?

Literal block scalar `|` line breaks ko preserve karta hai.

### 10. Multiline string mein `>` kya karta hai?

Folded block scalar `>` aam tor par line breaks ko spaces mein convert karke paragraph bana deta hai.

### 11. Jab arguments neeche likhe hon to `file:` ki value kya hoti hai?

Value blank nahi hoti. Neeche ke indented arguments mil kar module ki nested mapping value bante hain.

```yaml
file:
  path: /tmp/demo
  state: directory
  mode: "0755"
```

### 12. `ping:` arguments ke baghair kyun chal sakta hai?

Ansible `ping` module ke basic connectivity aur Python test ke liye koi required argument nahi hai.

### 13. Kya har valid YAML file valid Ansible playbook hoti hai?

Nahi. File valid YAML ho sakti hai lekin uska Ansible structure, keyword, module ya argument ghalat ho sakta hai.

### 14. Ansible-specific keywords kahan se aate hain?

`hosts`, `tasks`, `become`, `vars`, module names aur unke arguments Ansible define karta hai. YAML sirf data structure provide karti hai.

### 15. Ansible syntax check ka command kya hai?

```bash
ansible-playbook playbook.yml --syntax-check
```

### 16. `0644` jaise file modes ko quote kyun karna chahiye?

Quotes exact permission format preserve karti hain aur unintended numeric interpretation se bachati hain.

```yaml
mode: "0644"
```

### 17. Second run par `changed=0` aam tor par kya demonstrate karta hai?

Yeh aam tor par **idempotency** demonstrate karta hai: system pehle se desired state mein hai, is liye Ansible ko dobara change karne ki zarurat nahi.

### 18. Confidential playbook ko unknown online validator mein paste kyun nahi karna chahiye?

Playbook mein usernames, IP addresses, tokens, passwords, keys aur infrastructure details ho sakti hain. Unknown website is information ko store ya misuse kar sakti hai.

---

## 29. Ansible dry run aur Check Mode

### Definition

Ansible mein dry run ko **Check Mode** kehte hain. Jab involved modules Check Mode support karte hon, Ansible actual changes apply kiye baghair predict karta hai ke kya change hoga.

### Basic command

```bash
ansible-playbook playbook.yml --check
```

### Proposed file differences dekhein

```bash
ansible-playbook playbook.yml --check --diff
```

- `--check` predict karta hai ke kya change hoga.
- `--diff` supported modules ke liye before aur after difference show karta hai.

### Sirf `node1` par Check Mode

```bash
ansible-playbook playbook.yml --check --limit node1
```

### Inventory explicitly specify karein

```bash
ansible-playbook -i ./inventory/nodes playbook.yml --check
```

### Ad-hoc Check Mode example

```bash
ansible three_tier_app -b -m dnf \
  -a "name=nginx state=present" --check
```

### Important limitations

- Har module Check Mode ko completely support nahi karta.
- `command`, `shell` aur `raw` arbitrary commands ke changes reliably predict nahi kar sakte.
- Check Mode ek preview hai; yeh real run successful hone ki guarantee nahi deta.
- Agar later task kisi aisi file ya resource par depend karta ho jo earlier task create karta, to Check Mode mein woh task fail ho sakta hai.
- `--syntax-check` sirf syntax validate karta hai; yeh dry run nahi hai.

### Recommended validation workflow

```bash
ansible-playbook playbook.yml --syntax-check
ansible-playbook playbook.yml --check --diff
ansible-playbook playbook.yml
ansible-playbook playbook.yml
```

Idempotent playbook ke second real run par ideally `changed=0` aana chahiye.

---

## 30. Ansible verbosity options

### Definition

Verbosity options execution ki additional details show karte hain. Ansible command ke baad `v` add kiya jata hai; jitne zyada `v` hon ge, utni zyada detailed output milegi.

| Option | Detail level | Recommended use |
|---|---|---|
| `-v` | Basic additional details | General learning aur light troubleshooting |
| `-vv` | Zyada task aur connection details | Variables ya task behavior investigate karna |
| `-vvv` | Detailed SSH aur connection information | Authentication, inventory ya SSH problems diagnose karna |
| `-vvvv` | Bohat detailed connection debugging | Sirf deep troubleshooting; output bohat extensive ho sakti hai |

### Playbook examples

```bash
ansible-playbook playbook.yml -v
ansible-playbook playbook.yml -vv
ansible-playbook playbook.yml -vvv
ansible-playbook playbook.yml -vvvv
```

### Ad-hoc example

```bash
ansible three_tier_app -m ping -vvv
```

### Verbosity ko Check Mode ke sath use karein

```bash
ansible-playbook playbook.yml --check --diff -vv
```

### Apne lab environment mein use karein

```bash
ansible-playbook -i ./inventory/nodes playbooks/example.yml --check --diff -vv
```

> **Caution:** Verbose output mein hostnames, IP addresses, file paths, usernames aur connection details nazar aa sakti hain. Screenshots ya logs publicly share karne se pehle review karein. `-v` ya `-vv` se start karein; SSH ya connection failure diagnose karne ke liye `-vvv` use karein.

---

## 31. Quick-reference tables

### YAML symbols

| Symbol | Purpose | Example |
|---|---|---|
| `:` | Key aur value separate karta hai | `name: Khalid` |
| `-` | List item start karta hai | `- Linux` |
| `#` | Comment start karta hai | `# Lab task` |
| `|` | Literal multiline string | Line breaks preserve karta hai |
| `>` | Folded multiline string | Aam tor par line breaks ko spaces mein fold karta hai |
| `---` | YAML document start karta hai | Playbook ki first line |
| `...` | YAML document end karta hai | Optional |
| `{}` | Inline mapping | `{name: Khalid}` |
| `[]` | Inline list | `[Linux, Ansible]` |

### YAML structures

| Structure | Example |
|---|---|
| Scalar | `name: Khalid` |
| List | `subjects: [Linux, Ansible]` |
| Mapping | `student: {name: Khalid}` |
| Nested mapping | Ek mapping doosri mapping ke andar indented hoti hai |
| List of mappings | Multiple `- name:` objects |

### Ansible structure

| Level | Common keys |
|---|---|
| Playbook | Plays ki list |
| Play | `name`, `hosts`, `become`, `gather_facts`, `vars`, `tasks` |
| Task | `name`, module, `when`, `loop`, `register`, `notify` |
| Module value | Arguments ki mapping |
| Module arguments | `path`, `state`, `mode`, `name`, `enabled` aur doosre options |

### Recommended validation sequence

```bash
ansible-inventory --graph
ansible three_tier_app -m ping
ansible-playbook playbooks/example.yml --syntax-check
ansible-playbook playbooks/example.yml --list-hosts
ansible-playbook playbooks/example.yml --list-tasks
ansible-playbook playbooks/example.yml --check --diff
ansible-playbook playbooks/example.yml --check --diff -vv
ansible-playbook playbooks/example.yml
ansible-playbook playbooks/example.yml
```

---

## 32. Final summary

- YAML human-readable data format hai jo configuration aur automation mein commonly use hoti hai.
- YAML structure aur relationships show karne ke liye indentation use karti hai.
- Indentation ke liye tabs nahi, spaces use karni chahiye.
- Colon key aur value separate karta hai.
- Hyphen list item start karta hai.
- Scalar single value, list ordered items aur mapping key-value pairs store karti hai.
- Quotes ambiguous strings ko ghalat interpret hone se bachati hain.
- Ansible playbooks ke structure ke liye YAML use karta hai.
- `hosts`, `tasks`, modules aur arguments ka meaning Ansible define karta hai, YAML nahi.
- Module ke neeche indented arguments mil kar module ki value bante hain.
- `ping` jaisa module arguments ke baghair use ho sakta hai, lekin bohat se modules ko argument mapping chahiye.
- Playbook ko `ansible-playbook --syntax-check` se validate karein.
- Supported changes ko `--check` se preview aur file differences ko `--diff` se inspect karein.
- Progressively detailed troubleshooting output ke liye `-v` se `-vvvv` use karein.
- Idempotency check karne ke liye automation ko dobara run karein.
- Lab ko repeat karne ke liye cleanup playbook zaroor rakhein.
