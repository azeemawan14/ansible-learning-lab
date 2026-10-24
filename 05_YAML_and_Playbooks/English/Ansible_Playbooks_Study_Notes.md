# Ansible Playbooks From Scratch — Study Notes

These notes explain Ansible playbooks from the beginning and use this personal Rocky Linux lab:

- Control node: `ansible-server.nitclasses.com`
- Ansible user: `ansibleadmin`
- Project directory: `/home/ansibleadmin/automation`
- Inventory: `/home/ansibleadmin/automation/inventory/nodes`
- Main managed-node group: `three_tier_app`
- Web group: `web`

> The examples intentionally use short module names such as `copy`, `dnf`, and `service`.

## Index

1. [What is an Ansible playbook?](#1-what-is-an-ansible-playbook)
2. [Ad-hoc commands vs playbooks](#2-ad-hoc-commands-vs-playbooks)
3. [Why use playbooks?](#3-why-use-playbooks)
4. [Core playbook components](#4-core-playbook-components)
5. [Essential YAML rules](#5-essential-yaml-rules)
6. [Recommended project structure](#6-recommended-project-structure)
7. [First playbook](#7-first-playbook)
8. [Line-by-line explanation](#8-line-by-line-explanation)
9. [Install and start Nginx](#9-install-and-start-nginx)
10. [Check playbook syntax](#10-check-playbook-syntax)
11. [Preview target hosts and tasks](#11-preview-target-hosts-and-tasks)
12. [Check mode and diff mode](#12-check-mode-and-diff-mode)
13. [Run a playbook](#13-run-a-playbook)
14. [Limit execution](#14-limit-execution)
15. [Privilege escalation](#15-privilege-escalation)
16. [Understand PLAY RECAP](#16-understand-play-recap)
17. [Idempotency](#17-idempotency)
18. [Verify the result](#18-verify-the-result)
19. [Variables](#19-variables)
20. [Loops](#20-loops)
21. [Conditions](#21-conditions)
22. [Handlers and notify](#22-handlers-and-notify)
23. [Facts and setup](#23-facts-and-setup)
24. [Templates](#24-templates)
25. [Tags](#25-tags)
26. [Registered variables](#26-registered-variables)
27. [Common state values](#27-common-state-values)
28. [Common errors and troubleshooting](#28-common-errors-and-troubleshooting)
29. [Complete Nginx practice lab](#29-complete-nginx-practice-lab)
30. [Cleanup playbook](#30-cleanup-playbook)
31. [Recommended workflow](#31-recommended-workflow)
32. [Practice questions](#32-practice-questions)
33. [Quick reference](#33-quick-reference)

---

## 1. What is an Ansible playbook?

An Ansible playbook is a reusable YAML file that describes:

- which managed nodes will be targeted;
- which tasks will run;
- which modules will perform those tasks;
- whether administrator privileges are required;
- and the desired final state of the systems.

A playbook is a written automation procedure. It can be saved in Git, reviewed, shared, and run repeatedly.

The usual file extensions are `.yml` and `.yaml`.

---

## 2. Ad-hoc commands vs playbooks

| Feature | Ad-hoc command | Playbook |
|---|---|---|
| Format | One command in the terminal | YAML file |
| Best use | Quick, one-time work | Repeatable automation |
| Reusable | Not conveniently | Yes |
| Version control | Difficult | Easy |
| Multiple tasks | Awkward | Natural |
| Variables, loops, handlers | Limited | Fully supported |

Ad-hoc example:

```bash
ansible web -b -m dnf -a "name=nginx state=present"
```

Equivalent playbook task:

```yaml
- name: Install Nginx
  dnf:
    name: nginx
    state: present
```

---

## 3. Why use playbooks?

Playbooks provide:

- repeatability;
- consistency across many servers;
- readable documentation of the desired state;
- idempotent execution when suitable modules are used;
- error reporting per host and task;
- variables, conditions, loops, handlers, templates, and roles;
- safe review and testing before deployment.

---

## 4. Core playbook components

| Component | Purpose |
|---|---|
| Playbook | YAML file containing one or more plays |
| Play | Maps a set of hosts to tasks |
| Task | One named unit of work |
| Module | Tool that performs the work, such as `copy` or `dnf` |
| Argument | Setting passed to a module, such as `state: present` |
| Variable | Named value that can be reused |
| Fact | Information discovered about a managed node |
| Loop | Repeats a task for multiple items |
| Condition | Controls whether a task runs |
| Handler | Task triggered only when notified of a change |
| Template | Jinja2-powered file containing dynamic values |
| Role | Standard directory structure for reusable automation |

Basic hierarchy:

```text
Playbook
└── Play
    ├── Target hosts
    ├── Variables
    ├── Tasks
    └── Handlers
```

---

## 5. Essential YAML rules

1. Use spaces, not tabs.
2. Indentation defines structure; two spaces per level is common.
3. A hyphen (`-`) begins a list item.
4. A colon (`:`) separates a key from its value.
5. Keep related keys aligned at the same indentation level.
6. Quote values when special characters could be interpreted by YAML.
7. Use lowercase `true` and `false` for Boolean values.

Correct:

```yaml
---
- name: Test connectivity
  hosts: three_tier_app
  gather_facts: false

  tasks:
    - name: Ping managed nodes
      ping:
```

Incorrect indentation:

```yaml
- name: Test connectivity
 hosts: three_tier_app
   tasks:
```

The opening `---` is recommended but not mandatory. It marks the beginning of a YAML document.

---

## 6. Recommended project structure

```text
/home/ansibleadmin/automation/
├── ansible.cfg
├── inventory/
│   └── nodes
├── playbooks/
│   ├── ping.yml
│   ├── nginx.yml
│   └── cleanup-nginx.yml
├── files/
├── templates/
└── roles/
```

Create the directories:

```bash
cd /home/ansibleadmin/automation
mkdir -p playbooks files templates roles
```

If `ansible.cfg` already specifies the inventory, commands run from this project directory do not need `-i`:

```ini
[defaults]
inventory = ./inventory/nodes
```

If the configuration points to `./inventory`, Ansible can read supported inventory files inside that directory. Pointing to `./inventory/nodes` selects that exact inventory file.

---

## 7. First playbook

Create the file:

```bash
vim /home/ansibleadmin/automation/playbooks/ping.yml
```

Contents:

```yaml
---
- name: Verify connectivity to all lab nodes
  hosts: three_tier_app
  gather_facts: false

  tasks:
    - name: Run the Ansible ping test
      ping:
```

Run it from the project directory:

```bash
cd /home/ansibleadmin/automation
ansible-playbook playbooks/ping.yml
```

The Ansible `ping` module is not the same as the Linux `ping` command. It verifies Ansible login, Python execution, and module communication. A successful result returns `pong`.

---

## 8. Line-by-line explanation

```yaml
---
```

Starts the YAML document.

```yaml
- name: Verify connectivity to all lab nodes
```

Begins a play and gives it a descriptive name.

```yaml
  hosts: three_tier_app
```

Targets the `three_tier_app` inventory group.

```yaml
  gather_facts: false
```

Skips automatic system-fact collection because this simple test does not need facts.

```yaml
  tasks:
```

Begins the ordered task list.

```yaml
    - name: Run the Ansible ping test
      ping:
```

Defines a task and calls the `ping` module. The empty value is valid because the module needs no arguments here.

---

## 9. Install and start Nginx

Create `playbooks/nginx.yml`:

```yaml
---
- name: Install and configure Nginx
  hosts: web
  become: true

  tasks:
    - name: Install Nginx
      dnf:
        name: nginx
        state: present

    - name: Start and enable Nginx
      service:
        name: nginx
        state: started
        enabled: true

    - name: Deploy the home page
      copy:
        content: |
          <h1>Welcome to the Ansible Nginx Lab</h1>
          <p>This page was deployed with an Ansible playbook.</p>
        dest: /usr/share/nginx/html/index.html
        owner: root
        group: root
        mode: '0644'
```

`become: true` applies privilege escalation to the entire play. It is needed because installing packages, controlling services, and writing under `/usr/share/nginx` require administrator privileges.

---

## 10. Check playbook syntax

Always check syntax before execution:

```bash
ansible-playbook --syntax-check playbooks/nginx.yml
```

This detects YAML and playbook-structure errors. It does not prove that every task will succeed on a managed node.

Useful YAML check if available:

```bash
yamllint playbooks/nginx.yml
```

---

## 11. Preview target hosts and tasks

Show the hosts that the playbook will target:

```bash
ansible-playbook playbooks/nginx.yml --list-hosts
```

Show the task names:

```bash
ansible-playbook playbooks/nginx.yml --list-tasks
```

Show available tags:

```bash
ansible-playbook playbooks/nginx.yml --list-tags
```

These commands are safe inspection steps; they do not execute the tasks.

---

## 12. Check mode and diff mode

Predict changes without normally applying them:

```bash
ansible-playbook playbooks/nginx.yml --check
```

Show predicted file differences where supported:

```bash
ansible-playbook playbooks/nginx.yml --check --diff
```

Important limitations:

- Not every module fully supports check mode.
- A later task may depend on a resource that an earlier task only pretended to create.
- Check mode is useful, but it is not a replacement for testing in a lab.

---

## 13. Run a playbook

From the project directory:

```bash
ansible-playbook playbooks/nginx.yml
```

If the inventory is not configured in `ansible.cfg`, specify it explicitly:

```bash
ansible-playbook -i inventory/nodes playbooks/nginx.yml
```

Use more detail for troubleshooting:

```bash
ansible-playbook -vv playbooks/nginx.yml
```

Higher levels such as `-vvv` show additional connection details but also produce much more output.

---

## 14. Limit execution

Run the playbook only on `node1`, while still respecting the hosts defined in the play:

```bash
ansible-playbook playbooks/nginx.yml --limit node1
```

Other examples:

```bash
ansible-playbook playbooks/nginx.yml --limit web
ansible-playbook playbooks/nginx.yml --limit 'node1:node2'
ansible-playbook playbooks/nginx.yml --limit 'three_tier_app:!node3'
```

`--limit` narrows the playbook target. It does not add a host that is outside the play's `hosts:` pattern.

---

## 15. Privilege escalation

Play-level escalation:

```yaml
- name: Administrative work
  hosts: web
  become: true
```

Task-level escalation:

```yaml
- name: Install Nginx
  become: true
  dnf:
    name: nginx
    state: present
```

Related configuration:

```ini
[privilege_escalation]
become_method = sudo
become_user = root
become_ask_pass = False
```

- `become_method = sudo`: use `sudo` for escalation.
- `become_user = root`: become the `root` user.
- `become_ask_pass = False`: do not prompt for a sudo password.

This requires the remote user to have passwordless sudo. If sudo requires a password, use `--ask-become-pass` or configure credentials securely.

---

## 16. Understand PLAY RECAP

Typical recap:

```text
node1 : ok=4 changed=2 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

| Field | Meaning |
|---|---|
| `ok` | Tasks completed successfully |
| `changed` | Tasks changed the managed node |
| `unreachable` | Ansible could not connect |
| `failed` | A task ran but failed |
| `skipped` | A condition or tag caused a task to be skipped |
| `rescued` | Failure was handled by a rescue block |
| `ignored` | Failure was ignored by configuration |

A healthy run normally has `unreachable=0` and `failed=0`.

---

## 17. Idempotency

Idempotency means running the same automation repeatedly should leave a system in the same desired state without making unnecessary changes.

First run:

```text
changed=3
```

Second run, when the desired state already exists:

```text
changed=0
```

Modules such as `dnf`, `service`, `copy`, `file`, `user`, and `lineinfile` can determine whether a change is necessary.

The `command`, `shell`, and `raw` modules normally report `changed` whenever they run because they cannot automatically know the command's effect. Use purpose-built modules whenever possible.

---

## 18. Verify the result

Check the service:

```bash
ansible web -m command -a "systemctl is-active nginx"
```

Check whether it starts at boot:

```bash
ansible web -m command -a "systemctl is-enabled nginx"
```

Test the local website on each web server:

```bash
ansible web -m uri -a "url=http://localhost status_code=200 return_content=yes"
```

`status_code=200` means Ansible expects the server to return HTTP status 200, which indicates that the request succeeded. A response such as 403 or 404 causes the task to fail because it does not match the expected status.

---

## 19. Variables

Variables prevent repeated hard-coded values.

```yaml
---
- name: Install a configurable web package
  hosts: web
  become: true

  vars:
    web_package: nginx
    web_service: nginx
    web_root: /usr/share/nginx/html

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

The `{{ variable_name }}` syntax is a Jinja2 expression. Quoting a value that begins with a Jinja2 expression avoids YAML parsing problems.

Common variable locations include:

- play-level `vars:`;
- inventory host or group variables;
- `group_vars/` and `host_vars/`;
- variable files loaded with `vars_files:`;
- command-line extra variables using `-e`.

---

## 20. Loops

Install several packages with one task:

```yaml
- name: Install useful packages
  become: true
  dnf:
    name: "{{ item }}"
    state: present
  loop:
    - nginx
    - git
    - unzip
```

For package installation, passing the complete list directly is often faster:

```yaml
- name: Install useful packages efficiently
  become: true
  dnf:
    name:
      - nginx
      - git
      - unzip
    state: present
```

Use a loop when each item needs individual processing or when a module expects one item at a time.

---

## 21. Conditions

Run a task only on Red Hat-family systems:

```yaml
- name: Install Nginx on Red Hat-family systems
  become: true
  dnf:
    name: nginx
    state: present
  when: ansible_facts['os_family'] == 'RedHat'
```

Facts must be available for this condition, so do not set `gather_facts: false` unless facts were gathered another way.

Conditions use Jinja2 expressions but normally do not use `{{ }}` inside `when:`.

---

## 22. Handlers and notify

Handlers normally run only when a notifying task reports a change.

```yaml
---
- name: Configure Nginx
  hosts: web
  become: true

  tasks:
    - name: Deploy Nginx configuration
      copy:
        src: ../files/nginx.conf
        dest: /etc/nginx/nginx.conf
        owner: root
        group: root
        mode: '0644'
        backup: true
      notify: Restart Nginx

  handlers:
    - name: Restart Nginx
      service:
        name: nginx
        state: restarted
```

If the copied file is already identical, the task reports no change and the handler does not run. By default, notified handlers run near the end of the play.

---

## 23. Facts and setup

Ansible facts describe the managed node, including its operating system, hostname, interfaces, memory, and processors.

View all facts:

```bash
ansible node1 -m setup
```

Filter facts:

```bash
ansible node1 -m setup -a "filter=ansible_distribution*"
ansible node1 -m setup -a "filter=ansible_default_ipv4"
```

Display selected facts in a playbook:

```yaml
- name: Display system information
  hosts: three_tier_app

  tasks:
    - name: Show operating system and address
      debug:
        msg: >-
          {{ inventory_hostname }} runs
          {{ ansible_facts['distribution'] }}
          {{ ansible_facts['distribution_version'] }} and its default IPv4
          address is {{ ansible_facts['default_ipv4']['address'] }}.
```

`inventory_hostname` is the name Ansible uses in the inventory, such as `node1`. `ansible_host` is the address used for the connection, such as `192.168.1.154`.

---

## 24. Templates

A template is a text file containing Jinja2 expressions. Ansible renders it separately for each host.

Create `templates/index.html.j2`:

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>{{ site_title }}</title>
</head>
<body>
  <h1>{{ site_title }}</h1>
  <p>Served by {{ inventory_hostname }}</p>
</body>
</html>
```

Playbook task:

```yaml
- name: Deploy the generated home page
  template:
    src: ../templates/index.html.j2
    dest: /usr/share/nginx/html/index.html
    owner: root
    group: root
    mode: '0644'
```

Template paths are resolved relative to the playbook or role. A clean project layout and consistent relative paths prevent confusion.

---

## 25. Tags

Tags allow selected tasks to run.

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
    enabled: true
  tags:
    - service
```

Run only package tasks:

```bash
ansible-playbook playbooks/nginx.yml --tags packages
```

Skip service tasks:

```bash
ansible-playbook playbooks/nginx.yml --skip-tags service
```

---

## 26. Registered variables

`register` stores a task result in a variable.

```yaml
- name: Check the Nginx service
  command: systemctl is-active nginx
  register: nginx_status
  changed_when: false

- name: Display the service result
  debug:
    var: nginx_status.stdout
```

`changed_when: false` marks the inspection command as unchanged because it only reads the service state.

The registered result may include fields such as:

- `stdout` and `stdout_lines`;
- `stderr`;
- `rc` for the return code;
- `changed`;
- `failed`.

---

## 27. Common state values

| Value | Typical meaning |
|---|---|
| `present` | Ensure a resource exists or a package is installed |
| `absent` | Ensure a resource does not exist or a package is removed |
| `latest` | Ensure a package is installed at the newest available version |
| `started` | Ensure a service is running |
| `stopped` | Ensure a service is not running |
| `restarted` | Restart a service every time the task runs |
| `reloaded` | Reload a service configuration |
| `enabled` | For modules such as `firewalld`, ensure a feature is enabled |
| `directory` | Ensure a path is a directory |
| `file` | Inspect or manage an existing regular file |
| `touch` | Create a file if absent and update timestamps |
| `link` | Ensure a symbolic link exists |

Important: `file: state=file` does not create an empty file. Use `state: touch` to create one.

---

## 28. Common errors and troubleshooting

### YAML syntax or indentation error

```bash
ansible-playbook --syntax-check playbooks/nginx.yml
```

Use spaces, align related keys, and check colons and hyphens.

### Host pattern does not match

```bash
ansible-inventory --graph
ansible-playbook playbooks/nginx.yml --list-hosts
```

Confirm that the value under `hosts:` exactly matches an inventory host or group.

### `UNREACHABLE`

Test in stages:

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node1
ansible node1 -m ping -vvv
```

Check the address, SSH user, private-key path, SSH service, firewall, and host-key state.

### Sudo failure

```bash
ssh ansibleadmin@node1
sudo -n true
```

If this fails, passwordless sudo is not configured or the user lacks permission.

### Package cannot be found

```bash
ansible node1 -m command -a "dnf repolist"
ansible node1 -m command -a "dnf info nginx"
```

### Web request returns 403

A 403 often means Nginx reached the configured document root but could not serve an index file. Check the active Nginx configuration, document root, file permissions, and SELinux contexts.

```bash
ansible node1 -b -m command -a "nginx -T"
ansible node1 -b -m command -a "ls -laZ /var/www/lawfirm.com/html"
ansible node1 -b -m command -a "tail -n 30 /var/log/nginx/error.log"
```

### Nginx cannot bind to port 80

Find what owns the port:

```bash
ansible node1 -b -m shell -a "ss -ltnp | grep ':80 '"
```

Only one process can normally listen on the same IP address and port combination.

---

## 29. Complete Nginx practice lab

Create `playbooks/nginx-lab.yml`:

```yaml
---
- name: Deploy a simple Nginx website
  hosts: web
  become: true

  vars:
    web_package: nginx
    web_service: nginx
    web_root: /usr/share/nginx/html
    page_title: Ansible Nginx Lab

  tasks:
    - name: Install required packages
      dnf:
        name:
          - "{{ web_package }}"
          - firewalld
        state: present
      tags:
        - packages

    - name: Start and enable Nginx
      service:
        name: "{{ web_service }}"
        state: started
        enabled: true
      tags:
        - service

    - name: Start and enable firewalld
      service:
        name: firewalld
        state: started
        enabled: true
      tags:
        - firewall

    - name: Allow HTTP through the firewall
      firewalld:
        service: http
        permanent: true
        immediate: true
        state: enabled
      tags:
        - firewall

    - name: Deploy the website home page
      copy:
        content: |
          <!doctype html>
          <html lang="en">
          <head>
            <meta charset="utf-8">
            <title>{{ page_title }}</title>
          </head>
          <body>
            <h1>{{ page_title }}</h1>
            <p>Deployed on {{ inventory_hostname }} using Ansible.</p>
          </body>
          </html>
        dest: "{{ web_root }}/index.html"
        owner: root
        group: root
        mode: '0644'
      tags:
        - content

    - name: Verify the local web response
      uri:
        url: http://localhost
        status_code: 200
        return_content: true
      register: web_response
      changed_when: false
      tags:
        - verify

    - name: Display the HTTP result
      debug:
        msg: >-
          {{ inventory_hostname }} returned HTTP
          {{ web_response.status }} from Nginx.
      tags:
        - verify
```

Run the lab safely:

```bash
cd /home/ansibleadmin/automation
ansible-playbook --syntax-check playbooks/nginx-lab.yml
ansible-playbook playbooks/nginx-lab.yml --list-hosts
ansible-playbook playbooks/nginx-lab.yml --check --diff --limit node1
ansible-playbook playbooks/nginx-lab.yml --limit node1
ansible-playbook playbooks/nginx-lab.yml --limit node1
```

The second real run should usually report `changed=0`, demonstrating idempotency.

---

## 30. Cleanup playbook

Create `playbooks/cleanup-nginx.yml`:

```yaml
---
- name: Remove the Nginx practice deployment
  hosts: web
  become: true

  tasks:
    - name: Remove the custom home page
      file:
        path: /usr/share/nginx/html/index.html
        state: absent

    - name: Disable the HTTP firewall service
      firewalld:
        service: http
        permanent: true
        immediate: true
        state: disabled
      failed_when: false

    - name: Remove Nginx
      dnf:
        name: nginx
        state: absent
```

Inspect the target before cleanup:

```bash
ansible-playbook playbooks/cleanup-nginx.yml --list-hosts --limit node1
ansible-playbook playbooks/cleanup-nginx.yml --check --diff --limit node1
```

Run cleanup:

```bash
ansible-playbook playbooks/cleanup-nginx.yml --limit node1
```

Run it again to verify idempotency:

```bash
ansible-playbook playbooks/cleanup-nginx.yml --limit node1
```

> Warning: Do not remove shared services, configurations, or websites unless you know they belong to this lab. In a shared environment, use a dedicated VM or a unique path and service configuration.

---

## 31. Recommended workflow

Use this sequence for each new playbook:

1. Confirm inventory and connectivity.
2. Write small, clearly named tasks.
3. Check the syntax.
4. List the target hosts.
5. Use check mode and diff mode when supported.
6. Limit the first real run to one lab node.
7. Verify the result independently.
8. Run the playbook a second time to test idempotency.
9. Expand to the intended group.
10. Save the work in version control.

Command sequence:

```bash
ansible-inventory --graph
ansible three_tier_app -m ping
ansible-playbook --syntax-check playbooks/example.yml
ansible-playbook playbooks/example.yml --list-hosts
ansible-playbook playbooks/example.yml --check --diff --limit node1
ansible-playbook playbooks/example.yml --limit node1
ansible-playbook playbooks/example.yml --limit node1
ansible-playbook playbooks/example.yml
```

---

## 32. Practice questions

1. What is a playbook, play, task, module, and argument?
2. Why is indentation important in YAML?
3. What does `hosts:` control?
4. When should `gather_facts: false` be used?
5. What is the purpose of `become: true`?
6. What is the difference between `present`, `latest`, and `absent`?
7. What does idempotency mean?
8. Why can `shell` report `changed` on every run?
9. What is the difference between `copy` and `template`?
10. When does a handler run?
11. What does `register` store?
12. What is the purpose of `changed_when: false`?
13. How does `--limit node1` affect a playbook run?
14. Why should `--syntax-check`, `--list-hosts`, and `--check` be used?
15. How can you verify that Nginx returns HTTP 200?
16. Why should a cleanup playbook be tested carefully on shared nodes?

---

## 33. Quick reference

| Goal | Command or keyword |
|---|---|
| Check connectivity | `ansible three_tier_app -m ping` |
| Run a playbook | `ansible-playbook playbooks/site.yml` |
| Specify inventory | `-i inventory/nodes` |
| Check syntax | `--syntax-check` |
| Show targets | `--list-hosts` |
| Show tasks | `--list-tasks` |
| Preview changes | `--check` |
| Show file differences | `--diff` |
| Restrict execution | `--limit node1` |
| Increase detail | `-v`, `-vv`, or `-vvv` |
| Run selected tags | `--tags packages` |
| Skip selected tags | `--skip-tags service` |
| Pass an extra variable | `-e "package_name=nginx"` |
| Install a package | `dnf` with `state: present` |
| Control a service | `service` with `state:` and `enabled:` |
| Manage a file | `copy`, `file`, `lineinfile`, or `template` |
| Test a URL | `uri` with `status_code: 200` |
| Run only on a condition | `when:` |
| Repeat a task | `loop:` |
| Save a result | `register:` |
| Trigger a handler | `notify:` |

## Final summary

An Ansible playbook converts manual administration steps into readable, repeatable YAML automation. A good beginner workflow is to start with a small play, use purpose-built modules, validate the syntax and target hosts, test on one node, verify the result, and run the playbook again to confirm idempotency. As the automation grows, variables, facts, conditions, loops, handlers, templates, tags, and roles make it easier to maintain and reuse.
