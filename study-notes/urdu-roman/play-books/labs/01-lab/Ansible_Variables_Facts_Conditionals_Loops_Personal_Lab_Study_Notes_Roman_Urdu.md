# Ansible Variables, Facts, Conditionals aur Loops

## Personal Rocky Linux Lab — Roman Urdu Study Notes

## Fehrist (Table of Contents)

1. [Learning objectives](#1-learning-objectives)
2. [Aap ka lab environment](#2-aap-ka-lab-environment)
3. [Project structure](#3-project-structure)
4. [Pre-lab checks](#4-pre-lab-checks)
5. [Variables ki bunyad](#5-variables-ki-bunyad)
6. [Playbook variables ka lab](#6-playbook-variables-ka-lab)
7. [Extra variables `-e`](#7-extra-variables--e)
8. [`group_vars` aur `host_vars`](#8-group_vars-aur-host_vars)
9. [Variable files banana](#9-variable-files-banana)
10. [Inventory variables istemal karna](#10-inventory-variables-istemal-karna)
11. [Variable precedence](#11-variable-precedence)
12. [Ansible facts](#12-ansible-facts)
13. [Ad-hoc commands se facts](#13-ad-hoc-commands-se-facts)
14. [Playbook mein facts](#14-playbook-mein-facts)
15. [Aham facts ki table](#15-aham-facts-ki-table)
16. [Conditionals aur `when`](#16-conditionals-aur-when)
17. [Conditional tasks ka lab](#17-conditional-tasks-ka-lab)
18. [Loops](#18-loops)
19. [Loops ka lab](#19-loops-ka-lab)
20. [Optional user-creation loop](#20-optional-user-creation-loop)
21. [`loop` aur `with_items`](#21-loop-aur-with_items)
22. [`register` aur result object](#22-register-aur-result-object)
23. [`debug: var` aur `debug: msg`](#23-debug-var-aur-debug-msg)
24. [Server health-report project](#24-server-health-report-project)
25. [Validate, dry run aur execute](#25-validate-dry-run-aur-execute)
26. [Verification commands](#26-verification-commands)
27. [Idempotency](#27-idempotency)
28. [Common errors aur solutions](#28-common-errors-aur-solutions)
29. [Cleanup](#29-cleanup)
30. [Practice questions](#30-practice-questions)
31. [Quick command reference](#31-quick-command-reference)

---

## 1. Learning objectives

Is lab ke baad aap:

- variables define aur use kar sakein ge;
- `group_vars` aur `host_vars` ka farq samajh sakein ge;
- managed nodes ke facts hasil kar sakein ge;
- `when` se conditional tasks chala sakein ge;
- `loop` se aik task ko multiple items par chala sakein ge;
- `register` se task ka result save kar sakein ge;
- `debug` se variables aur results display kar sakein ge;
- syntax check, dry run aur idempotency test kar sakein ge.

> **Note:** Module names short form mein rakhe gaye hain, jaise `file`, `copy`,
> `dnf` aur `debug`, kyun ke aap isi style se practice karna pasand karte hain.

---

## 2. Aap ka lab environment

| Role | Host | IP address | Inventory group |
|---|---|---:|---|
| Control node | `ansible-server.nitclasses.com` | `192.168.1.233` | Control node |
| Managed node 1 | `node1` | `192.168.1.154` | `web` |
| Managed node 2 | `node2` | `192.168.1.185` | `app` |
| Managed node 3 | `node3` | `192.168.1.190` | `db` |

Lab ki additional maloomat:

- Operating system: Rocky Linux 9
- Remote user: `ansibleadmin`
- Parent group: `three_tier_app`
- Project path: `/home/ansibleadmin/automation`
- Inventory path: `/home/ansibleadmin/automation/inventory`
- Playbook path: `/home/ansibleadmin/automation/playbooks`

Inventory ka basic naqsha:

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

---

## 3. Project structure

```text
/home/ansibleadmin/automation/
├── ansible.cfg
├── inventory/
│   ├── nodes
│   ├── group_vars/
│   │   ├── all.yml
│   │   ├── web.yml
│   │   └── db.yml
│   └── host_vars/
│       ├── node1.yml
│       ├── node2.yml
│       └── node3.yml
└── playbooks/
    ├── 01_variables.yml
    ├── 02_inventory-variables.yml
    ├── 03_facts.yml
    ├── 04_conditionals.yml
    ├── 05_loops.yml
    ├── 06_users-loop.yml
    ├── 07_register-debug.yml
    └── 08_server-report.yml
```

Directories banane ke liye:

```bash
cd /home/ansibleadmin/automation
mkdir -p inventory/group_vars inventory/host_vars playbooks
```

---

## 4. Pre-lab checks

Pehle confirm karein ke Ansible sahi configuration aur inventory use kar raha hai:

```bash
cd /home/ansibleadmin/automation
ansible --version
ansible-config dump --only-changed
ansible-inventory --graph
ansible three_tier_app --list-hosts
ansible three_tier_app -m ping
```

Agar teenon nodes se `pong` milta hai to connectivity theek hai.

---

## 5. Variables ki bunyad

Variable aik naam wala container hota hai jo koi value store karta hai. Is se
playbook reusable hoti hai aur aik hi value ko bar bar hard-code nahi karna parta.

```yaml
app_directory: /opt/nitclasses-app
app_owner: root
app_mode: "0755"
```

Variable ko Jinja2 expression se use kiya jata hai:

```yaml
path: "{{ app_directory }}"
```

### Variable naming rules

- Naam letter se start karein.
- Spaces ki jagah underscore `_` use karein.
- Dash `-` se parhez karein.
- Meaningful naam use karein.
- File modes ko quote karein: `"0644"`, `"0755"`.

Sahi examples:

```yaml
web_package: nginx
service_state: started
```

Ghalat examples:

```yaml
web-package: nginx
service state: started
```

---

## 6. Playbook variables ka lab

File banayein:

```bash
vim playbooks/01_variables.yml
```

```yaml
---
- name: Demonstrate playbook variables
  hosts: three_tier_app
  become: true
  gather_facts: false

  vars:
    app_directory: /opt/nitclasses-app
    app_file: study-notes.txt
    app_message: Managed by Ansible variables

  tasks:
    - name: Ensure application directory exists
      file:
        path: "{{ app_directory }}"
        state: directory
        owner: root
        group: root
        mode: "0755"

    - name: Create study file using variables
      copy:
        content: |
          {{ app_message }}
          Inventory host: {{ inventory_hostname }}
        dest: "{{ app_directory }}/{{ app_file }}"
        owner: root
        group: root
        mode: "0644"
```

Run karein:

```bash
ansible-playbook --syntax-check playbooks/01_variables.yml
ansible-playbook playbooks/01_variables.yml --limit node1
```

Verify karein:

```bash
ansible node1 -b -m command -a "cat /opt/nitclasses-app/study-notes.txt"
```

---

## 7. Extra variables `-e`

Extra variable command line se di jati hai. Is ke liye `-e` ya `--extra-vars`
use hota hai. Aam tor par extra vars ki precedence bohat high hoti hai.

```bash
ansible-playbook playbooks/01_variables.yml --limit node1 \
  -e "app_directory=/opt/my-custom-app app_message='Overridden from CLI'"
```

JSON format bhi use kiya ja sakta hai:

```bash
ansible-playbook playbooks/01_variables.yml --limit node1 \
  -e '{"app_directory":"/opt/custom-json-app","app_message":"JSON extra variable"}'
```

> Password ya secret ko command line par dena munasib nahi, kyun ke shell history
> aur process listing mein nazar aa sakta hai. Secrets ke liye Ansible Vault use karein.

---

## 8. `group_vars` aur `host_vars`

`group_vars` mein rakhi value group ke sab hosts ko milti hai. `host_vars` ki
value sirf aik specific host ko milti hai.

| Location | Kis par apply hoti hai? | Example |
|---|---|---|
| `group_vars/all.yml` | Inventory ke tamam hosts | Common packages |
| `group_vars/web.yml` | Sirf `web` group | Nginx settings |
| `group_vars/db.yml` | Sirf `db` group | MariaDB settings |
| `host_vars/node1.yml` | Sirf `node1` | Host-specific port |

Inventory file ka naam `nodes` hai, is liye variable directories ko
`inventory/` ke andar rakhna wazeh aur asaan structure hai.

---

## 9. Variable files banana

### `inventory/group_vars/all.yml`

```yaml
---
organization_name: NIT Classes
lab_environment: personal-rocky-lab
common_packages:
  - git
  - curl
  - tree
  - vim-enhanced
```

### `inventory/group_vars/web.yml`

```yaml
---
web_package: nginx
web_service: nginx
web_port: 80
```

### `inventory/group_vars/db.yml`

```yaml
---
db_package: mariadb-server
db_service: mariadb
db_port: 3306
```

### `inventory/host_vars/node1.yml`

```yaml
---
node_role: web-server
training_owner: Khalid
```

### `inventory/host_vars/node2.yml`

```yaml
---
node_role: application-server
training_owner: Khalid
```

### `inventory/host_vars/node3.yml`

```yaml
---
node_role: database-server
training_owner: Khalid
```

Variables dekhne ke liye:

```bash
ansible-inventory --host node1
ansible-inventory --host node2
ansible-inventory --host node3
```

---

## 10. Inventory variables istemal karna

```bash
vim playbooks/02_inventory-variables.yml
```

```yaml
---
- name: Use group and host variables
  hosts: three_tier_app
  become: true
  gather_facts: false

  tasks:
    - name: Display variables inherited by each host
      debug:
        msg:
          - "Host: {{ inventory_hostname }}"
          - "Role: {{ node_role }}"
          - "Organization: {{ organization_name }}"
          - "Environment: {{ lab_environment }}"

    - name: Install common packages
      dnf:
        name: "{{ common_packages }}"
        state: present
```

Pehle sirf `node1` par test karein:

```bash
ansible-playbook --syntax-check playbooks/02_inventory-variables.yml
ansible-playbook playbooks/02_inventory-variables.yml --limit node1
```

Phir sab nodes par:

```bash
ansible-playbook playbooks/02_inventory-variables.yml
```

---

## 11. Variable precedence

Agar aik hi variable multiple jagah define ho to higher-precedence value jeetti
hai. Beginner ke liye simplified order, low se high tak:

1. Role defaults
2. Inventory group variables
3. Inventory host variables
4. Playbook `vars`
5. Task variables
6. Extra variables `-e`

Exact precedence list bohat detailed hai, lekin yaad rakhein:

> `-e` wali extra variable aam tor par sab se zyada precedence rakhti hai.

Current values inspect karne ke liye:

```bash
ansible-inventory --host node1
ansible-config dump --only-changed
```

---

## 12. Ansible facts

Facts managed node ke bare mein system information hain jo Ansible `setup`
module se collect karta hai, jaise OS, hostname, IP, memory aur CPU.

Facts default tor par tab collect hote hain jab:

```yaml
gather_facts: true
```

Ya `gather_facts` likha hi na ho. Agar facts ki zarurat nahi to:

```yaml
gather_facts: false
```

Is se playbook thori tez chal sakti hai.

---

## 13. Ad-hoc commands se facts

Tamam facts:

```bash
ansible node1 -m setup
```

Selected facts:

```bash
ansible node1 -m setup -a "filter=ansible_distribution*"
ansible node1 -m setup -a "filter=ansible_default_ipv4"
ansible node1 -m setup -a "filter=ansible_memtotal_mb"
ansible node1 -m setup -a "filter=ansible_processor_vcpus"
```

Facts ki local filtering ke liye:

```bash
ansible node1 -m setup | less
ansible node1 -m setup | grep -i distribution
```

---

## 14. Playbook mein facts

```bash
vim playbooks/03_facts.yml
```

```yaml
---
- name: Display useful system facts
  hosts: three_tier_app
  gather_facts: true

  tasks:
    - name: Show important facts
      debug:
        msg:
          - "Inventory name: {{ inventory_hostname }}"
          - "FQDN: {{ ansible_fqdn }}"
          - "OS: {{ ansible_distribution }} {{ ansible_distribution_version }}"
          - "Kernel: {{ ansible_kernel }}"
          - "IPv4: {{ ansible_default_ipv4.address | default('Not available') }}"
          - "Memory: {{ ansible_memtotal_mb }} MB"
          - "vCPUs: {{ ansible_processor_vcpus }}"
```

```bash
ansible-playbook --syntax-check playbooks/03_facts.yml
ansible-playbook playbooks/03_facts.yml
```

`default('Not available')` ka matlab hai ke agar IPv4 fact mojood na ho to
playbook fail hone ke bajaye yeh text display kare.

---

## 15. Aham facts ki table

| Fact | Matlab / istemal |
|---|---|
| `inventory_hostname` | Inventory mein host ka naam, jaise `node1` |
| `ansible_hostname` | Managed system ka short hostname |
| `ansible_fqdn` | Fully qualified domain name |
| `ansible_distribution` | OS family/name, jaise Rocky |
| `ansible_distribution_major_version` | Major OS version, jaise `9` |
| `ansible_default_ipv4.address` | Default IPv4 address |
| `ansible_memtotal_mb` | Total memory MB mein |
| `ansible_processor_vcpus` | Virtual CPUs ki tadaad |
| `ansible_mounts` | Mounted filesystems ki list |
| `group_names` | Jin groups ka host member hai |

---

## 16. Conditionals aur `when`

Conditional ka matlab hai task sirf us waqt chale jab di hui condition true ho.
Ansible mein `when` use hota hai.

```yaml
- name: Install Nginx only on web hosts
  dnf:
    name: nginx
    state: present
  when: "'web' in group_names"
```

`when` ke andar Jinja braces `{{ }}` aam tor par nahi lagaye jate:

```yaml
# Sahi
when: ansible_distribution == "Rocky"

# Ghalat / unnecessary
when: "{{ ansible_distribution }} == 'Rocky'"
```

---

## 17. Conditional tasks ka lab

```bash
vim playbooks/04_conditionals.yml
```

```yaml
---
- name: Demonstrate conditional tasks
  hosts: three_tier_app
  become: true
  gather_facts: true

  tasks:
    - name: Stop if the managed node is not Rocky Linux 9
      fail:
        msg: "This lab requires Rocky Linux 9."
      when:
        - ansible_distribution != "Rocky"
          or ansible_distribution_major_version != "9"

    - name: Install Nginx on web hosts
      dnf:
        name: "{{ web_package }}"
        state: present
      when: "'web' in group_names"

    - name: Install MariaDB on database hosts
      dnf:
        name: "{{ db_package }}"
        state: present
      when: "'db' in group_names"

    - name: Show the application-node message
      debug:
        msg: "{{ inventory_hostname }} belongs to the app group."
      when: "'app' in group_names"
```

```bash
ansible-playbook --syntax-check playbooks/04_conditionals.yml
ansible-playbook playbooks/04_conditionals.yml --limit node1
ansible-playbook playbooks/04_conditionals.yml
```

Expected behavior:

- Nginx sirf `node1` par install hoga.
- App message sirf `node2` par dikhe ga.
- MariaDB sirf `node3` par install hoga.
- Baqi relevant na hone wale tasks `skipped` dikhayen ge.

---

## 18. Loops

Loop aik task ko multiple items ke liye repeat karta hai.

```yaml
- name: Create multiple directories
  file:
    path: "{{ item }}"
    state: directory
  loop:
    - /opt/app/logs
    - /opt/app/data
```

Har iteration mein current value `item` variable ke andar hoti hai.

---

## 19. Loops ka lab

```bash
vim playbooks/05_loops.yml
```

```yaml
---
- name: Demonstrate loops
  hosts: three_tier_app
  become: true
  gather_facts: false

  vars:
    lab_directories:
      - /opt/nitclasses-app/logs
      - /opt/nitclasses-app/config
      - /opt/nitclasses-app/data
      - /opt/nitclasses-app/tmp

    lab_packages:
      - git
      - curl
      - unzip
      - jq

  tasks:
    - name: Create multiple application directories
      file:
        path: "{{ item }}"
        state: directory
        owner: root
        group: root
        mode: "0755"
      loop: "{{ lab_directories }}"

    - name: Install the package list efficiently
      dnf:
        name: "{{ lab_packages }}"
        state: present

    - name: Display every managed directory
      debug:
        msg: "Directory managed: {{ item }}"
      loop: "{{ lab_directories }}"
```

Packages par loop kyun nahi lagaya? `dnf` module seedha list accept karta hai.
Puri list aik transaction mein dena zyada efficient hota hai.

```bash
ansible-playbook --syntax-check playbooks/05_loops.yml
ansible-playbook playbooks/05_loops.yml --limit node1
ansible-playbook playbooks/05_loops.yml
```

---

## 20. Optional user-creation loop

> Is lab se real users bante hain. Sirf apne authorized practice nodes par chalayein.

```yaml
---
- name: Create lab users with a loop
  hosts: three_tier_app
  become: true
  gather_facts: false

  vars:
    lab_users:
      - name: student1
        comment: Ansible Lab Student 1
      - name: student2
        comment: Ansible Lab Student 2

  tasks:
    - name: Ensure lab users exist
      user:
        name: "{{ item.name }}"
        comment: "{{ item.comment }}"
        state: present
        create_home: true
      loop: "{{ lab_users }}"
```

Yahan har `item` aik mapping/object hai, is liye `item.name` aur
`item.comment` use kiye gaye hain.

---

## 21. `loop` aur `with_items`

Dono repetition ke liye use hote hain:

```yaml
loop:
  - git
  - curl
```

Purana syntax:

```yaml
with_items:
  - git
  - curl
```

Naye playbooks mein `loop` zyada clear aur recommended syntax hai. Purane
playbooks samajhne ke liye `with_items` pehchan-na bhi zaroori hai.

---

## 22. `register` aur result object

`register` task ka result aik variable mein save karta hai.

```bash
vim playbooks/07_register-debug.yml
```

```yaml
---
- name: Demonstrate register and debug
  hosts: three_tier_app
  gather_facts: false

  tasks:
    - name: Read system uptime
      command: uptime
      register: uptime_result
      changed_when: false

    - name: Display complete registered result
      debug:
        var: uptime_result

    - name: Display only command output
      debug:
        msg: "{{ inventory_hostname }} uptime: {{ uptime_result.stdout }}"
```

Registered result ke common fields:

| Field | Matlab |
|---|---|
| `stdout` | Command ka standard output |
| `stderr` | Error output |
| `rc` | Return code; aam tor par `0` success |
| `changed` | Ansible ke mutabiq change hui ya nahi |
| `failed` | Task fail hui ya nahi |

`uptime` sirf information read karta hai. `command` module phir bhi changed
report kar sakta hai, is liye `changed_when: false` result ko logically sahi banata hai.

---

## 23. `debug: var` aur `debug: msg`

Complete variable structure dekhne ke liye:

```yaml
- debug:
    var: uptime_result
```

Selected ya formatted value dikhane ke liye:

```yaml
- debug:
    msg: "Uptime is {{ uptime_result.stdout }}"
```

`var` ke saath `{{ }}` nahi lagate, lekin `msg` ke andar expression ke liye
Jinja braces use hote hain.

---

## 24. Server health-report project

Yeh variables, facts, conditionals, loops, `register` aur `debug` ko aik practical
playbook mein combine karta hai.

```bash
vim playbooks/08_server-report.yml
```

```yaml
---
- name: Generate a server health report
  hosts: three_tier_app
  become: true
  gather_facts: true

  vars:
    warning_disk_percent: 80
    report_packages:
      - git
      - curl
      - tree

  tasks:
    - name: Check root filesystem usage percentage
      shell: "df -P / | awk 'NR == 2 {gsub(/%/, \"\", $5); print $5}'"
      register: root_usage
      changed_when: false

    - name: Warn when root filesystem usage is high
      debug:
        msg: "WARNING: Root filesystem usage is {{ root_usage.stdout }}%."
      when: root_usage.stdout | int >= warning_disk_percent

    - name: Show normal disk-usage message
      debug:
        msg: "Root filesystem usage is {{ root_usage.stdout }}%; below the warning level."
      when: root_usage.stdout | int < warning_disk_percent

    - name: Check report packages
      command: "rpm -q {{ item }}"
      loop: "{{ report_packages }}"
      register: package_checks
      changed_when: false
      failed_when: false

    - name: Display package-check results
      debug:
        msg: "{{ item.item }}: {{ 'installed' if item.rc == 0 else 'not installed' }}"
      loop: "{{ package_checks.results }}"

    - name: Write host report
      copy:
        content: |
          Host: {{ inventory_hostname }}
          FQDN: {{ ansible_fqdn }}
          OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
          IPv4: {{ ansible_default_ipv4.address | default('Not available') }}
          Memory MB: {{ ansible_memtotal_mb }}
          vCPUs: {{ ansible_processor_vcpus }}
          Root usage: {{ root_usage.stdout }}%
        dest: "/tmp/server-report-{{ inventory_hostname }}.txt"
        owner: root
        group: root
        mode: "0644"
```

`shell` yahan is liye use hua kyun ke command mein pipe `|` aur `awk` hai.
Simple command ke liye `command` module ko preference dein.

---

## 25. Validate, dry run aur execute

### Step 1: Syntax check

```bash
ansible-playbook --syntax-check playbooks/08_server-report.yml
```

Yeh YAML aur Ansible structure check karta hai, lekin poora playbook execute nahi karta.

### Step 2: Dry run / check mode

```bash
ansible-playbook --check playbooks/08_server-report.yml --limit node1
```

`--check` possible changes ka andaza lagata hai. Har module check mode ko equally
support nahi karta, is liye output ko simulation samjhein, guarantee nahi.

### Step 3: Difference preview

```bash
ansible-playbook --check --diff playbooks/08_server-report.yml --limit node1
```

### Step 4: Verbose output

```bash
ansible-playbook -v playbooks/08_server-report.yml --limit node1
```

Verbosity levels:

| Option | Detail |
|---|---|
| `-v` | Basic extra detail |
| `-vv` | Zyada detail |
| `-vvv` | Connection troubleshooting |
| `-vvvv` | Bohat detailed SSH debugging |

### Step 5: Execute

```bash
ansible-playbook playbooks/08_server-report.yml --limit node1
ansible-playbook playbooks/08_server-report.yml
```

---

## 26. Verification commands

Variables:

```bash
ansible-inventory --host node1
```

Directories:

```bash
ansible three_tier_app -b -m command \
  -a "find /opt/nitclasses-app -maxdepth 1 -type d -print"
```

Conditional packages:

```bash
ansible node1 -m command -a "rpm -q nginx"
ansible node3 -m command -a "rpm -q mariadb-server"
```

Reports list karein:

```bash
ansible three_tier_app -b -m command \
  -a "find /tmp -maxdepth 1 -type f -name server-report-*.txt -print"
```

Reports read karein:

```bash
ansible node1 -b -m command -a "cat /tmp/server-report-node1.txt"
ansible node2 -b -m command -a "cat /tmp/server-report-node2.txt"
ansible node3 -b -m command -a "cat /tmp/server-report-node3.txt"
```

---

## 27. Idempotency

Idempotency ka matlab hai playbook ko dobara chalane par system already desired
state mein ho to unnecessary change na ho.

```bash
ansible-playbook playbooks/05_loops.yml
ansible-playbook playbooks/05_loops.yml
```

Second run par zyada tar tasks ke liye `changed=0` aana expected hai. Agar
read-only `command` ya `shell` task har dafa changed dikha raha ho to:

```yaml
changed_when: false
```

Lekin is setting ko sirf tab use karein jab task waqai system change nahi karta.

---

## 28. Common errors aur solutions

### Undefined variable

```text
The task includes an option with an undefined variable
```

Check karein:

- spelling same hai;
- file `group_vars` ya `host_vars` ki sahi location mein hai;
- YAML indentation sahi hai;
- host expected group ka member hai.

```bash
ansible-inventory --host node1
ansible-inventory --graph
```

### Fact undefined hai

Agar `ansible_distribution` undefined ho to mumkin hai `gather_facts: false` ho.

```yaml
gather_facts: true
```

### Conditional har host par chal rahi hai

Group membership inspect karein:

```bash
ansible node1 -m debug -a "var=group_names"
```

### `command` pipe ko nahi samajhta

Yeh fail hoga:

```yaml
command: df -h | grep root
```

Pipe, redirect, wildcard expansion ya `&&` ke liye `shell` use karein. Simple
commands ke liye safer `command` module use karein.

### Package naam ghalat hai

Rocky Linux mein package verify karein:

```bash
dnf info nginx
dnf info mariadb-server
```

### YAML indentation error

Tabs ki jagah spaces use karein aur syntax check chalayein:

```bash
ansible-playbook --syntax-check playbooks/FILE.yml
```

---

## 29. Cleanup

Pehle removal targets review karein:

```bash
ansible three_tier_app -b -m command \
  -a "find /opt -maxdepth 1 -type d -name *app* -print"
```

Sirf woh exact paths remove karein jo aap ne lab mein banaye the:

```bash
ansible three_tier_app -b -m file \
  -a "path=/opt/nitclasses-app state=absent"

ansible three_tier_app -b -m file \
  -a "path=/opt/my-custom-app state=absent"

ansible three_tier_app -b -m file \
  -a "path=/opt/custom-json-app state=absent"
```

Reports remove karein:

```bash
ansible node1 -b -m file -a "path=/tmp/server-report-node1.txt state=absent"
ansible node2 -b -m file -a "path=/tmp/server-report-node2.txt state=absent"
ansible node3 -b -m file -a "path=/tmp/server-report-node3.txt state=absent"
```

Optional lab users sirf us surat mein remove karein jab aap ne unhein isi lab ke
liye create kiya ho:

```bash
ansible three_tier_app -b -m user -a "name=student1 state=absent remove=yes"
ansible three_tier_app -b -m user -a "name=student2 state=absent remove=yes"
```

---

## 30. Practice questions

1. Variable kya hota hai aur playbook ko reusable kaise banata hai?
2. Variable ko reference karne ke liye kaunsa syntax use hota hai?
3. `group_vars/all.yml` aur `host_vars/node1.yml` mein kya farq hai?
4. `ansible-inventory --host node1` kya dikhata hai?
5. Extra variables ka option kya hai?
6. Extra variables ki precedence aam tor par kaisi hoti hai?
7. Facts kya hote hain aur kaunsa module unhein collect karta hai?
8. `gather_facts: false` kab use karna chahiye?
9. `inventory_hostname` aur `ansible_hostname` mein kya farq hai?
10. Conditional task ke liye kaunsa keyword use hota hai?
11. `when` mein `{{ }}` kyun nahi lagate?
12. `skipped` result ka kya matlab hai?
13. Loop ka current item kis variable mein hota hai?
14. Package list ko `dnf` mein direct dena loop se behtar kyun ho sakta hai?
15. `register` kya karta hai?
16. `stdout`, `stderr` aur `rc` ka kya matlab hai?
17. `debug: var` aur `debug: msg` mein kya farq hai?
18. Read-only task ke saath `changed_when: false` kyun use hota hai?
19. Syntax-check command kya hai?
20. Dry run ke liye kaunsa option use hota hai?
21. `--diff` kya dikhata hai?
22. `-vvv` kab helpful hota hai?
23. Idempotency kya hai?
24. Pipe use karne par `command` ke bajaye `shell` kyun chahiye?
25. Cleanup se pehle targets list karna kyun zaroori hai?

---

## 31. Quick command reference

```bash
# Project directory
cd /home/ansibleadmin/automation

# Connectivity
ansible three_tier_app -m ping

# Inventory
ansible-inventory --graph
ansible-inventory --host node1

# Facts
ansible node1 -m setup
ansible node1 -m setup -a "filter=ansible_distribution*"

# Syntax check
ansible-playbook --syntax-check playbooks/FILE.yml

# Dry run
ansible-playbook --check playbooks/FILE.yml --limit node1

# Dry run with differences
ansible-playbook --check --diff playbooks/FILE.yml --limit node1

# Verbose troubleshooting
ansible-playbook -vvv playbooks/FILE.yml --limit node1

# Normal run on one node
ansible-playbook playbooks/FILE.yml --limit node1

# Normal run on all targeted nodes
ansible-playbook playbooks/FILE.yml
```

---

## Khulasa

- Variables values ko reusable banati hain.
- `group_vars` group ke liye aur `host_vars` aik host ke liye hota hai.
- Facts managed nodes ki system information hain.
- `when` task ko condition ke mutabiq control karta hai.
- `loop` repeated work ko asaan banata hai.
- `register` task ka result save karta hai.
- `debug` learning aur troubleshooting mein result display karta hai.
- Pehle `--syntax-check`, phir `--check --diff`, phir `--limit node1`, aur aakhir
  mein tamam target nodes par run karna aik safe lab workflow hai.
