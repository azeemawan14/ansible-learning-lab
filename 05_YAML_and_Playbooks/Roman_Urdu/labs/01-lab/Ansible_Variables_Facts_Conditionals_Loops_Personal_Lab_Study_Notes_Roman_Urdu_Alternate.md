# Ansible Variables, Facts, Conditionals, Loops, Register aur Debug

## Personal Rocky Linux Lab — Roman Urdu Study Notes

## Fehrist (Table of Contents)

1. [Learning objectives](#1-learning-objectives)
2. [Aap ka lab environment](#2-aap-ka-lab-environment)
3. [Final project structure](#3-final-project-structure)
4. [Pre-lab checks](#4-pre-lab-checks)
5. [Variables ki bunyad](#5-variables-ki-bunyad)
6. [Lab 1: Playbook ke andar variables](#6-lab-1-playbook-ke-andar-variables)
7. [Extra variables `-e`](#7-extra-variables--e)
8. [`group_vars` aur `host_vars`](#8-group_vars-aur-host_vars)
9. [Lab 2: Variable files banana](#9-lab-2-variable-files-banana)
10. [Lab 3: Inventory variables istemal karna](#10-lab-3-inventory-variables-istemal-karna)
11. [Variable precedence](#11-variable-precedence)
12. [Ansible facts](#12-ansible-facts)
13. [Lab 4: Ad-hoc commands se facts explore karna](#13-lab-4-ad-hoc-commands-se-facts-explore-karna)
14. [Lab 5: Playbook mein facts](#14-lab-5-playbook-mein-facts)
15. [Real work ke liye paanch aham facts](#15-real-work-ke-liye-paanch-aham-facts)
16. [Conditionals aur `when`](#16-conditionals-aur-when)
17. [Lab 6: Aap ke environment mein conditional tasks](#17-lab-6-aap-ke-environment-mein-conditional-tasks)
18. [Loops](#18-loops)
19. [Lab 7: Packages aur directories ke loops](#19-lab-7-packages-aur-directories-ke-loops)
20. [Optional user-creation loop](#20-optional-user-creation-loop)
21. [`loop` aur `with_items`](#21-loop-aur-with_items)
22. [`register` aur result object](#22-register-aur-result-object)
23. [`debug: var` aur `debug: msg`](#23-debug-var-aur-debug-msg)
24. [Lab 8: Server health report](#24-lab-8-server-health-report)
25. [Validate, dry run aur execute](#25-validate-dry-run-aur-execute)
26. [Verification commands](#26-verification-commands)
27. [Idempotency](#27-idempotency)
28. [Common errors aur solutions](#28-common-errors-aur-solutions)
29. [Cleanup](#29-cleanup)
30. [Evidence aur documentation checklist](#30-evidence-aur-documentation-checklist)
31. [Quick command reference](#31-quick-command-reference)
32. [Practice questions](#32-practice-questions)
33. [Khulasa](#33-khulasa)

---

## 1. Learning objectives

Is lab ke baad aap:

- playbook ke andar variables define kar sakein ge;
- command line se playbook variable override kar sakein ge;
- group aur host variables ko playbooks se bahar store kar sakein ge;
- practical variable precedence samajh sakein ge;
- Ansible facts gather aur filter kar sakein ge;
- facts aur inventory variables ko templates aur messages mein use kar sakein ge;
- `when` se tasks conditionally chala sakein ge;
- `group_names` se host ke inventory groups pehchan sakein ge;
- `loop` se aik task ko multiple items par chala sakein ge;
- `register` se task ka result save kar sakein ge;
- `debug` se variables aur results display kar sakein ge;
- teenon managed nodes ke liye basic server health report bana sakein ge.

> **Note:** Module names short form mein rakhe gaye hain, jaise `file`, `copy`,
> `dnf` aur `debug`, kyun ke aap isi style se practice karna pasand karte hain.

---

## 2. Aap ka lab environment

### Control node

| Item | Value |
|---|---|
| Hostname | `ansible-server.nitclasses.com` |
| IP address | `192.168.1.233` |
| Operating system | Rocky Linux 9.8 |
| User | `ansibleadmin` |
| Project directory | `/home/ansibleadmin/automation` |
| Playbook directory | `/home/ansibleadmin/automation/playbooks` |
| Inventory directory | `/home/ansibleadmin/automation/inventory` |
| Ansible version | Ansible Core 2.14.18 |
| Python | Python 3.9 |

### Managed nodes

| Inventory host | IP address | Group | Maqsad |
|---|---:|---|---|
| `node1` | `192.168.1.154` | `web` | Web-server practice |
| `node2` | `192.168.1.185` | `app` | Application-server practice |
| `node3` | `192.168.1.190` | `db` | Database-server practice |

Parent group yeh hai:

```ini
[three_tier_app:children]
web
app
db
```

In notes mein aap ki preference ke mutabiq short module names, jaise `dnf`,
`file`, `copy` aur `debug`, use kiye gaye hain.

---

## 3. Final project structure

Mukammal project ki structure is tarah honi chahiye:

```text
/home/ansibleadmin/automation/
├── ansible.cfg
├── inventory/
│   ├── nodes
│   ├── group_vars/
│   │   ├── all.yml
│   │   ├── web.yml
│   │   ├── app.yml
│   │   └── db.yml
│   └── host_vars/
│       └── node1.yml
├── playbooks/
│   ├── 03_variables-demo.yml
│   ├── 04_site-vars-demo.yml
│   ├── 05_facts-demo.yml
│   ├── 06_conditionals-demo.yml
│   ├── 07_loops-demo.yml
│   └── 08_server-report.yml
└── reports/
```

### `group_vars` aur `host_vars` ko `inventory/` ke andar kyun rakhein?

- Aap ka configured inventory source `/home/ansibleadmin/automation/inventory` hai.
- Variable directories ko inventory source ke saath rakhne se un ka aapas ka
  talluq bilkul wazeh rehta hai.
- Ansible ke vars plugins us inventory se related group aur host variable files
  ko discover kar sakte hain.

Directories banayein:

```bash
cd /home/ansibleadmin/automation
mkdir -p inventory/group_vars inventory/host_vars playbooks reports
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

Expected hosts `node1`, `node2` aur `node3` hain. Package ya file-management
labs par tab tak aage na barhein jab tak teenon hosts `SUCCESS` aur `pong`
return na karein.

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

### Common variable data types

| Type | Example |
|---|---|
| String | `app_name: nitclasses-app` |
| Integer | `app_port: 8080` |
| Boolean | `app_enabled: true` |
| List | `packages: [git, curl]` |
| Dictionary | `app: {name: demo, port: 8080}` |

Variable ka naam number se start nahi hona chahiye.

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

## 6. Lab 1: Playbook ke andar variables

File banayein:

```bash
vim playbooks/03_variables-demo.yml
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
ansible-playbook --syntax-check playbooks/03_variables-demo.yml
ansible-playbook playbooks/03_variables-demo.yml --limit node1
```

Verify karein:

```bash
ansible node1 -b -m command -a "cat /opt/nitclasses-app/study-notes.txt"
```

### Complete nested-variable example

Isi lab ka doosra example `app_name`, `app_port`, nested `app_dir` aur package
list ko aik saath demonstrate karta hai:

```yaml
---
- name: Demonstrate playbook variables
  hosts: three_tier_app
  become: true
  gather_facts: false

  vars:
    app_name: nitclasses-app
    app_port: 8080
    app_dir: "/opt/{{ app_name }}"
    required_packages:
      - git
      - curl
      - wget

  tasks:
    - name: Print application details
      debug:
        msg: >-
          Deploying {{ app_name }} on port {{ app_port }}
          into {{ app_dir }} on {{ inventory_hostname }}

[>- Explanation]          

    - name: Create the application directory
      file:
        path: "{{ app_dir }}"
        state: directory
        owner: root
        group: root
        mode: "0755"

    - name: Install the required packages
      dnf:
        name: "{{ required_packages }}"
        state: present
```

Yahan `app_name` aur `app_port` simple variables, `app_dir` ke andar doosra
variable, aur `required_packages` aik list hai. `dnf` puri list loop ke baghair
accept karta hai aur `inventory_hostname` current inventory name deta hai.

```bash
ansible-playbook --syntax-check playbooks/03_variables-demo.yml
ansible-playbook playbooks/03_variables-demo.yml --limit node1
ansible-playbook playbooks/03_variables-demo.yml
ansible three_tier_app -b -m command -a "ls -ld /opt/nitclasses-app"
```

---

## 7. Extra variables `-e`

Extra variable command line se di jati hai. Is ke liye `-e` ya `--extra-vars`
use hota hai. Aam tor par extra vars ki precedence bohat high hoti hai.

```bash
ansible-playbook playbooks/03_variables-demo.yml --limit node1 \
  -e "app_directory=/opt/my-custom-app app_message='Overridden from CLI'"
```

JSON format bhi use kiya ja sakta hai:

```bash
ansible-playbook playbooks/03_variables-demo.yml --limit node1 \
  -e '{"app_directory":"/opt/custom-json-app","app_message":"JSON extra variable"}'
```

Nested-variable example ko override karne ke liye:

```bash
ansible-playbook playbooks/03_variables-demo.yml \
  -e "app_name=my-custom-app app_port=9090"

ansible three_tier_app -b -m command -a "ls -ld /opt/my-custom-app"

ansible-playbook playbooks/03_variables-demo.yml \
  -e '{"app_name":"custom-json-app","app_port":9091}'
```

Is mein `app_dir: "/opt/{{ app_name }}"`, `/opt/my-custom-app` resolve hota hai.

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

## 9. Lab 2: Variable files banana

### `inventory/group_vars/all.yml`

```yaml
---
lab_environment: development
organization_name: NIT Classes
ntp_server: pool.ntp.org
common_packages:
  - git
  - curl
  - tree
  - vim-enhanced
```

### `inventory/group_vars/web.yml`

```yaml
---
service_role: web-server
http_port: 80
max_connections: 1000
role_packages:
  - nginx
```

### `inventory/group_vars/app.yml`

```yaml
---
service_role: application-server
app_port: 8080
role_packages:
  - java-17-openjdk-headless
```

### `inventory/group_vars/db.yml`

```yaml
---
service_role: database-server
db_port: 3306
role_packages:
  - mariadb-server
```

Rocky Linux mein is lab ke MariaDB/MySQL-compatible server ke liye
`mariadb-server` package use hota hai. Source exercise ka `mysql-server` naam
Rocky Linux ke liye preferred package naam nahi.

### `inventory/host_vars/node1.yml`

```yaml
---
max_connections: 2000
custom_message: "node1 is the primary web server in Khalid's lab"
```

`node1.yml` ki `max_connections: 2000` value, `web` group ki
`max_connections: 1000` value ko sirf `node1` ke liye override karti hai.

Variables dekhne ke liye:

```bash
ansible-inventory --host node1
ansible-inventory --host node2
ansible-inventory --host node3
```

---

## 10. Lab 3: Inventory variables istemal karna

```bash
vim playbooks/04_site-vars-demo.yml
```

```yaml
---
- name: Apply common configuration
  hosts: three_tier_app
  become: true
  gather_facts: false

  tasks:
    - name: Install common packages
      dnf:
        name: "{{ common_packages }}"
        state: present

    - name: Show common variables
      debug:
        msg: >-
          Host={{ inventory_hostname }},
          Environment={{ lab_environment }},
          Organization={{ organization_name }},
          NTP={{ ntp_server }}

- name: Display web-server configuration
  hosts: web
  gather_facts: false

  tasks:
    - name: Show web variables
      debug:
        msg: >-
          Role={{ service_role }}, HTTP port={{ http_port }},
          Maximum connections={{ max_connections }}

    - name: Show the host-specific message when defined
      debug:
        msg: "{{ custom_message }}"
      when: custom_message is defined
```

```bash
ansible-playbook --syntax-check playbooks/04_site-vars-demo.yml
ansible-playbook playbooks/04_site-vars-demo.yml
```

Expected behavior:

- Common packages `node1`, `node2` aur `node3` par apply hote hain.
- Doosra play sirf `node1` target karta hai kyun ke woh `web` group mein hai.
- `node1` par `max_connections` ki resolved value `2000` hai, kyun ke host
  variable group ki `1000` value ko override karti hai.

Resolved variables inspect karein:

```bash
ansible-inventory --host node1
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

## 13. Lab 4: Ad-hoc commands se facts explore karna

Tamam facts:

```bash
ansible node1 -m setup
```

Selected facts:

```bash
ansible node1 -m setup -a "filter=ansible_os_family"
ansible node1 -m setup -a "filter=ansible_distribution*"
ansible node1 -m setup -a "filter=ansible_default_ipv4"
ansible node1 -m setup -a "filter=ansible_memtotal_mb"
ansible node1 -m setup -a "filter=ansible_architecture"
ansible node1 -m setup -a "filter=ansible_processor_vcpus"
```

Teenon nodes ke filtered facts:

```bash
ansible three_tier_app -m setup -a "filter=ansible_distribution*"
```

`setup` module Ansible facts gather karta hai; iska software install karne ya
operating-system setup program chalane se koi talluq nahi.

Facts ki local filtering ke liye:

```bash
ansible node1 -m setup | less
ansible node1 -m setup | grep -i distribution
```

---

## 14. Lab 5: Playbook mein facts

```bash
vim playbooks/05_facts-demo.yml
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
ansible-playbook --syntax-check playbooks/05_facts-demo.yml
ansible-playbook playbooks/05_facts-demo.yml
```

`default('Not available')` ka matlab hai ke agar IPv4 fact mojood na ho to
playbook fail hone ke bajaye yeh text display kare.

---

## 15. Real work ke liye paanch aham facts

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

Five khas practical uses:

- `ansible_distribution`: Rocky, Ubuntu, Amazon Linux ya doosre OS ke liye task select karna.
- `ansible_distribution_major_version`: Version 8, 9 waghera ke liye munasib repository/configuration select karna.
- `ansible_memtotal_mb`: Memory limits lagana ya chhote system ki warning dena.
- `ansible_default_ipv4.address`: Primary IPv4 ko configuration ya report mein use karna.
- `ansible_processor_vcpus`: CPU count ke mutabiq workers ya concurrency tune karna.

Doosre useful facts mein `ansible_architecture`, `ansible_interfaces` aur
`ansible_date_time.iso8601` bhi shamil hain.

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

### Useful conditional operators

| Operator | Matlab |
|---|---|
| `==` | Barabar |
| `!=` | Barabar nahi |
| `>` / `<` | Bara / chhota |
| `>=` / `<=` | Bara/chhota ya barabar |
| `in` | Value list/collection mein mojood hai |
| `and` | Dono conditions true hon |
| `or` | Kam az kam aik condition true ho |
| `is defined` | Variable mojood ho |

---

## 17. Lab 6: Conditional tasks

```bash
vim playbooks/06_conditionals-demo.yml
```

```yaml
---
- name: Demonstrate conditional tasks
  hosts: three_tier_app
  become: true
  gather_facts: true

  tasks:
    - name: Install Nginx only on the web group
      dnf:
        name: nginx
        state: present
      when: "'web' in group_names"

    - name: Install MariaDB server only on the db group
      dnf:
        name: mariadb-server
        state: present
      when: "'db' in group_names"

    - name: Display the application-server role
      debug:
        msg: "{{ inventory_hostname }} is an application server"
      when: "'app' in group_names"

    - name: Warn when total memory is below 1 GB
      debug:
        msg: "WARNING: {{ inventory_hostname }} has less than 1 GB RAM"
      when: ansible_memtotal_mb < 1024

    - name: Confirm Rocky Linux hosts
      debug:
        msg: >-
          {{ inventory_hostname }} runs
          {{ ansible_distribution }} {{ ansible_distribution_version }}
      when: ansible_distribution == "Rocky"

  [>- Explanation]    

    - name: Display development-environment status
      debug:
        msg: "Development settings apply to {{ inventory_hostname }}"
      when: lab_environment == "development"

    - name: Match web group and sufficient memory with AND
      debug:
        msg: "Web host has at least 512 MB RAM"
      when:
        - "'web' in group_names"
        - ansible_memtotal_mb >= 512

    - name: Match either web or app with OR
      debug:
        msg: "{{ inventory_hostname }} belongs to the web or app tier"
      when: "'web' in group_names or 'app' in group_names"
```

```bash
ansible-playbook --syntax-check playbooks/06_conditionals-demo.yml
ansible-playbook playbooks/06_conditionals-demo.yml --limit node1
ansible-playbook playbooks/06_conditionals-demo.yml
```

Expected behavior:

- Nginx sirf `node1` par install hoga.
- App message sirf `node2` par dikhe ga.
- MariaDB sirf `node3` par install hoga.
- Web ya app message `node1` aur `node2` par chale ga, `node3` par skip hoga.
- Baqi relevant na hone wale tasks `skipped` dikhayen ge. `skipped` error nahi;
  iska matlab hai us host par `when` expression false thi.

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

Dictionary items ki misaal:

```yaml
users:
  - name: deploy
    group: wheel
```

Isay is tarah access karein:

```yaml
name: "{{ item.name }}"
groups: "{{ item.group }}"
```

---

## 19. Lab 7: Packages aur directories ke loops

```bash
vim playbooks/07_loops-demo.yml
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
ansible-playbook --syntax-check playbooks/07_loops-demo.yml
ansible-playbook playbooks/07_loops-demo.yml --limit node1
ansible-playbook playbooks/07_loops-demo.yml
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
      - name: deploy
        groups: wheel
      - name: monitor
        groups: wheel
      - name: appuser
        groups: users

  tasks:
    - name: Ensure lab users exist
      user:
        name: "{{ item.name }}"
        groups: "{{ item.groups }}"
        append: true
        state: present
      loop: "{{ lab_users }}"
```

Yahan har `item` aik mapping/object hai, is liye `item.name` aur
`item.groups` use kiye gaye hain.

`append: true` ke baghair supplementary groups change karne se user ki doosri
group memberships remove ho sakti hain. Yeh option requested group add karta
hai aur doosri supplementary memberships replace nahi karta.

Pehle aik host par test aur verify karein:

```bash
ansible-playbook playbooks/07_loops-demo.yml --limit node1
ansible node1 -m command -a "id deploy"
ansible node1 -m command -a "id monitor"
ansible node1 -m command -a "id appuser"
```

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
| `stdout_lines` | Output ki har line ko list item ki surat mein rakhta hai |
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

## 24. Lab 8: Server health report

Source exercise mein `'9[0-9]%' in output` jaisi literal string check thi. Yeh
regular-expression match nahi karti. Neeche adapted playbook root filesystem ka
usage number ki surat mein collect karke numeric comparison karti hai.

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
    disk_alert_threshold: 90

  tasks:
    - name: Check root filesystem space
      command: df -h /
      register: disk_result
      changed_when: false

    - name: Get numeric root filesystem usage
      shell: "df -P / | awk 'NR == 2 {gsub(/%/, \"\", $5); print $5}'"
      register: disk_usage
      changed_when: false

    - name: Check memory
      command: free -m
      register: memory_result
      changed_when: false

    - name: Count running services
      shell: "systemctl list-units --type=service --state=running --no-legend | wc -l"
      register: running_services
      changed_when: false

    - name: Display the health summary
      debug:
        msg:
          - "========== {{ inventory_hostname }} =========="
          - "Hostname: {{ ansible_hostname }}"
          - "OS: {{ ansible_distribution }} {{ ansible_distribution_version }}"
          - "IP: {{ ansible_default_ipv4.address | default('Unavailable') }}"
          - "RAM: {{ ansible_memtotal_mb }} MB"
          - "Root usage: {{ disk_usage.stdout }}%"
          - "Running services: {{ running_services.stdout }}"

    - name: Warn when root filesystem usage reaches the threshold
      debug:
        msg: >-
          ALERT: Root filesystem usage on {{ inventory_hostname }}
          is {{ disk_usage.stdout }}%, threshold is {{ disk_alert_threshold }}%.
      when: disk_usage.stdout | int >= disk_alert_threshold

    - name: Save the report on each managed node
      copy:
        content: |
          Server: {{ inventory_hostname }}
          Hostname: {{ ansible_hostname }}
          OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
          IP: {{ ansible_default_ipv4.address | default('Unavailable') }}
          RAM: {{ ansible_memtotal_mb }} MB
          Root usage: {{ disk_usage.stdout }}%
          Running services: {{ running_services.stdout }}
          Checked at: {{ ansible_date_time.iso8601 }}

          Disk command output:
          {{ disk_result.stdout }}

          Memory command output:
          {{ memory_result.stdout }}
        dest: "/tmp/server-report-{{ inventory_hostname }}.txt"
        owner: root
        group: root
        mode: "0644"
```

### Yeh improvements kyun zaroori hain?

- Diagnostic commands `changed_when: false` use karti hain.
- Disk usage integer ki surat mein compare hota hai.
- Threshold variable hai aur override kiya ja sakta hai.
- `default('Unavailable')` missing default IPv4 fact ko handle karta hai.
- `copy` idempotent report file banata hai.
- Har node ko unique naam wali report milti hai.

Mukhtalif threshold ke saath run karein:

```bash
ansible-playbook playbooks/08_server-report.yml \
  -e "disk_alert_threshold=80"
```

---

## 25. Validate, dry run aur execute

Project directory se run karein:

```bash
cd /home/ansibleadmin/automation
```

Tamam playbooks ki syntax checks:

```bash
ansible-playbook --syntax-check playbooks/03_variables-demo.yml
ansible-playbook --syntax-check playbooks/04_site-vars-demo.yml
ansible-playbook --syntax-check playbooks/05_facts-demo.yml
ansible-playbook --syntax-check playbooks/06_conditionals-demo.yml
ansible-playbook --syntax-check playbooks/07_loops-demo.yml
ansible-playbook --syntax-check playbooks/08_server-report.yml
```

Optional lint checks:

```bash
ansible-lint playbooks/03_variables-demo.yml
ansible-lint playbooks/08_server-report.yml
```

Supported changes preview karein:

```bash
ansible-playbook --check --diff playbooks/03_variables-demo.yml
ansible-playbook --check --diff playbooks/07_loops-demo.yml
```

Pehle aik node par test karein:

```bash
ansible-playbook playbooks/03_variables-demo.yml --limit node1
```

Tamam labs run karein:

```bash
ansible-playbook playbooks/03_variables-demo.yml
ansible-playbook playbooks/04_site-vars-demo.yml
ansible-playbook playbooks/05_facts-demo.yml
ansible-playbook playbooks/06_conditionals-demo.yml
ansible-playbook playbooks/07_loops-demo.yml
ansible-playbook playbooks/08_server-report.yml
```

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
ansible-playbook playbooks/07_loops-demo.yml
ansible-playbook playbooks/07_loops-demo.yml
```

Second run par zyada tar tasks ke liye `changed=0` aana expected hai. Agar
read-only `command` ya `shell` task har dafa changed dikha raha ho to:

```yaml
changed_when: false
```

Lekin is setting ko sirf tab use karein jab task waqai system change nahi karta.

In labs mein `file state=directory`, `dnf state=present`, `user state=present`
aur unchanged content wala `copy` aam tor par idempotent resources hain.

Server report mein `ansible_date_time.iso8601` timestamp hai. Facts dobara gather
hone par timestamp badal jata hai, is liye report file har naye run par normally
`changed` ho gi. Agar stable report chahiye to timestamp remove kar dein.

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

Ya line remove kar dein, kyun ke fact gathering default tor par enabled hai.

### Host variable apply nahi ho rahi

Filename inventory hostname se match karna chahiye:

```text
Inventory name: node1
Correct file: inventory/host_vars/node1.yml
```

`192.168.1.154.yml` tabhi use karein jab IP khud inventory hostname ho.

### `when` mein Jinja braces ki warning

```yaml
# Na likhein
when: "{{ ansible_distribution == 'Rocky' }}"

# Is tarah likhein
when: ansible_distribution == "Rocky"
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
dnf info java-17-openjdk-headless
```

Is Rocky Linux lab mein `mariadb-server` use karein; Ubuntu-specific package
assumption use na karein.

### Registered command har dafa changed dikhata hai

Read-only diagnostic command ke saath:

```yaml
changed_when: false
```

### String ko integer se compare karna

Registered `stdout` text hota hai. Numeric comparison se pehle convert karein:

```yaml
when: disk_usage.stdout | int >= disk_alert_threshold
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
ansible three_tier_app -b -m user -a "name=deploy state=absent remove=yes"
ansible three_tier_app -b -m user -a "name=monitor state=absent remove=yes"
ansible three_tier_app -b -m user -a "name=appuser state=absent remove=yes"
```

Nginx, MariaDB ya shared packages ko automatically remove na karein agar koi
doosra lab ya student abhi unhein use kar raha ho.

---

## 30. Evidence aur documentation checklist

Apne study record ke liye yeh evidence capture karein:

- [ ] `ansible-inventory --graph` ka output
- [ ] `group_vars` aur `host_vars` dikhane wali directory tree
- [ ] Resolved variables ke saath `ansible-inventory --host node1`
- [ ] `-e` se variable override ka output
- [ ] Chaar filtered-fact commands
- [ ] Teenon nodes ke liye facts playbook ka output
- [ ] Conditional playbook mein `ok`, `changed` aur `skipped`
- [ ] Har directory iteration dikhane wala loop output
- [ ] `debug: var` se registered-variable output
- [ ] `node1`, `node2` aur `node3` ki server reports
- [ ] Idempotency dikhane wala second-run recap

Project structure dikhayein:

```bash
cd /home/ansibleadmin/automation
find inventory playbooks -maxdepth 3 -type f -print | sort
```

---

## 31. Quick command reference

```bash
cd /home/ansibleadmin/automation

# Configuration aur inventory
ansible --version
ansible-config dump --only-changed
ansible-inventory --graph
ansible-inventory --host node1
ansible three_tier_app --list-hosts
ansible three_tier_app -m ping

# Facts
ansible node1 -m setup
ansible node1 -m setup -a "filter=ansible_distribution*"
ansible node1 -m setup -a "filter=ansible_memtotal_mb"
ansible node1 -m setup -a "filter=ansible_default_ipv4"

# Syntax aur lint
ansible-playbook --syntax-check playbooks/03_variables-demo.yml
ansible-lint playbooks/03_variables-demo.yml

# Dry run aur one-host test
ansible-playbook --check --diff playbooks/03_variables-demo.yml
ansible-playbook playbooks/03_variables-demo.yml --limit node1

# Extra variables
ansible-playbook playbooks/03_variables-demo.yml \
  -e "app_name=my-custom-app app_port=9090"
```

---

## 32. Practice questions

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

### Mazeed quick commands

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

## 33. Khulasa

- Variables values ko reusable banati hain.
- `group_vars` group ke liye aur `host_vars` aik host ke liye hota hai.
- Facts managed nodes ki system information hain.
- `when` task ko condition ke mutabiq control karta hai.
- `loop` repeated work ko asaan banata hai.
- `register` task ka result save karta hai.
- `debug` learning aur troubleshooting mein result display karta hai.
- Pehle `--syntax-check`, phir `--check --diff`, phir `--limit node1`, aur aakhir
  mein tamam target nodes par run karna aik safe lab workflow hai.
