# Ansible Variables aur Loops Learning Bundle — Roman Urdu

Yeh bundle Ansible ke do bohat aham concepts ke liye structured study notes aur hands-on practice provide karta hai:

- Variables
- Loops

Yeh material Rocky Linux 9 ke Ansible lab ke mutabiq tayyar kiya gaya hai, jis mein ek control node aur teen managed nodes use hote hain.

## Index

1. [Bundle mein kya shamil hai?](#1-bundle-mein-kya-shamil-hai)
2. [Learning objectives](#2-learning-objectives)
3. [Lab environment](#3-lab-environment)
4. [Recommended learning order](#4-recommended-learning-order)
5. [Directory structure](#5-directory-structure)
6. [Har document ki tafseel](#6-har-document-ki-tafseel)
7. [Lab files ko kaise use karein?](#7-lab-files-ko-kaise-use-karein)
8. [Aham commands](#8-aham-commands)
9. [Expected learning outcomes](#9-expected-learning-outcomes)
10. [Safety aur cleanup](#10-safety-aur-cleanup)
11. [Suggested classroom workflow](#11-suggested-classroom-workflow)

---

## 1. Bundle mein kya shamil hai?

| File | Maqsad |
|---|---|
| [Ansible_Loops_Study_Notes_Roman_Urdu.md](Ansible_Loops_Study_Notes_Roman_Urdu.md) | Ansible loops ki mukammal Roman Urdu explanation |
| [Ansible_Variables_Study_Notes_Roman_Urdu.md](Ansible_Variables_Study_Notes_Roman_Urdu.md) | Ansible variables ki mukammal Roman Urdu explanation |
| [lab/Ansible_Variables_and_Loops_6_Task_Lab.md](lab/Ansible_Variables_and_Loops_6_Task_Lab.md) | Instructions aur hints ke sath six-task student lab |
| [lab/Ansible_Variables_and_Loops_6_Task_Lab_Solution.md](lab/Ansible_Variables_and_Loops_6_Task_Lab_Solution.md) | Complete solution, explanation aur verification procedure |

> **Language note:** Variables aur Loops study notes Roman Urdu mein hain. Lab aur solution English mein hain taa-ke students Ansible ke asal technical terms aur exam-style instructions ke sath bhi practice kar sakein.

## 2. Learning objectives

Is material ko complete karne ke baad aap:

- Ansible variable ka purpose explain kar sakenge.
- Playbook ke andar variables define kar sakenge.
- Strings, numbers, Boolean values, lists aur dictionaries pehchan sakenge.
- `{{ variable_name }}` se variables reference kar sakenge.
- Ansible loop ka purpose explain kar sakenge.
- Samajh sakenge ke har iteration mein `item` ki value kaise change hoti hai.
- Simple list ko `loop` ke sath process kar sakenge.
- List of dictionaries ko `item.key_name` ke sath process kar sakenge.
- `loop_control.loop_var` se `item` ka naam change kar sakenge.
- `loop_control.label` se output ko saaf bana sakenge.
- `register` se task result save kar sakenge.
- Registered loop ki `results` list samajh sakenge.
- Syntax check, dry run aur idempotency test kar sakenge.

## 3. Lab environment

| Component | Configuration |
|---|---|
| Control node | `ansible-server.nitclasses.com` |
| Control-node IP | `192.168.1.x` |
| Control-node user | `ansibleadmin` |
| Project directory | `/home/ansibleadmin/automation` |
| Playbook directory | `/home/ansibleadmin/automation/playbooks` |
| Inventory group | `three_tier_app` |
| Web node | `node1` — `192.168.1.154` |
| Application node | `node2` — `192.168.1.185` |
| Database node | `node3` — `192.168.1.190` |
| Managed-node OS | Rocky Linux 9 |

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

## 4. Recommended learning order

### Step 1: Variables parhein

Sab se pehle:

```text
Ansible_Variables_Study_Notes_Roman_Urdu.md
```

In topics par focus karein:

- `vars:` ke neeche variables define karna
- Jinja expressions
- Lists aur dictionaries
- Inventory variables
- `group_vars` aur `host_vars`
- Registered variables
- Facts aur magic variables
- Variable precedence

### Step 2: Loops parhein

Is ke baad:

```text
Ansible_Loops_Study_Notes_Roman_Urdu.md
```

In topics par focus karein:

- Basic `loop` syntax
- `item` variable
- List of dictionaries
- `loop_control.loop_var`
- `loop_control.label`
- Conditions aur registered loop results
- Idempotency

### Step 3: Lab khud complete karein

```text
lab/Ansible_Variables_and_Loops_6_Task_Lab.md
```

Requirements aur hints parhein, lekin pehle solution file kholay baghair playbook khud likhne ki koshish karein.

### Step 4: Solution ke sath compare karein

```text
lab/Ansible_Variables_and_Loops_6_Task_Lab_Solution.md
```

YAML indentation, variable names, loop placement, module arguments, `loop_control` aur verification commands compare karein.

## 5. Directory structure

```text
variables-loop/
├── README.md
├── Ansible_Loops_Study_Notes_Roman_Urdu.md
├── Ansible_Variables_Study_Notes_Roman_Urdu.md
└── lab/
    ├── Ansible_Variables_and_Loops_6_Task_Lab.md
    └── Ansible_Variables_and_Loops_6_Task_Lab_Solution.md
```

README ko ZIP extract karne ke baad `variables-loop/` ki root directory mein rakhna chahiye.

## 6. Har document ki tafseel

### Ansible Loops Study Notes

Yeh guide explain karti hai:

- Loop kya hai aur kyun use hota hai
- Basic `loop` syntax aur `item`
- Package, directory, file aur user loops
- List of dictionaries
- Variables ko loop input banana
- `loop_control`
- Conditions aur registered loop results
- Aam ghaltiyan aur exercises

### Ansible Variables Study Notes

Yeh guide explain karti hai:

- Variable ki definition aur naming rules
- YAML data types
- Play aur inventory variables
- `group_vars` aur `host_vars`
- External variable files
- Registered variables
- Facts aur magic variables
- Extra variables, filters aur precedence
- Ansible Vault

### Six-Task Lab

Students ko:

1. Managed-node information display karni hai.
2. Main lab directory banani hai.
3. Loop se subdirectories banani hain.
4. Dictionaries se study files banani hain.
5. Loop se packages install karne hain.
6. `stat` aur `register` se files verify karni hain.

### Six-Task Lab Solution

Solution mein complete playbook, har task ki explanation, execution commands, verification, idempotency aur safe cleanup mojood hai.

## 7. Lab files ko kaise use karein?

Playbook is directory mein banayein:

```text
/home/ansibleadmin/automation/playbooks/
```

Recommended filename:

```text
variables-loops-lab.yml
```

Project directory mein jayein:

```bash
cd /home/ansibleadmin/automation
```

Connectivity verify karein:

```bash
ansible three_tier_app -m ping
```

Agar teeno nodes ke liye `SUCCESS` aur `pong` aaye to connectivity theek hai.

## 8. Aham commands

### Syntax check

```bash
ansible-playbook playbooks/variables-loops-lab.yml --syntax-check
```

Yeh basic YAML aur playbook structure check karta hai; tasks execute nahi karta.

### Dry run

```bash
ansible-playbook playbooks/variables-loops-lab.yml --check
```

`--check` supported changes ka preview deta hai. Kuch package operations check mode mein fully predictable nahi hotin.

### Sirf node1 par test

```bash
ansible-playbook playbooks/variables-loops-lab.yml --limit node1
```

### Teeno nodes par run

```bash
ansible-playbook playbooks/variables-loops-lab.yml
```

### Verbose output

```bash
ansible-playbook playbooks/variables-loops-lab.yml -v
```

Zyada detail ke liye `-vv` ya `-vvv` use kiya ja sakta hai.

### Directory structure verify karein

```bash
ansible three_tier_app -m command \
  -a "find /tmp/variables-loops-lab -maxdepth 2 -ls"
```

### Generated files parhein

Wildcard ko shell expansion chahiye, is liye `shell` module use karein:

```bash
ansible three_tier_app -m shell \
  -a "cat /tmp/variables-loops-lab/notes/*.txt"
```

### Packages verify karein

```bash
ansible three_tier_app -m command \
  -a "rpm -q git curl tree"
```

## 9. Expected learning outcomes

Students ko yeh relationship samajhna chahiye:

```text
Variable → data store karta hai
Loop     → us data ko baar baar process karta hai
item     → har repetition ki current value hoti hai
Module   → required operation perform karta hai
register → task ka result save karta hai
```

Example:

```yaml
vars:
  packages:
    - git
    - curl
    - tree

tasks:
  - name: Install packages
    dnf:
      name: "{{ item }}"
      state: present
    loop: "{{ packages }}"
```

Is example mein:

- `packages` list variable hai.
- `loop` list ko process karta hai.
- `item` mein ek waqt mein ek package name aata hai.
- `dnf` current package ko installed state mein lata hai.

Iterations:

```text
Pehli iteration:  item = git
Doosri iteration: item = curl
Teesri iteration: item = tree
```

## 10. Safety aur cleanup

Delete karne se pehle exact target inspect karein:

```bash
ansible three_tier_app -m command \
  -a "ls -la /tmp/variables-loops-lab"
```

Sirf lab directory remove karein:

```bash
ansible three_tier_app -b -m file \
  -a "path=/tmp/variables-loops-lab state=absent"
```

Removal verify karein:

```bash
ansible three_tier_app -m stat \
  -a "path=/tmp/variables-loops-lab"
```

Result mein yeh aana chahiye:

```text
"exists": false
```

Cleanup `git`, `curl` aur `tree` ko remove nahi karta kyun ke doosre students ya labs ko un ki zaroorat ho sakti hai.

## 11. Suggested classroom workflow

1. Instructor variables ko chhoti examples ke sath explain kare.
2. Students do variable exercises complete karein.
3. Instructor basic loops aur `item` explain kare.
4. Students simple list loop practice karein.
5. Instructor dictionaries aur `item.filename` explain kare.
6. Students six-task lab independently complete karein.
7. Students syntax check karein.
8. Pehle sirf `node1` par playbook test karein.
9. Phir teeno managed nodes par run karein.
10. Playbook dobara run karke idempotency observe karein.
11. Apna kaam solution file se compare karein.

---

## Short summary

> **Variable data store karta hai, jab ke loop us data ke har item par task repeat karta hai.**

Variables aur loops ko combine karke playbooks ko chhota, reusable, readable aur maintain karne mein asaan banaya ja sakta hai.
