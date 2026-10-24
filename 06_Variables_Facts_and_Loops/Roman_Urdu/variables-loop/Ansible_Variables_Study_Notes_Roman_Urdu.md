# Ansible Variables — Roman Urdu Study Notes

## Index

1. [Variable kya hota hai?](#1-variable-kya-hota-hai)
2. [Variables kyun use kiye jate hain?](#2-variables-kyun-use-kiye-jate-hain)
3. [Variable naming rules](#3-variable-naming-rules)
4. [Variables define aur reference karna](#4-variables-define-aur-reference-karna)
5. [Aam variable data types](#5-aam-variable-data-types)
6. [Variables aur loops](#6-variables-aur-loops)
7. [Inventory variables](#7-inventory-variables)
8. [`group_vars` aur `host_vars`](#8-group_vars-aur-host_vars)
9. [External variable files](#9-external-variable-files)
10. [Registered variables](#10-registered-variables)
11. [Ansible facts](#11-ansible-facts)
12. [Magic variables](#12-magic-variables)
13. [Command-line extra variables](#13-command-line-extra-variables)
14. [Default values aur filters](#14-default-values-aur-filters)
15. [Variable precedence](#15-variable-precedence)
16. [Sensitive variables](#16-sensitive-variables)
17. [Personal lab ka mukammal example](#17-personal-lab-ka-mukammal-example)
18. [Variables check karne ke commands](#18-variables-check-karne-ke-commands)
19. [Aam ghaltiyan](#19-aam-ghaltiyan)
20. [Practice exercises](#20-practice-exercises)
21. [Quick reference](#21-quick-reference)

---

## 1. Variable kya hota hai?

Ansible variable ek named value hoti hai jo reusable information store karti hai, jaise username, package name, file path, IP address, port number, list ya dictionary.

> **Ek line ki definition:** Ansible variable ek value ko naam ke sath store karta hai taa-ke automation ke dauran usay reference aur reuse kiya ja sake.

## 2. Variables kyun use kiye jate hain?

Variables playbooks ko:

- Mukhtalif systems par reusable banate hain.
- Update karna asaan banate hain.
- Repeated values ko kam karte hain.
- Read aur maintain karna asaan banate hain.
- Mukhtalif groups, hosts aur environments ke liye munasib banate hain.

Misal ke taur par `/tmp/ansible-lab` ko har task mein dobara likhne ke bajaye ek martaba variable mein define karein aur jahan zaroorat ho usay reference karein.

## 3. Variable naming rules

Achhe variable names:

```yaml
web_package: nginx
http_port: 80
lab_directory: /tmp/ansible-lab
```

Recommendations:

- Naam letter se shuru karein.
- Letters, numbers aur underscores use karein.
- Descriptive lowercase names use karein.
- Normal variable names mein spaces ya hyphens use na karein.
- Aise names se bachein jo Ansible playbook keywords se conflict karein.

In names se bachein:

```yaml
web-package: nginx
lab directory: /tmp/lab
```

## 4. Variables define aur reference karna

Play variables ko `vars:` ke neeche define karein:

```yaml
---
- name: Practice variables
  hosts: three_tier_app
  gather_facts: false

  vars:
    lab_directory: /tmp/ansible-lab
    lab_file: notes.txt
    file_mode: "0644"

  tasks:
    - name: Create the lab directory
      file:
        path: "{{ lab_directory }}"
        state: directory
        mode: "0755"

    - name: Create the study file
      copy:
        content: "Created with Ansible variables.\n"
        dest: "{{ lab_directory }}/{{ lab_file }}"
        mode: "{{ file_mode }}"
```

Variable expressions Jinja syntax use karti hain:

```yaml
"{{ variable_name }}"
```

Jab YAML value `{{` se shuru ho to poori value ko quotes mein likhein.

## 5. Aam variable data types

### String

String text value hoti hai:

```yaml
web_package: nginx
```

### Number

```yaml
http_port: 80
```

### Boolean

```yaml
enable_service: true
```

Clarity ke liye `true` aur `false` use karein.

### List

List ordered values ka collection hoti hai:

```yaml
required_packages:
  - git
  - curl
  - tree
```

Yahan `required_packages` parent key aur `git`, `curl`, `tree` list items hain.

### Dictionary

Dictionary named key-value pairs rakhti hai:

```yaml
student:
  name: Khalid
  course: Ansible
  city: Chicago
```

`student` parent mapping hai, jab ke `name`, `course`, aur `city` is ki child keys hain.

Dictionary members ko dot notation se reference karein:

```yaml
msg: "{{ student.name }} studies {{ student.course }}."
```

Bracket notation bhi valid hai:

```yaml
msg: "{{ student['name'] }}"
```

### List of dictionaries

```yaml
student_accounts:
  - username: student1
    description: Linux Student
  - username: student2
    description: Ansible Student
```

Yahan `student_accounts` ek list hai aur har list item ek dictionary hai.

## 6. Variables aur loops

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

- `required_packages` list ko store karta hai.
- `loop` us list ko read karta hai.
- `item` current package ko represent karta hai.

## 7. Inventory variables

Aap ki INI inventory connection variables rakh sakti hai:

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

| Variable | Maqsad |
|---|---|
| `ansible_host` | Woh address jis se Ansible host tak pohanchta hai |
| `ansible_user` | Remote SSH username |
| `ansible_port` | Remote SSH port, aam tor par `22` |
| `ansible_ssh_private_key_file` | SSH ke liye private key ka path |
| `ansible_python_interpreter` | Managed node par Python executable |

Inventory alias aur real address mein farq:

```ini
node1 ansible_host=192.168.1.154
```

- `node1` inventory hostname hai.
- `192.168.1.154` connection address hai.
- Playbook mein `inventory_hostname` ki value `node1` hogi.

## 8. `group_vars` aur `host_vars`

Recommended structure:

```text
/home/ansibleadmin/automation/
├── ansible.cfg
├── inventory/
│   ├── nodes
│   ├── group_vars/
│   │   ├── all.yml
│   │   └── web.yml
│   └── host_vars/
│       └── node1.yml
└── playbooks/
```

### `group_vars` aur `host_vars` ko `inventory/` ke neeche kyun rakhein?

- Aap ka configured inventory source `/home/ansibleadmin/automation/inventory` hai.
- Variable directories ko inventory source ke sath rakhne se un ka relationship saaf samajh aata hai.
- Ansible ke vars plugins us inventory ke sath associated group aur host files discover kar sakte hain.

### Har host ke variables

`inventory/group_vars/all.yml`:

```yaml
---
ansible_user: ansibleadmin
ansible_python_interpreter: /usr/bin/python3
lab_directory: /tmp/ansible-lab
```

### Sirf `web` group ke variables

`inventory/group_vars/web.yml`:

```yaml
---
web_package: nginx
web_service: nginx
http_port: 80
```

`web` group ka har host yeh values hasil karega.

### Sirf `node1` ke variables

`inventory/host_vars/node1.yml`:

```yaml
---
server_role: web
site_title: Node1 Training Website
```

Yeh variables sirf `node1` par apply honge.

## 9. External variable files

`/home/ansibleadmin/automation/vars/lab-vars.yml` banayein:

```yaml
---
lab_directory: /tmp/ansible-study
lab_file: notes.txt
lab_content: Ansible variables make playbooks reusable.
```

Isay `vars_files` ke sath load karein:

```yaml
---
- name: Use an external variable file
  hosts: three_tier_app
  gather_facts: false

  vars_files:
    - ../vars/lab-vars.yml

  tasks:
    - name: Create the lab directory
      file:
        path: "{{ lab_directory }}"
        state: directory
        mode: "0755"

    - name: Create the study file
      copy:
        content: "{{ lab_content }}\n"
        dest: "{{ lab_directory }}/{{ lab_file }}"
        mode: "0644"
```

File copy hone se pehle directory create ki gayi hai. Agar parent directory mojood na ho to `copy` task fail ho sakta hai.

## 10. Registered variables

`register` kisi task ka result save karta hai:

```yaml
- name: Check system uptime
  command: uptime
  register: uptime_result
  changed_when: false

- name: Display uptime
  debug:
    var: uptime_result.stdout
```

Common registered-result properties:

| Property | Matlab |
|---|---|
| `stdout` | Command ka normal output |
| `stderr` | Error output |
| `rc` | Return code; `0` aam tor par success hota hai |
| `changed` | Ansible ne change report kiya ya nahi |
| `failed` | Task fail hua ya nahi |

Yahan `changed_when: false` munasib hai kyun ke `uptime` sirf information read karta hai aur system ko change nahi karta.

Registered variable sirf current playbook run ke dauran mojood hota hai; yeh automatically permanent file mein save nahi hota.

## 11. Ansible facts

Facts woh variables hain jo fact gathering enabled hone par Ansible managed nodes se automatically discover karta hai:

```yaml
gather_facts: true
```

Example:

```yaml
- name: Display operating-system information
  debug:
    msg: >-
      {{ inventory_hostname }} runs
      {{ ansible_distribution }}
      {{ ansible_distribution_version }}.
```

`>-` folded block scalar hai. Yeh multiple YAML lines ko mila kar ek single-line string banata hai aur aakhir ka newline remove kar deta hai.

Common facts:

| Fact | Matlab |
|---|---|
| `ansible_distribution` | Operating-system ka naam |
| `ansible_distribution_version` | OS version |
| `ansible_hostname` | Managed node ka hostname |
| `ansible_architecture` | CPU architecture |
| `ansible_memtotal_mb` | Total memory MB mein |
| `ansible_processor_vcpus` | Virtual CPUs ki tadaad |
| `ansible_default_ipv4.address` | Primary IPv4 address |

Ad-hoc command se facts display karein:

```bash
ansible node1 -m setup
```

Output filter karein:

```bash
ansible node1 -m setup -a "filter=ansible_distribution*"
```

## 12. Magic variables

Ansible kuch special variables automatically provide karta hai:

| Variable | Matlab |
|---|---|
| `inventory_hostname` | Current host ka woh naam jo inventory mein likha hai |
| `groups` | Inventory groups aur members wali dictionary |
| `group_names` | Woh groups jin ka current host member hai |
| `hostvars` | Inventory hosts se related variables |
| `playbook_dir` | Current playbook wali directory |

`inventory_hostname` ko fact gathering ki zaroorat nahi hoti:

```yaml
- name: Display inventory hostname
  debug:
    msg: "Currently running on {{ inventory_hostname }}"
```

`inventory_hostname` aur `ansible_hostname` ek jaisi cheez zaroori nahi:

- `inventory_hostname` inventory ka naam hai, jaise `node1`.
- `ansible_hostname` managed machine se gathered actual short hostname hai.

## 13. Command-line extra variables

`-e` ya `--extra-vars` use karein:

```bash
ansible-playbook playbooks/create-file.yml \
  -e "lab_directory=/tmp/student-lab"
```

Multiple values pass karein:

```bash
ansible-playbook playbooks/create-file.yml \
  -e "lab_directory=/tmp/student-lab lab_file=homework.txt"
```

JSON data types ko zyada reliably preserve karta hai:

```bash
ansible-playbook playbooks/create-file.yml \
  -e '{"lab_directory":"/tmp/student-lab","cleanup":true}'
```

Extra variables ki precedence bohat high hoti hai, is liye yeh zyada tar doosri locations mein defined values ko override kar sakte hain.

## 14. Default values aur filters

Agar variable undefined ho sakta ho to `default` filter use karein:

```yaml
- name: Display course name
  debug:
    msg: "Course: {{ course_name | default('Ansible Basics') }}"
```

Agar `course_name` defined nahi hai to output mein `Ansible Basics` use hoga.

Kuch useful filters:

```yaml
"{{ student_name | upper }}"
"{{ package_list | length }}"
"{{ value | default('fallback') }}"
```

- `upper` text ko uppercase banata hai.
- `length` list ya string ki length deta hai.
- `default` fallback value deta hai.

## 15. Variable precedence

Ek hi variable kai locations mein define ho sakta hai. Ansible precedence rules se decide karta hai ke kaunsi value use hogi.

Beginner ke liye lower se higher precedence ka simplified order:

1. Role defaults
2. Inventory group variables
3. Inventory host variables
4. Play variables aur `vars_files`
5. Task variables
6. Command-line extra variables (`-e`)

Ansible ka full precedence system is se zyada levels rakhta hai. Shuruati practice ke liye yaad rakhein ke `-e` aam tor par aap ki doosri variable definitions ko override karta hai.

Jab tak intentionally override na karna ho, ek hi variable ko bohat si jagahon par define na karein. Is se troubleshooting mushkil ho sakti hai.

## 16. Sensitive variables

Plain-text passwords ya secret keys ko public repository mein store na karein. Sensitive values ke liye Ansible Vault use karein:

```bash
ansible-vault create vars/secrets.yml
```

Encrypted variable file use karne wala playbook run karein:

```bash
ansible-playbook playbooks/site.yml --ask-vault-pass
```

Existing file encrypt karne ke liye:

```bash
ansible-vault encrypt vars/secrets.yml
```

Encrypted file edit karne ke liye:

```bash
ansible-vault edit vars/secrets.yml
```

## 17. Personal lab ka mukammal example

Isay `/home/ansibleadmin/automation/playbooks/variables-practice.yml` ke naam se save karein:

```yaml
---
- name: Practice variables in the personal Ansible lab
  hosts: three_tier_app
  become: true
  gather_facts: true

  vars:
    lab_directory: /tmp/ansible-variable-lab
    file_mode: "0644"
    study_files:
      - filename: system.txt
        content: >-
          {{ inventory_hostname }} runs
          {{ ansible_distribution }}
          {{ ansible_distribution_version }}.
      - filename: course.txt
        content: Ansible variables and loops practice.

  tasks:
    - name: Create the lab directory
      file:
        path: "{{ lab_directory }}"
        state: directory
        mode: "0755"

    - name: Create study files
      copy:
        content: "{{ item.content }}\n"
        dest: "{{ lab_directory }}/{{ item.filename }}"
        mode: "{{ file_mode }}"
      loop: "{{ study_files }}"
      loop_control:
        label: "{{ item.filename }}"

    - name: Display the lab result
      debug:
        msg: "Files were created in {{ lab_directory }} on {{ inventory_hostname }}."
```

Is example mein:

- `lab_directory` simple string variable hai.
- `file_mode` permission value hai aur quotes mein likhi gayi hai.
- `study_files` dictionaries ki list hai.
- Facts OS ki information provide karte hain.
- Loop har file ko process karta hai.
- `inventory_hostname` current inventory host ka naam deta hai.

## 18. Variables check karne ke commands

Syntax check karein:

```bash
ansible-playbook playbooks/variables-practice.yml --syntax-check
```

Dry run karein:

```bash
ansible-playbook playbooks/variables-practice.yml --check
```

Verbose output ke sath run karein:

```bash
ansible-playbook playbooks/variables-practice.yml -v
```

Ek inventory host ko assigned variables display karein:

```bash
ansible-inventory --host node1
```

Inventory graph display karein:

```bash
ansible-inventory --graph
```

Ad-hoc command se variable display karein:

```bash
ansible node1 -m debug -a "var=inventory_hostname"
```

Specific fact display karein:

```bash
ansible node1 -m debug -a "var=ansible_distribution"
```

Yaad rakhein ke fact variable ad-hoc `debug` command mein pehle gather na hua ho. Is surat mein `setup` module use karein:

```bash
ansible node1 -m setup -a "filter=ansible_distribution"
```

## 19. Aam ghaltiyan

### Jinja se shuru hone wali value ko quote na karna

Ghalat:

```yaml
path: {{ lab_directory }}
```

Sahih:

```yaml
path: "{{ lab_directory }}"
```

### Variable name ki spelling ghalat hona

`lab_directory` aur `lab_directry` do mukhtalif variables hain.

### Facts disabled hone ke bawajood fact use karna

Agar `gather_facts: false` ho to `ansible_distribution` jaise facts undefined ho sakte hain jab tak unhein alag se gather na kiya gaya ho.

### Inventory variables aur facts ko confuse karna

- `inventory_hostname` inventory se aata hai aur facts ki zaroorat nahi.
- `ansible_hostname` aam tor par gathered fact hai.

### Secrets ko normal YAML mein rakhna

Passwords aur doosre confidential data ke liye Ansible Vault use karein.

### File modes ko number samajhna

Permission values ko quote karna behtar hai:

```yaml
mode: "0644"
```

### Undefined variable

Variable define na ho ya naam ghalat ho to task fail ho sakta hai. Zaroorat par `default` filter use karein.

## 20. Practice exercises

1. Directory name, filename, content aur mode ke variables define karein.
2. Variables ko `vars/lab-vars.yml` mein move karke `vars_files` se load karein.
3. `group_vars/web.yml` mein `web_package: nginx` add karein.
4. Har host ki `host_vars` file mein mukhtalif `server_role` add karein.
5. `uptime` ka output register karke sirf `stdout` display karein.
6. Facts use karke OS name aur primary IPv4 address display karein.
7. `-e` se play variable override karein aur result observe karein.
8. Ansible Vault mein ek practice secret create karein.
9. `inventory_hostname` aur `ansible_hostname` ka output compare karein.

## 21. Quick reference

| Term | Matlab |
|---|---|
| `vars` | Play ke andar variables define karta hai |
| `vars_files` | Doosri YAML file se variables load karta hai |
| `group_vars` | Inventory group ko assigned variables |
| `host_vars` | Ek inventory host ko assigned variables |
| `register` | Task result ko variable mein store karta hai |
| Facts | System information jo Ansible discover karta hai |
| Magic variables | Special variables jo Ansible provide karta hai |
| `-e` | Command line se extra variables pass karta hai |
| `default` | Undefined value ke liye fallback provide karta hai |
| Ansible Vault | Sensitive Ansible data ko encrypt karta hai |
