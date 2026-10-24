# Ansible Loops — Roman Urdu Study Notes

## Index

1. [Loop kya hota hai?](#1-loop-kya-hota-hai)
2. [Loops kyun use kiye jate hain?](#2-loops-kyun-use-kiye-jate-hain)
3. [Basic syntax](#3-basic-syntax)
4. [`item` ko samajhna](#4-item-ko-samajhna)
5. [Packages ke sath loop](#5-packages-ke-sath-loop)
6. [Directories aur files ke loops](#6-directories-aur-files-ke-loops)
7. [Dictionaries par loop](#7-dictionaries-par-loop)
8. [Variable ko loop mein use karna](#8-variable-ko-loop-mein-use-karna)
9. [`loop_control` se `item` ka naam badalna](#9-loop_control-se-item-ka-naam-badalna)
10. [Loops ke sath conditions](#10-loops-ke-sath-conditions)
11. [Loop results ko register karna](#11-loop-results-ko-register-karna)
12. [Personal lab ka mukammal example](#12-personal-lab-ka-mukammal-example)
13. [Verification commands](#13-verification-commands)
14. [Idempotency](#14-idempotency)
15. [Aam ghaltiyan](#15-aam-ghaltiyan)
16. [Practice exercises](#16-practice-exercises)
17. [Quick reference](#17-quick-reference)

---

## 1. Loop kya hota hai?

Ansible loop ek hi task ko list ki har value ke liye repeat karta hai. Is se hamein milte-julte tasks baar baar likhne ki zaroorat nahi rehti.

> **Ek line ki definition:** Ansible loop kisi collection ke har item ke liye ek task ko repeat karta hai.

## 2. Loops kyun use kiye jate hain?

Loops hamari madad karte hain:

- Ek se zyada packages install karne mein.
- Ek se zyada users, files ya directories banane mein.
- Ek se zyada services start karne mein.
- Aise structured records process karne mein jin mein multiple properties hon.
- Playbooks ko chhota, saaf aur maintain karne mein asaan banane mein.

## 3. Basic syntax

```yaml
- name: Display course names
  debug:
    msg: "Course: {{ item }}"
  loop:
    - Linux
    - Ansible
    - DevOps
```

`loop:` list rakhta hai aur `{{ item }}` current value ko represent karta hai.

## 4. `item` ko samajhna

Is loop ko dekhein:

```yaml
loop:
  - git
  - curl
  - tree
```

Ansible task ko teen martaba execute karega:

| Execution | `item` ki value |
|---:|---|
| 1 | `git` |
| 2 | `curl` |
| 3 | `tree` |

`item` permanently store nahi hota. Har loop iteration ke dauran Ansible is ki value change karta hai.

## 5. Packages ke sath loop

```yaml
- name: Install required packages
  dnf:
    name: "{{ item }}"
    state: present
  loop:
    - git
    - curl
    - tree
```

Is task mein `dnf` module pehle `git`, phir `curl`, aur phir `tree` ko process karega.

Package modules ke liye poori list seedha module ko dena aam tor par zyada efficient hota hai:

```yaml
- name: Install required packages efficiently
  dnf:
    name:
      - git
      - curl
      - tree
    state: present
```

Loop us waqt use karein jab har item ko alag process karna ho, alag condition lagani ho, alag result chahiye ho, ya items ki properties mukhtalif hon.

## 6. Directories aur files ke loops

### Multiple directories banana

```yaml
- name: Create lab directories
  file:
    path: "/tmp/{{ item }}"
    state: directory
    mode: "0755"
  loop:
    - ansible-lab
    - yaml-lab
    - nginx-lab
```

Yeh task ye directories banayega:

```text
/tmp/ansible-lab
/tmp/yaml-lab
/tmp/nginx-lab
```

### Multiple files banana

```yaml
- name: Create practice files
  file:
    path: "/tmp/ansible-lab/{{ item }}"
    state: touch
    mode: "0644"
  loop:
    - file1.txt
    - file2.txt
    - file3.txt
```

Har iteration mein `item` ek mukhtalif filename rakhega.

## 7. Dictionaries par loop

List ka har item ek dictionary ho sakta hai jis mein kai named values hon:

```yaml
- name: Create student users
  user:
    name: "{{ item.username }}"
    comment: "{{ item.description }}"
    state: present
  loop:
    - username: student1
      description: Linux Student
    - username: student2
      description: Ansible Student
    - username: student3
      description: DevOps Student
```

Har iteration ke dauran:

- `item.username` username read karta hai.
- `item.description` description read karta hai.

### Mukhtalif content wali files banana

```yaml
- name: Create study files
  copy:
    content: "{{ item.content }}\n"
    dest: "/tmp/{{ item.filename }}"
    mode: "0644"
  loop:
    - filename: ansible.txt
      content: Ansible is an automation tool
    - filename: yaml.txt
      content: YAML is a data-serialization language
```

Pehle item se `/tmp/ansible.txt` aur doosre se `/tmp/yaml.txt` banegi.

## 8. Variable ko loop mein use karna

Reusable data ko variable mein rakhna behtar hota hai:

```yaml
vars:
  required_packages:
    - git
    - curl
    - tree

tasks:
  - name: Install required packages
    dnf:
      name: "{{ item }}"
      state: present
    loop: "{{ required_packages }}"
```

Yahan `required_packages` ek list variable hai aur loop is ke har member ko process karta hai.

## 9. `loop_control` se `item` ka naam badalna

Descriptive naam complex loop ko samajhne mein asaan banata hai:

```yaml
- name: Create lab directories
  file:
    path: "/tmp/{{ directory_name }}"
    state: directory
    mode: "0755"
  loop:
    - ansible-lab
    - yaml-lab
    - nginx-lab
  loop_control:
    loop_var: directory_name
```

Ab `directory_name`, `item` ki jagah use hoga.

Output mein useful label bhi dikhaya ja sakta hai:

```yaml
loop_control:
  label: "{{ item.username }}"
```

`label` sirf output ko saaf banata hai; original data ko change nahi karta.

## 10. Loops ke sath conditions

```yaml
- name: Display selected packages
  debug:
    msg: "Selected package: {{ item }}"
  loop:
    - git
    - curl
    - tree
  when: item != "curl"
```

Yeh `curl` ko skip karega aur baqi items ko process karega. Har iteration mein `when` condition dobara evaluate hoti hai.

## 11. Loop results ko register karna

```yaml
- name: Check several files
  stat:
    path: "{{ item }}"
  loop:
    - /etc/hosts
    - /etc/ssh/sshd_config
  register: file_checks

- name: Display all registered results
  debug:
    var: file_checks.results
```

Kyun ke original task loop use karta hai, registered data mein `results` naam ki list hoti hai. Har result ke andar us se related `item` aur module ka result hota hai.

Kisi specific property ko process karne ke liye registered results par dobara loop bhi lagaya ja sakta hai:

```yaml
- name: Display checked paths
  debug:
    msg: "{{ item.item }} exists: {{ item.stat.exists }}"
  loop: "{{ file_checks.results }}"
```

Yahan pehla `item` current result hai aur `item.item` original path hai.

## 12. Personal lab ka mukammal example

Is file ko `/home/ansibleadmin/automation/playbooks/loop-practice.yml` ke naam se save karein:

```yaml
---
- name: Practice loops in the personal Ansible lab
  hosts: three_tier_app
  become: true
  gather_facts: false

  vars:
    lab_directory: /tmp/ansible-loop-lab
    study_files:
      - filename: linux.txt
        content: Linux operating-system practice
      - filename: ansible.txt
        content: Ansible automation practice
      - filename: yaml.txt
        content: YAML syntax practice

  tasks:
    - name: Create the lab directory
      file:
        path: "{{ lab_directory }}"
        state: directory
        mode: "0755"

    - name: Create all study files
      copy:
        content: "{{ item.content }}\n"
        dest: "{{ lab_directory }}/{{ item.filename }}"
        mode: "0644"
      loop: "{{ study_files }}"
      loop_control:
        label: "{{ item.filename }}"
```

Yeh aap ke `three_tier_app` group ko target karta hai jis mein `node1`, `node2`, aur `node3` shamil hain.

## 13. Verification commands

Syntax check karein:

```bash
ansible-playbook playbooks/loop-practice.yml --syntax-check
```

Supported changes ka dry run karein:

```bash
ansible-playbook playbooks/loop-practice.yml --check
```

Playbook run karein:

```bash
ansible-playbook playbooks/loop-practice.yml
```

Additional details ke sath run karein:

```bash
ansible-playbook playbooks/loop-practice.yml -v
```

Files verify karein:

```bash
ansible three_tier_app -m command -a "ls -l /tmp/ansible-loop-lab"
```

Kisi ek host par test karne ke liye:

```bash
ansible-playbook playbooks/loop-practice.yml --limit node1
```

## 14. Idempotency

Idempotent task sirf us waqt change karta hai jab desired state mojood na ho. Agar files pehle se correct content aur permissions ke sath mojood hon, to playbook ki doosri run mein un tasks ke liye aam tor par `changed=0` aana chahiye.

Loop khud idempotency guarantee nahi karta. Idempotency ka daromadar module aur task likhne ke tareeqe par hota hai. `file`, `copy`, `user`, aur `dnf` jaise modules state ko idempotent tareeqe se manage karne ke liye design kiye gaye hain.

Misal ke taur par, `shell` task har run par `CHANGED` dikha sakta hai chahe us ne asal mein koi tabdeeli na ki ho. Is liye jahan mumkin ho, purpose-built module use karein.

## 15. Aam ghaltiyan

### Curly braces na lagana

Ghalat:

```yaml
name: item
```

Sahih:

```yaml
name: "{{ item }}"
```

### Ghalat indentation

`loop:` task level par module ke naam ke barabar aligned hota hai:

```yaml
- name: Correct example
  debug:
    msg: "{{ item }}"
  loop:
    - one
    - two
```

### Missing dictionary key ko reference karna

Agar data mein key `username` hai to `item.username` use karein, `item.name` nahi.

### Bila zaroorat loop use karna

Package modules ko aam tor par poori package list ek hi task mein di ja sakti hai.

### Variable list ko quote na karna

Recommended:

```yaml
loop: "{{ required_packages }}"
```

### `item` conflict

Nested includes ya complex loops mein `item` conflict ho sakta hai. `loop_control.loop_var` se meaningful aur unique naam use karein.

## 16. Practice exercises

1. Ek loop se `/tmp/student1`, `/tmp/student2`, aur `/tmp/student3` banayein.
2. List variable use karke teen users banayein.
3. Dictionaries use karke mukhtalif names, content aur modes wali do files banayein.
4. `/etc/hosts` aur `/etc/passwd` ko check karein aur results register karein.
5. Playbook ko do martaba run karke `changed` values compare karein.
6. `loop_control.loop_var` se `item` ka naam `student_name` rakhein.
7. `when` condition se list ka ek item skip karein.

## 17. Quick reference

| Term | Matlab |
|---|---|
| `loop` | Woh collection jise Ansible process karta hai |
| `item` | Har iteration ki current value |
| `loop_control` | Loop ke display ya behavior ko control karta hai |
| `loop_var` | `item` ka naam replace karta hai |
| `label` | Output mein dikhne wale item label ko control karta hai |
| `register` | Task results ko variable mein save karta hai |
| `results` | Registered loop se paida hone wale results ki list |
| `when` | Har item par condition lagata hai |

