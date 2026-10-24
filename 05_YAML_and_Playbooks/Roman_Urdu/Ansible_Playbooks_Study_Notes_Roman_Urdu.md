# Ansible Playbooks From Scratch - Roman Urdu Study Notes

Yeh notes beginner level se Ansible playbook samjhati hain aur phir practical Nginx playbook tak le jati hain. Examples aap ke Rocky Linux lab ke mutabiq hain.

## Lab environment

| Component | Value |
|---|---|
| Control node | `ansible-server.nitclasses.com` |
| Ansible user | `ansibleadmin` |
| Project directory | `/home/ansibleadmin/automation` |
| Inventory file | `/home/ansibleadmin/automation/inventory/nodes` |
| Managed-node group | `three_tier_app` |
| Web group | `web` |
| Operating system | Rocky Linux 9 |
| Package module | `dnf` |

---

## Index

1. [Playbook kya hai?](#1-playbook-kya-hai)
2. [Ad-hoc command aur playbook ka farq](#2-ad-hoc-command-aur-playbook-ka-farq)
3. [Playbook ki zaroorat kyun hoti hai?](#3-playbook-ki-zaroorat-kyun-hoti-hai)
4. [Playbook ke bunyadi components](#4-playbook-ke-bunyadi-components)
5. [YAML ke zaroori qawaid](#5-yaml-ke-zaroori-qawaid)
6. [Project directory structure](#6-project-directory-structure)
7. [Pehla simple playbook](#7-pehla-simple-playbook)
8. [Playbook ki line-by-line wazahat](#8-playbook-ki-line-by-line-wazahat)
9. [Nginx install aur start karne ka playbook](#9-nginx-install-aur-start-karne-ka-playbook)
10. [Playbook ki syntax check](#10-playbook-ki-syntax-check)
11. [Target hosts check karna](#11-target-hosts-check-karna)
12. [Check mode ya dry run](#12-check-mode-ya-dry-run)
13. [Playbook chalana](#13-playbook-chalana)
14. [`--limit` ka istemal](#14---limit-ka-istemal)
15. [Privilege escalation](#15-privilege-escalation)
16. [Play recap samajhna](#16-play-recap-samajhna)
17. [Idempotency](#17-idempotency)
18. [Result verify karna](#18-result-verify-karna)
19. [Variables](#19-variables)
20. [Loops](#20-loops)
21. [Conditions](#21-conditions)
22. [Handlers aur notify](#22-handlers-aur-notify)
23. [Facts aur setup module](#23-facts-aur-setup-module)
24. [Templates ka basic concept](#24-templates-ka-basic-concept)
25. [Tags](#25-tags)
26. [Registered variables](#26-registered-variables)
27. [Common state values](#27-common-state-values)
28. [Common errors aur troubleshooting](#28-common-errors-aur-troubleshooting)
29. [Complete practice lab](#29-complete-practice-lab)
30. [Cleanup playbook](#30-cleanup-playbook)
31. [Recommended workflow](#31-recommended-workflow)
32. [Practice questions](#32-practice-questions)
33. [Quick reference](#33-quick-reference)

---

## 1. Playbook kya hai?

Ansible playbook ek YAML file hoti hai jisme hum likhte hain:

- Automation kis host ya group par chalni hai
- Kaun se tasks perform karne hain
- Kaun se modules istemal karne hain
- System ki matlooba state kya honi chahiye

One-line definition:

> Ansible playbook ek reusable YAML file hai jo managed nodes par automation tasks ko defined order mein chalati hai.

Playbook aam tor par `.yml` ya `.yaml` extension ke sath save hoti hai:

```text
nginx.yml
webserver.yaml
user-management.yml
```

---

## 2. Ad-hoc command aur playbook ka farq

| Ad-hoc command | Playbook |
|---|---|
| Terminal par direct command | YAML file mein tasks |
| Quick aur one-time kaam | Repeatable automation |
| Chhote tasks ke liye | Kai related tasks ke liye |
| Version control mushkil | Git mein asani se track hota hai |
| Conditions aur loops limited | Conditions, loops aur variables supported |

Ad-hoc example:

```bash
ansible web -b -m dnf -a "name=nginx state=present"
```

Isi ka playbook version:

```yaml
---
- name: Install Nginx
  hosts: web
  become: true

  tasks:
    - name: Ensure Nginx is installed
      dnf:
        name: nginx
        state: present
```

---

## 3. Playbook ki zaroorat kyun hoti hai?

Playbook se:

- Ek hi automation ko bar bar chala sakte hain
- Kai servers ko ek jaisi configuration de sakte hain
- Manual mistakes kam hoti hain
- Tasks ko Git mein store aur review kar sakte hain
- Variables, loops aur conditions istemal kar sakte hain
- Idempotent automation bana sakte hain
- Team ke doosray members bhi wahi procedure chala sakte hain

---

## 4. Playbook ke bunyadi components

### Playbook

Poori YAML file ko playbook kaha jata hai.

### Play

Play host pattern aur tasks ko aapas mein jorta hai.

### Task

Task ek specific action hai, jaise package install karna.

### Module

Module woh Ansible tool hai jo action perform karta hai.

Examples:

- `dnf` package manage karta hai
- `service` service manage karta hai
- `copy` file copy karta hai
- `file` file ya directory manage karta hai
- `user` user account manage karta hai

### Module arguments

Arguments module ko batate hain ke kis resource par kya action karna hai.

```yaml
dnf:
  name: nginx
  state: present
```

Yahan:

- `dnf` module hai
- `name` aur `state` arguments hain
- `nginx` aur `present` argument values hain

---

## 5. YAML ke zaroori qawaid

### Spaces istemal karein, tabs nahin

YAML indentation ke liye spaces istemal karta hai. Do spaces ki consistent indentation beginner ke liye achhi practice hai.

### Colon ke baad space

Sahi:

```yaml
name: nginx
```

Ghalat:

```yaml
name:nginx
```

### List item ke liye hyphen

```yaml
packages:
  - nginx
  - git
  - wget
```

### Same level, same indentation

```yaml
tasks:
  - name: Install Nginx
    dnf:
      name: nginx
      state: present
```

### Document marker

`---` YAML document ka start marker hai. Ansible playbooks mein isay likhna achhi practice hai.

---

## 6. Project directory structure

Recommended structure:

```text
/home/ansibleadmin/automation/
├── ansible.cfg
├── inventory/
│   └── nodes
└── playbooks/
    ├── ping.yml
    ├── nginx.yml
    └── cleanup-nginx.yml
```

Directories banayen:

```bash
cd /home/ansibleadmin/automation
mkdir -p playbooks
```

---

## 7. Pehla simple playbook

File banayen:

```bash
vim playbooks/ping.yml
```

Content:

```yaml
---
- name: Test connectivity with managed nodes
  hosts: three_tier_app
  gather_facts: false

  tasks:
    - name: Run Ansible ping test
      ping:
```

Run:

```bash
ansible-playbook playbooks/ping.yml
```

Important: Ansible ka `ping` module ICMP ping nahin hai. Yeh SSH connection, Python aur module execution test karta hai.

---

## 8. Playbook ki line-by-line wazahat

```yaml
---
```

YAML document ka start marker.

```yaml
- name: Test connectivity with managed nodes
```

`-` ek play shuru karta hai. `name` play ki readable description hai.

```yaml
  hosts: three_tier_app
```

Inventory ke `three_tier_app` group ko target karta hai.

```yaml
  gather_facts: false
```

Is play ke start par system facts collect nahin kiye jayenge. Simple ping test ke liye facts zaroori nahin.

```yaml
  tasks:
```

Tasks ki ordered list shuru hoti hai.

```yaml
    - name: Run Ansible ping test
```

Task ka descriptive naam.

```yaml
      ping:
```

`ping` module call hota hai. Is module ko is example mein additional arguments nahin chahiye.

---

## 9. Nginx install aur start karne ka playbook

File:

```bash
vim playbooks/nginx.yml
```

Playbook:

```yaml
---
- name: Install and configure Nginx web server
  hosts: web
  become: true

  tasks:
    - name: Ensure Nginx is installed
      dnf:
        name: nginx
        state: present

    - name: Ensure Nginx is started and enabled
      service:
        name: nginx
        state: started
        enabled: true

    - name: Create a simple home page
      copy:
        content: |
          <h1>Welcome to Khalid's Ansible Lab</h1>
          <p>This page was deployed with an Ansible playbook.</p>
        dest: /usr/share/nginx/html/index.html
        owner: root
        group: root
        mode: "0644"
```

Note: Agar aap ke node par custom Nginx virtual host kisi doosray document root ko use karta hai, to `dest` ko us document root ke mutabiq change karein.

---

## 10. Playbook ki syntax check

```bash
ansible-playbook --syntax-check playbooks/nginx.yml
```

Yeh check karta hai:

- YAML parse ho rahi hai ya nahin
- Playbook structure valid hai ya nahin
- Module aur task structure mein obvious syntax issue hai ya nahin

Expected output:

```text
playbook: playbooks/nginx.yml
```

Syntax check successful honay ka matlab yeh nahin ke runtime par har task zaroor successful hoga. SSH, sudo, repository aur package issues phir bhi ho sakte hain.

---

## 11. Target hosts check karna

```bash
ansible-playbook playbooks/nginx.yml --list-hosts
```

Yeh batata hai ke playbook kin hosts ko target karega. Changes apply nahin hoti.

Tasks list dekhne ke liye:

```bash
ansible-playbook playbooks/nginx.yml --list-tasks
```

---

## 12. Check mode ya dry run

```bash
ansible-playbook playbooks/nginx.yml --check
```

Check mode possible changes ka andaza lagata hai magar aam tor par changes apply nahin karta.

Limitations:

- Har module check mode ko poori tarah support nahin karta
- Command aur shell ka result predict karna mushkil hota hai
- Check mode successful honay ke bawajood real run fail ho sakti hai

Detailed changes dekhne ke liye:

```bash
ansible-playbook playbooks/nginx.yml --check --diff
```

---

## 13. Playbook chalana

Project directory se:

```bash
cd /home/ansibleadmin/automation
ansible-playbook playbooks/nginx.yml
```

Agar inventory config file mein defined nahin hai:

```bash
ansible-playbook -i inventory/nodes playbooks/nginx.yml
```

Verbose troubleshooting:

```bash
ansible-playbook playbooks/nginx.yml -v
ansible-playbook playbooks/nginx.yml -vv
ansible-playbook playbooks/nginx.yml -vvv
```

`-vvv` SSH aur connection troubleshooting mein kaafi useful hai.

---

## 14. `--limit` ka istemal

Sirf `node1` par playbook chalane ke liye:

```bash
ansible-playbook playbooks/nginx.yml --limit node1
```

Important:

`node1` playbook ke `hosts:` pattern ka member hona chahiye. Agar playbook mein `hosts: web` hai aur `node1` web group mein hai, tab command chalegi.

Multiple hosts:

```bash
ansible-playbook playbooks/nginx.yml --limit 'node1:node2'
```

---

## 15. Privilege escalation

Package install karne, service manage karne aur protected directories mein files likhne ke liye root privileges chahiye.

Play level par:

```yaml
become: true
```

Is ka matlab:

- Ansible SSH se `ansibleadmin` user ke taur par connect karta hai
- Task chalate waqt `sudo` ke zariye root privileges leta hai

Aap ke config mein:

```ini
[privilege_escalation]
become_method = sudo
become_user = root
become_ask_pass = False
```

Passwordless sudo configured hona chahiye agar `become_ask_pass = False` hai.

---

## 16. Play recap samajhna

Example:

```text
PLAY RECAP
node1 : ok=4 changed=3 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

| Field | Matlab |
|---|---|
| `ok` | Successful tasks |
| `changed` | Tasks ne system mein change ki |
| `unreachable` | Ansible SSH se host tak nahin pohanch saka |
| `failed` | Host reachable tha magar task fail hui |
| `skipped` | Condition ki wajah se task skip hui |
| `rescued` | `rescue` block ne failure handle ki |
| `ignored` | Failure ko explicitly ignore kiya gaya |

---

## 17. Idempotency

Idempotency ka matlab hai:

> Playbook ko dobara chalane par system pehle se matlooba state mein ho to ghair zaroori changes na hon.

Pehli run:

```text
changed=3
```

Doosri run:

```text
changed=0
```

Idempotent modules:

- `dnf`
- `service`
- `copy`
- `file`
- `user`
- `lineinfile`

`command` aur `shell` har run par default tor par `changed` report kar sakte hain kyun ke Ansible ko command ke internal result ka desired state pata nahin hota.

---

## 18. Result verify karna

Service check:

```bash
ansible web -m command -a "systemctl is-active nginx"
```

Expected:

```text
active
```

HTTP response check:

```bash
ansible web -m uri -a "url=http://localhost status_code=200"
```

Browser se:

```text
http://192.168.1.154/
```

Package check:

```bash
ansible web -m command -a "rpm -q nginx"
```

---

## 19. Variables

Variables se playbook flexible banti hai.

```yaml
---
- name: Install a package using variables
  hosts: web
  become: true

  vars:
    web_package: nginx
    web_service: nginx

  tasks:
    - name: Install the web package
      dnf:
        name: "{{ web_package }}"
        state: present

    - name: Start the web service
      service:
        name: "{{ web_service }}"
        state: started
        enabled: true
```

Variable reference double curly braces mein hota hai:

```text
{{ variable_name }}
```

---

## 20. Loops

Loop se ek task ko kai values par chala sakte hain.

```yaml
- name: Install common packages
  dnf:
    name: "{{ item }}"
    state: present
  loop:
    - nginx
    - git
    - wget
```

Modern package modules aksar poori list direct accept kar lete hain:

```yaml
- name: Install common packages
  dnf:
    name:
      - nginx
      - git
      - wget
    state: present
```

Package installation ke liye direct list zyada efficient ho sakti hai.

---

## 21. Conditions

`when` task ko condition ke mutabiq chalata hai.

```yaml
- name: Install Nginx on Red Hat family systems
  dnf:
    name: nginx
    state: present
  when: ansible_facts['os_family'] == 'RedHat'
```

Facts required hain, is liye `gather_facts: false` use na karein ya pehle `setup` module chalayein.

---

## 22. Handlers aur notify

Handler ek special task hai jo sirf notification milne par run hoti hai.

```yaml
---
- name: Configure Nginx
  hosts: web
  become: true

  tasks:
    - name: Copy Nginx configuration
      copy:
        src: files/nginx.conf
        dest: /etc/nginx/nginx.conf
        owner: root
        group: root
        mode: "0644"
      notify: Restart Nginx

  handlers:
    - name: Restart Nginx
      service:
        name: nginx
        state: restarted
```

Handler tabhi run hogi jab `copy` task configuration file mein change karegi.

---

## 23. Facts aur setup module

Facts managed node ki system information hain:

- OS family
- Distribution
- Hostname
- IP addresses
- Memory
- CPU
- Mount points

Facts collect karein:

```bash
ansible web -m setup
```

Specific fact filter:

```bash
ansible web -m setup -a "filter=ansible_distribution*"
```

Playbook mein:

```yaml
- name: Display operating system
  debug:
    msg: "{{ inventory_hostname }} runs {{ ansible_distribution }} {{ ansible_distribution_version }}"
```

---

## 24. Templates ka basic concept

Template ek Jinja2 file hoti hai jisme variables use kiye ja sakte hain.

Example `templates/index.html.j2`:

```html
<h1>Welcome to {{ inventory_hostname }}</h1>
<p>Managed by Ansible</p>
```

Playbook task:

```yaml
- name: Deploy personalized home page
  template:
    src: templates/index.html.j2
    dest: /usr/share/nginx/html/index.html
    owner: root
    group: root
    mode: "0644"
```

Har managed node par `inventory_hostname` ki value different ho sakti hai.

---

## 25. Tags

Tags se selected tasks chala sakte hain.

```yaml
- name: Install Nginx
  dnf:
    name: nginx
    state: present
  tags:
    - packages

- name: Start Nginx
  service:
    name: nginx
    state: started
  tags:
    - services
```

Sirf package task:

```bash
ansible-playbook playbooks/nginx.yml --tags packages
```

Tag skip karein:

```bash
ansible-playbook playbooks/nginx.yml --skip-tags services
```

---

## 26. Registered variables

Task ka result variable mein save kiya ja sakta hai.

```yaml
- name: Check Nginx service state
  command: systemctl is-active nginx
  register: nginx_status
  changed_when: false

- name: Display Nginx service state
  debug:
    var: nginx_status.stdout
```

`changed_when: false` read-only check ko `changed` report karne se rokta hai.

---

## 27. Common state values

| State | Aam matlab |
|---|---|
| `present` | Resource mojood ho |
| `absent` | Resource remove ho |
| `latest` | Latest available package version installed ho |
| `started` | Service running ho |
| `stopped` | Service stopped ho |
| `restarted` | Service restart ki jaye |
| `reloaded` | Service configuration reload ho |
| `directory` | Path directory ho |
| `file` | Existing path file ho; yeh empty file create nahin karta |
| `touch` | File create ho ya timestamp update ho |

State ka exact matlab module ke mutabiq badal sakta hai. Is liye check karein:

```bash
ansible-doc dnf
ansible-doc service
ansible-doc file
```

---

## 28. Common errors aur troubleshooting

### YAML syntax error

Possible reason:

- Wrong indentation
- Tab character
- Colon ke baad missing space

Check:

```bash
ansible-playbook --syntax-check playbooks/nginx.yml
```

### No hosts matched

Possible reason:

- `hosts:` mein wrong group name
- Wrong inventory load ho rahi hai

Check:

```bash
ansible-inventory --graph
ansible-playbook playbooks/nginx.yml --list-hosts
```

### UNREACHABLE

Possible reason:

- SSH problem
- Wrong user
- Wrong key
- Host down
- Firewall ya network issue

Check:

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node1
ansible node1 -m ping -vvv
```

### Permission denied

Possible reason:

- `become: true` missing
- Sudo permission missing
- `become_ask_pass` setting environment se match nahin karti

Check:

```bash
ssh ansibleadmin@node1
sudo -n whoami
```

Expected:

```text
root
```

### Package not found

Check repositories:

```bash
ansible web -b -m command -a "dnf repolist"
ansible web -b -m command -a "dnf info nginx"
```

---

## 29. Complete practice lab

### Objective

`web` group par Nginx install, start, enable aur simple webpage deploy karni hai.

### Step 1: Connectivity

```bash
ansible web -m ping
```

### Step 2: Playbook file

```bash
vim playbooks/nginx-lab.yml
```

```yaml
---
- name: Deploy Nginx website
  hosts: web
  become: true

  vars:
    web_package: nginx
    web_service: nginx
    web_root: /usr/share/nginx/html

  tasks:
    - name: Install Nginx
      dnf:
        name: "{{ web_package }}"
        state: present

    - name: Start and enable Nginx
      service:
        name: "{{ web_service }}"
        state: started
        enabled: true

    - name: Deploy home page
      copy:
        content: |
          <h1>Welcome to {{ inventory_hostname }}</h1>
          <p>Deployed from ansible-server by Khalid.</p>
        dest: "{{ web_root }}/index.html"
        owner: root
        group: root
        mode: "0644"

    - name: Verify local HTTP response
      uri:
        url: http://localhost
        status_code: 200
```

### Step 3: Syntax check

```bash
ansible-playbook --syntax-check playbooks/nginx-lab.yml
```

### Step 4: Hosts check

```bash
ansible-playbook playbooks/nginx-lab.yml --list-hosts
```

### Step 5: Check mode

```bash
ansible-playbook playbooks/nginx-lab.yml --check --diff
```

### Step 6: Real run

```bash
ansible-playbook playbooks/nginx-lab.yml
```

### Step 7: Second run

```bash
ansible-playbook playbooks/nginx-lab.yml
```

Second run mein ideally `changed=0` ana chahiye agar tamam resources desired state mein hon.

### Step 8: Browser verification

```text
http://192.168.1.154/
```

---

## 30. Cleanup playbook

File:

```bash
vim playbooks/cleanup-nginx.yml
```

```yaml
---
- name: Remove Nginx lab configuration
  hosts: web
  become: true

  tasks:
    - name: Remove custom home page
      file:
        path: /usr/share/nginx/html/index.html
        state: absent

    - name: Stop and disable Nginx
      service:
        name: nginx
        state: stopped
        enabled: false

    - name: Remove Nginx package
      dnf:
        name: nginx
        state: absent
```

Run:

```bash
ansible-playbook playbooks/cleanup-nginx.yml
```

Warning: Shared practice node par cleanup se pehle confirm karein ke doosray users ki required website ya configuration remove nahin ho rahi.

---

## 31. Recommended workflow

Har playbook ke liye yeh order follow karein:

1. Inventory verify karein
2. Manual SSH test karein
3. `ansible ... -m ping` chalayen
4. Playbook likhein
5. `--syntax-check` chalayen
6. `--list-hosts` se targets dekhein
7. `--check --diff` se possible changes dekhein
8. Zaroorat ho to `--limit node1` se pehle ek node par test karein
9. Real playbook run karein
10. Result verify karein
11. Playbook dobara chala kar idempotency check karein

---

## 32. Practice questions

1. Playbook aur play mein kya farq hai?
2. Task aur module kya hotay hain?
3. `hosts:` kis cheez ko select karta hai?
4. `become: true` kyun istemal hota hai?
5. `state: present` ka kya matlab hai?
6. Syntax check runtime SSH problem kyun nahin pakar sakti?
7. Check mode ki kya limitations hain?
8. Idempotency kya hai?
9. Handler kab run hoti hai?
10. `register` kis liye istemal hota hai?
11. `changed_when: false` kyun useful hai?
12. `--limit node1` kis condition mein node1 ko target karega?
13. `failed` aur `unreachable` mein kya farq hai?
14. Variables playbook ko reusable kaise banate hain?
15. Facts kis tarah conditions mein use hote hain?

---

## 33. Quick reference

| Kaam | Command |
|---|---|
| Inventory graph | `ansible-inventory --graph` |
| Connectivity | `ansible web -m ping` |
| Syntax check | `ansible-playbook --syntax-check playbooks/nginx.yml` |
| List hosts | `ansible-playbook playbooks/nginx.yml --list-hosts` |
| List tasks | `ansible-playbook playbooks/nginx.yml --list-tasks` |
| Check mode | `ansible-playbook playbooks/nginx.yml --check` |
| Show differences | `ansible-playbook playbooks/nginx.yml --check --diff` |
| Run playbook | `ansible-playbook playbooks/nginx.yml` |
| Limit to node1 | `ansible-playbook playbooks/nginx.yml --limit node1` |
| Verbose output | `ansible-playbook playbooks/nginx.yml -vvv` |
| Module help | `ansible-doc dnf` |
| Service verification | `ansible web -m command -a "systemctl is-active nginx"` |
| HTTP verification | `ansible web -m uri -a "url=http://localhost status_code=200"` |

---

## Final summary

Ansible playbook ek reusable YAML automation file hai. Is mein plays host groups ko target karte hain, tasks modules ko call karte hain aur module arguments desired state define karte hain. Behtar practice yeh hai ke pehle syntax aur targets check kiye jayen, phir check mode use ho, limited host par test kiya jaye, real run ke baad result verify ho aur second run se idempotency confirm ki jaye.
