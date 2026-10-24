# Ansible Reusable Task Files: `include_tasks` aur `import_tasks` — Roman Urdu

## Fehrist (Table of Contents)

1. [Learning objectives](#1-learning-objectives)
2. [Lab ki requirement](#2-lab-ki-requirement)
3. [Recommended project structure](#3-recommended-project-structure)
4. [Task file kya hoti hai?](#4-task-file-kya-hoti-hai)
5. [Reusable copy task file banana](#5-reusable-copy-task-file-banana)
6. [Main playbook banana](#6-main-playbook-banana)
7. [Dono files mil kar kaise kaam karti hain?](#7-dono-files-mil-kar-kaise-kaam-karti-hain)
8. [`include_tasks` ki wazahat](#8-include_tasks-ki-wazahat)
9. [`include_tasks` aur `import_tasks` ka farq](#9-include_tasks-aur-import_tasks-ka-farq)
10. [Original YAML mein masail](#10-original-yaml-mein-masail)
11. [`file` aur `copy` module ka farq](#11-file-aur-copy-module-ka-farq)
12. [Files ko validate karna](#12-files-ko-validate-karna)
13. [Playbook run karna](#13-playbook-run-karna)
14. [Results verify karna](#14-results-verify-karna)
15. [Idempotency samajhna](#15-idempotency-samajhna)
16. [Reusable task mein variables istemal karna](#16-reusable-task-mein-variables-istemal-karna)
17. [Ek task file ko multiple playbooks mein use karna](#17-ek-task-file-ko-multiple-playbooks-mein-use-karna)
18. [Common errors aur solutions](#18-common-errors-aur-solutions)
19. [Cleanup](#19-cleanup)
20. [Quick-reference commands](#20-quick-reference-commands)
21. [Practice questions](#21-practice-questions)
22. [Khulasa](#22-khulasa)

---

## 1. Learning objectives

Is lesson ke baad aap:

- Main playbook se kuch tasks ko separate file mein rakh saken ge.
- `include_tasks` ke zariye task file ko reuse kar saken ge.
- Playbook aur task file ka farq samajh saken ge.
- Directory, empty file aur content wali file ke liye sahi module select kar saken ge.
- Ghalat indentation aur ghalat module arguments ko pehchan saken ge.
- Multi-file playbook ko validate, run aur verify kar saken ge.
- `include_tasks` aur `import_tasks` ka basic farq samajh saken ge.

---

## 2. Lab ki requirement

Hum chahte hain ke main playbook inventory ke tamam target hosts par:

1. `/tmp/yaml-study-lab` directory banaye.
2. `abc.txt` naam ki empty file banaye.
3. Doosri YAML file se `copy` task load kare.
4. Study content ke saath `notes.txt` banaye.
5. Har managed node ka inventory name `notes.txt` mein likhe.

Har task ko ek hi bari playbook mein rakhne ke bajaye, hum copy task ko separate reusable task file mein rakhen ge.

---

## 3. Recommended project structure

```text
/home/ansibleadmin/automation/
├── ansible.cfg
├── inventory/
├── playbooks/
│   ├── 02_create-dir-file.yml
│   └── tasks/
│       └── create-study-file.yml
└── roles/
```

Task directory banayen:

```bash
mkdir -p /home/ansibleadmin/automation/playbooks/tasks
```

### `tasks` directory kyun use karte hain?

- Reusable tasks complete playbooks se alag aur organized rehte hain.
- Project ko samajhna asaan hota hai.
- Ek hi task file ko multiple playbooks reuse kar sakti hain.
- Yeh structure aapko future mein Ansible roles samajhne mein madad deta hai.

---

## 4. Task file kya hoti hai?

**Task file** ek YAML file hoti hai jis mein ek ya zyada Ansible tasks ki list hoti hai.

Task file mein aam tor par yeh play-level keywords nahi hote:

```yaml
hosts:
gather_facts:
tasks:
```

Task file seedha tasks ki YAML list se start hoti hai:

```yaml
---
- name: Example task
  copy:
    content: Example
    dest: /tmp/example.txt
```

Main playbook target hosts define karti hai aur phir task file ko include ya import karti hai.

### Playbook aur task file ka farq

| Cheez | Complete playbook | Task file |
|---|---|---|
| `hosts:` | Hota hai | Aam tor par nahi hota |
| `tasks:` | Hota hai | Nahi hota; file khud task list hoti hai |
| Direct `ansible-playbook` se run | Haan | Nahi; main playbook load karti hai |
| Maqsad | Complete automation define karna | Tasks ko organize aur reuse karna |

---

## 5. Reusable copy task file banana

File banayen:

```bash
vim /home/ansibleadmin/automation/playbooks/tasks/create-study-file.yml
```

Is mein likhen:

```yaml
---
- name: Create a study file with content
  copy:
    content: |
      YAML is a data format.
      Ansible uses YAML to structure playbooks.
      Inventory host: {{ inventory_hostname }}
    dest: /tmp/yaml-study-lab/notes.txt
    mode: "0644"
```

### Line-by-line samjhain

| Line | Matlab |
|---|---|
| `---` | YAML document ka optional start marker hai. |
| `- name:` | Naya task start karta hai aur us ka readable naam deta hai. |
| `copy:` | Ansible copy module use karta hai. |
| `content: \|` | Multiple lines ka content deta hai aur line breaks preserve karta hai. |
| `{{ inventory_hostname }}` | Current managed host ka inventory name insert karta hai. |
| `dest:` | Managed node par destination file ka path set karta hai. |
| `mode: "0644"` | Owner ko read/write aur group/others ko read permission deta hai. |

`0644` ko quotes mein likhna behtar hai taa-ke YAML isay permission string samjhe.

---

## 6. Main playbook banana

Main playbook create ya correct karein:

```bash
vim /home/ansibleadmin/automation/playbooks/02_create-dir-file.yml
```

Correct playbook:

```yaml
---
- name: Create a directory and files
  hosts: all
  gather_facts: false

  tasks:
    - name: Create the lab directory
      file:
        path: /tmp/yaml-study-lab
        state: directory
        mode: "0755"

    - name: Create an empty abc.txt file
      file:
        path: /tmp/yaml-study-lab/abc.txt
        state: touch
        mode: "0644"

    - name: Include the study-file tasks
      include_tasks: tasks/create-study-file.yml
```

`include_tasks` ka relative path us playbook ke location ke mutabiq resolve hota hai jis mein include statement likha ho.

Main playbook `playbooks/` directory mein hai aur reusable file `playbooks/tasks/` mein hai, is liye correct relative path hai:

```text
tasks/create-study-file.yml
```

---

## 7. Dono files mil kar kaise kaam karti hain?

Execution order yeh hoga:

1. Ansible `02_create-dir-file.yml` read karega.
2. Play inventory ke `all` hosts ko target karega.
3. Pehla task `/tmp/yaml-study-lab` directory banaye ga.
4. Doosra task `abc.txt` create ya touch karega.
5. `include_tasks` runtime par `create-study-file.yml` load karega.
6. Included `copy` task `notes.txt` banaye ga.
7. `inventory_hostname` har managed node ke liye alag evaluate hoga.

Example:

```text
node1 -> Inventory host: node1
node2 -> Inventory host: node2
node3 -> Inventory host: node3
```

---

## 8. `include_tasks` ki wazahat

One-line definition:

> `include_tasks` playbook run hote waqt doosri YAML file se tasks ki list dynamically load karta hai.

Syntax:

```yaml
- name: Include another task file
  include_tasks: tasks/create-study-file.yml
```

### Faide

- Main playbook chhoti aur readable rehti hai.
- Tasks reusable ho jate hain.
- Runtime conditions aur loops ke saath use kiya ja sakta hai.
- Bari automation ko organized parts mein divide kiya ja sakta hai.

Condition ke saath example:

```yaml
- name: Include study-file tasks on Rocky Linux
  include_tasks: tasks/create-study-file.yml
  when: ansible_distribution == "Rocky"
```

`ansible_distribution` ek gathered fact hai. Is example ke liye fact gathering enabled honi chahiye, ya fact kisi aur tareeqe se available hona chahiye.

---

## 9. `include_tasks` aur `import_tasks` ka farq

| Feature | `include_tasks` | `import_tasks` |
|---|---|---|
| Nature | Dynamic | Static |
| Tasks kab load hote hain? | Playbook execution ke waqt | Playbook parse hone ke waqt |
| Runtime conditions/loops | Zyada flexible | Fixed organization ke liye behtar |
| Best use | Runtime choice, loops, dynamic workflow | Pehle se fixed aur hamesha required tasks |

Dynamic include:

```yaml
- name: Dynamically include tasks
  include_tasks: tasks/create-study-file.yml
```

Static import:

```yaml
- name: Statically import tasks
  import_tasks: tasks/create-study-file.yml
```

Is beginner lab mein `include_tasks` use karna asaan hai. Agar file har run mein lazmi load honi ho aur koi dynamic selection na ho, to `import_tasks` bhi theek hai.

---

## 10. Original YAML mein masail

Original section kuch is tarah tha:

```yaml
- name: Creating a file
  file:
    path: /tmp/yaml-study-lab/abc.txt
    state: touch
    mode: "0644"

    dest: /tmp/yaml-study-lab/notes.txt
    mode: "0644"
```

Is mein teen important problems hain.

### Problem 1: `dest` ghalat module ke neeche hai

`file` module mein is kaam ke liye `dest` argument nahi hota. `dest` yahan `copy` module ke neeche hona chahiye.

### Problem 2: `mode` duplicate hai

Ek hi YAML mapping level par same key do dafa nahi honi chahiye. Duplicate `mode` configuration ko ambiguous banata hai aur linter error de sakta hai.

### Problem 3: Copy content maujood nahi

Text ke saath file banane ke liye `copy` module mein `content` aur `dest` dono chahiye.

Correct example:

```yaml
- name: Create a file containing text
  copy:
    content: |
      Example text
    dest: /tmp/yaml-study-lab/notes.txt
    mode: "0644"
```

---

## 11. `file` aur `copy` module ka farq

| Requirement | Suitable module |
|---|---|
| Directory create karna | `file` with `state: directory` |
| Empty file ka timestamp create/update karna | `file` with `state: touch` |
| Ownership ya permissions manage karna | `file` ya resource create karne wala module |
| Inline text ke saath file create karna | `copy` with `content` |
| Control node ki file managed nodes par bhejna | `copy` with `src` and `dest` |
| Jinja template se dynamic file generate karna | `template` |

Directory example:

```yaml
- name: Create a directory
  file:
    path: /tmp/example
    state: directory
```

Content file example:

```yaml
- name: Copy inline content
  copy:
    content: "Hello\n"
    dest: /tmp/example/hello.txt
```

---

## 12. Files ko validate karna

Project directory mein jayen taa-ke local `ansible.cfg` use ho:

```bash
cd /home/ansibleadmin/automation
```

Files display karein:

```bash
sed -n '1,200p' playbooks/02_create-dir-file.yml
sed -n '1,200p' playbooks/tasks/create-study-file.yml
```

Syntax check:

```bash
ansible-playbook --syntax-check playbooks/02_create-dir-file.yml
```

Expected ending:

```text
playbook: playbooks/02_create-dir-file.yml
```

Ansible Lint installed ho to:

```bash
ansible-lint playbooks/02_create-dir-file.yml
```

`--syntax-check` check karta hai ke Ansible playbook ko parse kar sakta hai. `ansible-lint` style, maintainability aur recommended practices ke rules bhi check karta hai.

Aap ke lab mein short module names (`file:`, `copy:`) valid hain. Linter Fully Qualified Collection Names recommend kar sakta hai, jo style recommendation hai.

---

## 13. Playbook run karna

Automation directory se run karein:

```bash
cd /home/ansibleadmin/automation
ansible-playbook playbooks/02_create-dir-file.yml
```

Pehle sirf `node1` par test:

```bash
ansible-playbook playbooks/02_create-dir-file.yml --limit node1
```

Possible changes ka preview:

```bash
ansible-playbook playbooks/02_create-dir-file.yml --check --diff
```

Verbose troubleshooting:

```bash
ansible-playbook -v playbooks/02_create-dir-file.yml
```

### Options ka matlab

| Option | Matlab |
|---|---|
| `--limit node1` | Play ke targets ko temporary tor par sirf `node1` tak restrict karta hai. |
| `--check` | Jahan modules support karein, changes apply kiye baghair dry run karta hai. |
| `--diff` | File content waghera ka before/after difference dikhata hai. |
| `-v` | Extra execution details dikhata hai. |

---

## 14. Results verify karna

Directory list karein:

```bash
ansible all -m command -a "ls -l /tmp/yaml-study-lab"
```

`notes.txt` read karein:

```bash
ansible all -m command -a "cat /tmp/yaml-study-lab/notes.txt"
```

Dono files ka detailed status dekhein:

```bash
ansible all -m command -a "stat /tmp/yaml-study-lab/abc.txt /tmp/yaml-study-lab/notes.txt"
```

Expected resources:

```text
/tmp/yaml-study-lab/
├── abc.txt
└── notes.txt
```

Har managed node ke `notes.txt` mein usi node ka `inventory_hostname` hoga.

---

## 15. Idempotency samajhna

`copy` task idempotent hai. Agar `notes.txt` ka content aur mode pehle se desired state mein hon, dobara run par task aam tor par `ok` report karega, `changed` nahi.

Lekin:

```yaml
state: touch
```

file ka access aur modification timestamp update kar sakta hai. Is liye `abc.txt` task har run par `changed` report kar sakta hai.

Agar empty `abc.txt` ki zaroorat nahi, to us task ko remove kar dein aur sirf idempotent `copy` task se `notes.txt` banayen.

Agar `abc.txt` sirf missing hone par create karni hai:

```yaml
- name: Check whether abc.txt exists
  stat:
    path: /tmp/yaml-study-lab/abc.txt
  register: abc_file

- name: Create abc.txt only when missing
  file:
    path: /tmp/yaml-study-lab/abc.txt
    state: touch
    mode: "0644"
  when: not abc_file.stat.exists
```

Is flow mein:

1. `stat` file ki current information leta hai.
2. Result `abc_file` variable mein register hota hai.
3. Doosra task sirf tab run hota hai jab file exist nahi karti.

---

## 16. Reusable task mein variables istemal karna

Variables task file ko aur reusable bana dete hain.

Main playbook:

```yaml
---
- name: Create a directory and study file
  hosts: all
  gather_facts: false

  vars:
    study_directory: /tmp/yaml-study-lab
    study_filename: notes.txt

  tasks:
    - name: Create the study directory
      file:
        path: "{{ study_directory }}"
        state: directory
        mode: "0755"

    - name: Include the study-file tasks
      include_tasks: tasks/create-study-file.yml
```

Reusable task file:

```yaml
---
- name: Create a study file with content
  copy:
    content: |
      YAML is a data format.
      Ansible uses YAML to structure playbooks.
      Inventory host: {{ inventory_hostname }}
    dest: "{{ study_directory }}/{{ study_filename }}"
    mode: "0644"
```

Ab main playbook directory aur filename control kar sakti hai, reusable task ko edit karne ki zaroorat nahi.

---

## 17. Ek task file ko multiple playbooks mein use karna

Same `playbooks` directory ki koi aur playbook bhi task file ko reuse kar sakti hai:

```yaml
---
- name: Create study notes on the web group
  hosts: web
  gather_facts: false

  tasks:
    - name: Ensure the destination directory exists
      file:
        path: /tmp/yaml-study-lab
        state: directory
        mode: "0755"

    - name: Reuse the study-file tasks
      include_tasks: tasks/create-study-file.yml
```

Important: `copy` module destination file create kar sakta hai, lekin missing parent directory automatically create nahi karta. Is liye directory pehle exist karni chahiye.

---

## 18. Common errors aur solutions

### Error: `conflicting action statements`

Cause: Ek task mein do modules likh diye gaye.

Incorrect:

```yaml
- name: Incorrect task
  file:
    path: /tmp/example
  copy:
    content: Test
```

Solution: `file` aur `copy` ko separate tasks banayen.

### Error: `unsupported parameters for (file) module: dest`

Cause: `dest` ko `file` module ke neeche likha gaya.

Solution: `file` ke saath `path` use karein, ya `dest` ko `copy` ke neeche move karein.

### Error: Included file nahi mil rahi

File verify karein:

```bash
ls -l /home/ansibleadmin/automation/playbooks/tasks/create-study-file.yml
```

Correct relative path:

```yaml
include_tasks: tasks/create-study-file.yml
```

### Error: Destination directory exist nahi karti

Cause: `copy` parent directories create nahi karta.

Solution: Copy task se pehle directory task run karein.

### Error: YAML indentation

Tabs ke bajaye spaces use karein. Module arguments ko module name ke neeche indent karein:

```yaml
- name: Correct indentation
  copy:
    content: Example
    dest: /tmp/example.txt
```

### Error: Duplicate key `mode`

Ek hi mapping level par sirf ek `mode` rakhein. Directory aur file ke modes ko un ke separate tasks mein likhein.

### Error: `inventory_hostname` undefined

`inventory_hostname` aam tor par `gather_facts: false` ke bawajood inventory hosts ke liye available hota hai. Inventory check karein:

```bash
ansible-inventory --graph
ansible all --list-hosts
```

---

## 19. Cleanup

Delete karne se pehle exact target verify karein:

```bash
ansible all -m command -a "ls -ld /tmp/yaml-study-lab"
```

Complete lab directory ko idempotent `file` module se remove karein:

```bash
ansible all -m file -a "path=/tmp/yaml-study-lab state=absent"
```

Verify:

```bash
ansible all -m command -a "test ! -e /tmp/yaml-study-lab"
```

Jab directory exist nahi karti to verification command successful return hoti hai.

---

## 20. Quick-reference commands

```bash
# Task directory banayen
mkdir -p ~/automation/playbooks/tasks

# Main playbook edit karein
vim ~/automation/playbooks/02_create-dir-file.yml

# Reusable task file edit karein
vim ~/automation/playbooks/tasks/create-study-file.yml

# Project directory mein jayen
cd ~/automation

# Inventory check karein
ansible-inventory --graph

# Syntax check
ansible-playbook --syntax-check playbooks/02_create-dir-file.yml

# Lint check
ansible-lint playbooks/02_create-dir-file.yml

# Dry run aur diff
ansible-playbook --check --diff playbooks/02_create-dir-file.yml

# Sirf node1 par test
ansible-playbook playbooks/02_create-dir-file.yml --limit node1

# Complete play run
ansible-playbook playbooks/02_create-dir-file.yml

# Results verify karein
ansible all -m command -a "ls -l /tmp/yaml-study-lab"
ansible all -m command -a "cat /tmp/yaml-study-lab/notes.txt"

# Cleanup
ansible all -m file -a "path=/tmp/yaml-study-lab state=absent"
```

---

## 21. Practice questions

1. Complete playbook aur task file mein kya farq hai?
2. Task file mein `hosts:` kyun nahi hota?
3. `include_tasks` kya karta hai?
4. Relative included-file path kis location ke mutabiq resolve hota hai?
5. Directory task ko copy task se pehle kyun run karna chahiye?
6. Directory banane ke liye kaun sa module use hota hai?
7. Inline content wali file banane ke liye kaun sa module use hota hai?
8. Is example mein `file` module ke neeche `dest` kyun ghalat hai?
9. YAML mein `content: |` kya karta hai?
10. `inventory_hostname` kya value deta hai?
11. `include_tasks` aur `import_tasks` ka basic farq kya hai?
12. `state: touch` har run par `changed` kyun report kar sakta hai?
13. Ansible syntax-check ka command kya hai?
14. Lint check ka command kya hai?
15. Playbook ko sirf `node1` par kaise test karein ge?
16. `--check` aur `--diff` ka kya maqsad hai?
17. Included task file mein `tasks:` keyword kyun nahi likha jata?
18. Ek hi YAML level par duplicate `mode` keys kyun avoid karni chahiye?

---

## 22. Khulasa

- Playbook play, target hosts aur tasks ka execution flow define karti hai.
- Task file reusable tasks ki YAML list hoti hai.
- `include_tasks` runtime par doosri file ke tasks dynamically load karta hai.
- `file` module directory, empty file, permissions aur filesystem state manage karta hai.
- `copy` module `content` aur `dest` ke saath text wali file banata hai.
- Is use case mein `dest` ko `file` module ke neeche nahi likhna chahiye.
- Ek hi YAML mapping mein duplicate keys, jaise do `mode` entries, avoid karein.
- Pehle `--syntax-check`, phir `--check --diff`, aur phir `--limit node1` se safe testing karein.
- `state: touch` timestamp update karta hai aur repeat runs par `changed` dikha sakta hai.
- Reusable task files seekhna Ansible roles ki taraf ek important agla qadam hai.
