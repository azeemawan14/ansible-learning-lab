# Ansible Common Modules — Demo Lab

This lab demonstrates 25 commonly used Ansible modules in a Rocky Linux environment. It is designed for the following personal lab:

- Control node: `ansible-server`
- Managed nodes: `node1`, `node2`, and `node3`
- Inventory group: `three_tier_app`
- Remote user: `ansibleadmin`
- Managed-node OS: Rocky Linux

> **Safety:** Run the storage section only when a managed node has a separate empty practice disk. Never experiment with `parted`, `filesystem`, or `mount` on the operating-system disk.

## Index

1. [Learning objectives](#1-learning-objectives)
2. [Prerequisites](#2-prerequisites)
3. [Pre-lab verification](#3-pre-lab-verification)
4. [Lab workspace](#4-lab-workspace)
5. [`copy` module](#5-copy-module)
6. [`command` module](#6-command-module)
7. [`raw` module](#7-raw-module)
8. [`shell` module](#8-shell-module)
9. [`file` module](#9-file-module)
10. [`fetch` module](#10-fetch-module)
11. [`get_url` module](#11-get_url-module)
12. [`lineinfile` module](#12-lineinfile-module)
13. [`replace` module](#13-replace-module)
14. [`user` module](#14-user-module)
15. [`group` module](#15-group-module)
16. [`dnf`, `yum`, and `package` modules](#16-dnf-yum-and-package-modules)
17. [`yum_repository` module](#17-yum_repository-module)
18. [`stat` module](#18-stat-module)
19. [`setup` module](#19-setup-module)
20. [`service` and `systemd` modules](#20-service-and-systemd-modules)
21. [`debug` module](#21-debug-module)
22. [`uri` module](#22-uri-module)
23. [`cron` module](#23-cron-module)
24. [`script` module](#24-script-module)
25. [`parted`, `filesystem`, and `mount` modules](#25-parted-filesystem-and-mount-modules)
26. [Combined playbook](#26-combined-playbook)
27. [Idempotency test](#27-idempotency-test)
28. [Cleanup](#28-cleanup)
29. [Review questions](#29-review-questions)

---

## 1. Learning objectives

After completing this lab, you should be able to:

- Select a suitable module instead of using `shell` for every task.
- Distinguish between `command`, `shell`, and `raw`.
- Manage files, users, groups, packages, repositories, services, and cron jobs.
- Collect facts and inspect registered variables.
- Download and retrieve files.
- Explain Ansible idempotency.
- Recognize the risks of storage-management modules.

## 2. Prerequisites

The following must already work:

```bash
cd /home/ansibleadmin/automation
ansible three_tier_app -m ping
ansible three_tier_app -b -m command -a "whoami"
```

Expected results:

- `ping` returns `pong` from all three nodes.
- The second command returns `root` because `-b` enables privilege escalation.

This lab assumes that the project-level `ansible.cfg` already defines the inventory, remote user, private key, and sudo settings.

## 3. Pre-lab verification

Display the selected hosts:

```bash
ansible three_tier_app --list-hosts
```

Display the inventory structure:

```bash
ansible-inventory --graph
```

Check Ansible's active configuration:

```bash
ansible-config dump --only-changed
```

## 4. Lab workspace

Create a local lab directory on the control node:

```bash
mkdir -p /home/ansibleadmin/automation/module-lab/{files,playbooks,output,scripts}
cd /home/ansibleadmin/automation/module-lab
```

Create a source file:

```bash
echo "Managed by Ansible" > files/module-lab.conf
```

Create a remote practice directory:

```bash
ansible three_tier_app -m file -a \
"path=/tmp/ansible-module-lab state=directory mode=0755"
```

Run the same command twice. The first run should normally report `CHANGED`; the second should report `SUCCESS` with `changed=false`.

## 5. `copy` module

Purpose: copy a file from the control node to managed nodes, or create a file from inline content.

```bash
ansible three_tier_app -m copy -a \
"src=files/module-lab.conf dest=/tmp/ansible-module-lab/module-lab.conf mode=0644"
```

Inline-content example:

```bash
ansible three_tier_app -m copy -a \
'content="Hello from Ansible\n" dest=/tmp/ansible-module-lab/hello.txt mode=0644'
```

Verify:

```bash
ansible three_tier_app -m command -a \
"cat /tmp/ansible-module-lab/hello.txt"
```

## 6. `command` module

Purpose: run a command directly without opening a shell.

```bash
ansible three_tier_app -m command -a "uptime"
ansible three_tier_app -m command -a "df -h /"
ansible three_tier_app -m command -a "ls -l /tmp/ansible-module-lab"
```

The `command` module does not interpret shell operators such as:

```text
|  >  >>  &&  ;  *  $HOME
```

Therefore, this fails:

```bash
ansible three_tier_app -m command -a "uptime; lsblk"
```

Use separate `command` tasks or use `shell` when shell syntax is genuinely required.

## 7. `raw` module

Purpose: send a command directly through SSH without requiring Python on the managed node.

```bash
ansible three_tier_app -m raw -a "hostname"
ansible three_tier_app -m raw -a "python3 --version"
```

Typical use case: bootstrap Python on a minimal Linux host before normal Python-based Ansible modules can run.

```bash
ansible new_linux_hosts -b -m raw -a "dnf install -y python3"
```

Do not run the bootstrap command unless the selected hosts actually need Python.

## 8. `shell` module

Purpose: execute a command through `/bin/sh`, allowing pipes, redirects, variables, and command separators.

```bash
ansible three_tier_app -m shell -a \
"uptime; lsblk"
```

Pipe example:

```bash
ansible three_tier_app -m shell -a \
"ps -ef | systemctl is-active sshd"
```

Redirect example:

```bash
ansible three_tier_app -m shell -a \
'date > /tmp/ansible-module-lab/date.txt'
```

Important: ad-hoc `shell` commands normally report `CHANGED` whenever they succeed, even if they did not alter the system. Prefer a purpose-built module when one is available.

## 9. `file` module

Purpose: manage files, directories, links, ownership, permissions, and absence.

Create a directory:

```bash
ansible three_tier_app -m file -a \
"path=/tmp/ansible-module-lab/demo-dir state=directory mode=0750"
```

Create an empty file:

```bash
ansible three_tier_app -m file -a \
"path=/tmp/ansible-module-lab/empty.txt state=touch mode=0640"
```

Create a symbolic link:

```bash
ansible three_tier_app -m file -a \
"src=/tmp/ansible-module-lab/hello.txt dest=/tmp/ansible-module-lab/hello-link state=link"
```

Remove an exact path:

```bash
ansible three_tier_app -m file -a \
"path=/tmp/ansible-module-lab/empty.txt state=absent"
```

## 10. `fetch` module

Purpose: copy files from managed nodes back to the control node.

```bash
ansible three_tier_app -m fetch -a \
"src=/tmp/ansible-module-lab/date.txt dest=./output/"
```

By default, `fetch` creates a separate host directory under `output` so same-named files from different nodes do not overwrite one another.

Inspect the results:

```bash
find output -type f -print
```

## 11. `get_url` module

Purpose: download a file from an HTTP, HTTPS, or FTP URL onto managed nodes.

Example using a public text file:

```bash
ansible three_tier_app -m get_url -a \
"url=https://www.example.com/ dest=/tmp/ansible-module-lab/example.html mode=0644"
```

Verify:

```bash
ansible three_tier_app -m stat -a \
"path=/tmp/ansible-module-lab/example.html"
```

This step requires outbound internet access from the managed nodes. Skip it if the lab network blocks internet access.

## 12. `lineinfile` module

Purpose: ensure a particular line is present, absent, or replaced in a text file.

```bash
ansible three_tier_app -m lineinfile -a \
'path=/tmp/ansible-module-lab/module-lab.conf line="environment=practice" state=present'
```

Run it twice. The second run should report no change because the required line already exists.

Verify:

```bash
ansible three_tier_app -m command -a \
"cat /tmp/ansible-module-lab/module-lab.conf"
```

## 13. `replace` module

Purpose: replace all text matching a regular expression.

```bash
ansible three_tier_app -m replace -a \
'path=/tmp/ansible-module-lab/module-lab.conf regexp="^environment=.*$" replace="environment=training"'
```

Verify:

```bash
ansible three_tier_app -m command -a \
"cat /tmp/ansible-module-lab/module-lab.conf"
```

Use `lineinfile` when managing one logical line. Use `replace` when regex-based replacement may affect one or more matches.

## 14. `user` module

Purpose: create, modify, lock, unlock, or remove user accounts.

Create a practice user:

```bash
ansible three_tier_app -b -m user -a \
"name=labuser comment='Ansible Lab User' shell=/bin/bash create_home=yes state=present"
```

Verify:

```bash
ansible three_tier_app -m command -a "id labuser"
```

## 15. `group` module

Purpose: manage local groups.

```bash
ansible three_tier_app -b -m group -a \
"name=labops state=present"
```

Add the practice user to the group without removing existing supplementary groups:

```bash
ansible three_tier_app -b -m user -a \
"name=labuser groups=labops append=yes"
```

Verify:

```bash
ansible three_tier_app -m command -a "id labuser"
```

## 16. `dnf`, `yum`, and `package` modules

On Rocky Linux 9, prefer `dnf`. The `yum` module may redirect to the DNF backend. The generic `package` module selects the operating system's package manager.

Install a small package:

```bash
ansible three_tier_app -b -m dnf -a \
"name=tree state=present"
```

Update it to the newest available version:

```bash
ansible three_tier_app -b -m dnf -a \
"name=tree state=latest"
```

Generic package example:

```bash
ansible three_tier_app -b -m package -a \
"name=wget state=present"
```

Common states:

| State | Meaning |
|---|---|
| `present` | Package must be installed |
| `latest` | Newest available package version must be installed |
| `absent` | Package must not be installed |

## 17. `yum_repository` module

Purpose: create or remove YUM/DNF repository definitions.

For a safe demonstration, create a disabled repository:

```bash
ansible three_tier_app -b -m yum_repository -a \
'name=ansible-lab description="Ansible Lab Repository" baseurl=https://example.com/repo enabled=no gpgcheck=no state=present'
```

Verify:

```bash
ansible three_tier_app -b -m command -a \
"cat /etc/yum.repos.d/ansible-lab.repo"
```

Because the demonstration repository is disabled, DNF will not attempt to use the placeholder URL.

## 18. `stat` module

Purpose: collect metadata about a path without changing it.

```bash
ansible three_tier_app -m stat -a \
"path=/tmp/ansible-module-lab/module-lab.conf"
```

Useful returned fields include:

- `exists`
- `isreg`
- `isdir`
- `mode`
- `pw_name`
- `gr_name`
- `size`
- `checksum`

## 19. `setup` module

Purpose: collect Ansible facts about managed nodes.

All facts:

```bash
ansible three_tier_app -m setup
```

Filtered operating-system facts:

```bash
ansible three_tier_app -m setup -a \
"filter=ansible_distribution*"
```

Memory facts:

```bash
ansible three_tier_app -m setup -a \
"filter=ansible_memtotal_mb"
```

IPv4 facts:

```bash
ansible three_tier_app -m setup -a \
"filter=ansible_default_ipv4"
```

## 20. `service` and `systemd` modules

Purpose: manage services. `service` provides a general interface; `systemd` exposes systemd-specific controls.

Install and start Chrony:

```bash
ansible three_tier_app -b -m dnf -a \
"name=chrony state=present"

ansible three_tier_app -b -m service -a \
"name=chronyd state=started enabled=yes"
```

Check service state without changing it:

```bash
ansible three_tier_app -m command -a \
"systemctl is-active chronyd"
```

Systemd daemon-reload example:

```bash
ansible three_tier_app -b -m systemd -a \
"daemon_reload=yes"
```

Do not restart SSH remotely during this introductory lab.

## 21. `debug` module

Purpose: display a message or variable during playbook execution.

Create `playbooks/debug-demo.yml`:

```yaml
---
- name: Demonstrate registered variables and debug
  hosts: three_tier_app
  gather_facts: false

  tasks:
    - name: Check system uptime
      command: uptime
      register: uptime_result
      changed_when: false

    - name: Display the host and uptime
      debug:
        msg: "{{ inventory_hostname }}: {{ uptime_result.stdout }}"
```

Run it:

```bash
ansible-playbook playbooks/debug-demo.yml
```

## 22. `uri` module

Purpose: communicate with an HTTP or HTTPS endpoint and optionally validate its response.

Check a public website from managed nodes:

```bash
ansible three_tier_app -m uri -a \
"url=https://www.example.com method=GET status_code=200 return_content=no"
```

This requires outbound network and DNS access from managed nodes.

Local web-service example, after installing and starting Nginx or HTTPD:

```bash
ansible web -m uri -a \
"url=http://127.0.0.1 status_code=200"
```

## 23. `cron` module

Purpose: manage cron entries idempotently.

Create a harmless cron job that records the time every five minutes:

```bash
ansible three_tier_app -m cron -a \
'name="Ansible lab timestamp" minute="*/5" job="date >> /tmp/ansible-module-lab/cron-time.log"'
```

Verify:

```bash
ansible three_tier_app -m command -a "crontab -l"
```

The job is created in the `ansibleadmin` user's crontab because privilege escalation was not used.

## 24. `script` module

Purpose: transfer a local script to a managed node, execute it, and then remove the temporary transferred copy.

Create `scripts/system-summary.sh`:

```bash
#!/bin/bash
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
```

Make it executable:

```bash
chmod +x scripts/system-summary.sh
```

Run it:

```bash
ansible three_tier_app -m script -a \
"scripts/system-summary.sh"
```

Use modules or playbooks for repeatable configuration. The `script` module is most useful when an existing script must be reused.

## 25. `parted`, `filesystem`, and `mount` modules

These modules form a typical storage workflow:

```text
parted → filesystem → mount
```

| Module | Purpose |
|---|---|
| `parted` | Create or manage a disk partition |
| `filesystem` | Create a filesystem on a block device |
| `mount` | Define and mount the filesystem |

> **Critical warning:** Do not use `/dev/xvda`, `/dev/sda`, or any disk containing the operating system. Continue only with a separate empty practice disk confirmed by your instructor or hypervisor configuration.

Inspect disks first:

```bash
ansible three_tier_app -m command -a \
"lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS"
```

Example only—assuming `/dev/xvdb` is a dedicated empty practice disk:

```yaml
---
- name: Optional storage-module demonstration
  hosts: node1
  become: true

  vars:
    lab_disk: /dev/xvdb
    lab_partition: /dev/xvdb1
    lab_mount: /mnt/ansible-lab

  tasks:
    - name: Create one GPT partition
      parted:
        device: "{{ lab_disk }}"
        label: gpt
        number: 1
        state: present
        part_start: 1MiB
        part_end: 100%

    - name: Create an XFS filesystem
      filesystem:
        fstype: xfs
        dev: "{{ lab_partition }}"

    - name: Create the mount point
      file:
        path: "{{ lab_mount }}"
        state: directory
        mode: "0755"

    - name: Mount and persist the filesystem
      mount:
        path: "{{ lab_mount }}"
        src: "{{ lab_partition }}"
        fstype: xfs
        state: mounted
```

Save this optional example as `playbooks/storage-demo.yml`, replace device names only after verifying the correct blank disk, and test only on a disposable VM.

## 26. Combined playbook

Create `playbooks/common-modules-demo.yml`:

```yaml
---
- name: Demonstrate common Ansible modules safely
  hosts: three_tier_app
  become: true

  vars:
    lab_path: /tmp/ansible-module-lab

  tasks:
    - name: Create the practice group
      group:
        name: labops
        state: present

    - name: Create the practice user
      user:
        name: labuser
        comment: Ansible Lab User
        shell: /bin/bash
        create_home: true
        groups: labops
        append: true
        state: present

    - name: Create the practice directory
      file:
        path: "{{ lab_path }}"
        state: directory
        owner: ansibleadmin
        group: ansibleadmin
        mode: "0755"

    - name: Copy the configuration file
      copy:
        src: ../files/module-lab.conf
        dest: "{{ lab_path }}/module-lab.conf"
        owner: ansibleadmin
        group: ansibleadmin
        mode: "0644"

    - name: Ensure the environment line exists
      lineinfile:
        path: "{{ lab_path }}/module-lab.conf"
        line: environment=training
        state: present

    - name: Install the demonstration package
      dnf:
        name: tree
        state: present

    - name: Install Chrony
      dnf:
        name: chrony
        state: present

    - name: Start and enable Chrony
      service:
        name: chronyd
        state: started
        enabled: true

    - name: Inspect the managed configuration file
      stat:
        path: "{{ lab_path }}/module-lab.conf"
      register: module_lab_file

    - name: Display the result
      debug:
        msg: >-
          {{ inventory_hostname }} has {{ module_lab_file.stat.path }}
          with mode {{ module_lab_file.stat.mode }}
```

Check syntax:

```bash
ansible-playbook --syntax-check playbooks/common-modules-demo.yml
```

Preview changes on one node:

```bash
ansible-playbook playbooks/common-modules-demo.yml \
--check --diff --limit node1
```

Run on one node:

```bash
ansible-playbook playbooks/common-modules-demo.yml \
--limit node1
```

Run on the complete group:

```bash
ansible-playbook playbooks/common-modules-demo.yml
```

## 27. Idempotency test

Run the combined playbook twice:

```bash
ansible-playbook playbooks/common-modules-demo.yml
ansible-playbook playbooks/common-modules-demo.yml
```

Expected behavior:

- The first run may report several changes.
- The second run should normally report `changed=0`.
- Read-only `stat` and `debug` tasks should not change the system.
- Purpose-built modules understand the desired state better than arbitrary shell commands.

## 28. Cleanup

Create `playbooks/cleanup-common-modules-demo.yml`:

```yaml
---
- name: Remove common-modules demonstration resources
  hosts: three_tier_app
  become: true

  tasks:
    - name: Remove the practice cron job
      cron:
        name: Ansible lab timestamp
        user: ansibleadmin
        state: absent

    - name: Remove the practice directory
      file:
        path: /tmp/ansible-module-lab
        state: absent

    - name: Remove the practice user
      user:
        name: labuser
        state: absent
        remove: true

    - name: Remove the practice group
      group:
        name: labops
        state: absent

    - name: Remove the disabled practice repository
      yum_repository:
        name: ansible-lab
        state: absent

    - name: Remove the optional demonstration package
      dnf:
        name: tree
        state: absent
```

Run cleanup:

```bash
ansible-playbook --syntax-check playbooks/cleanup-common-modules-demo.yml
ansible-playbook playbooks/cleanup-common-modules-demo.yml --check --diff --limit node1
ansible-playbook playbooks/cleanup-common-modules-demo.yml
```

The cleanup intentionally leaves Chrony installed and running because time synchronization is a useful baseline service. Storage changes are also excluded because storage cleanup requires careful unmounting, `/etc/fstab` removal, filesystem removal, and partition deletion.

## 29. Review questions

1. Why should `command` be preferred over `shell` when shell features are unnecessary?
2. Which module can run before Python is installed on a managed node?
3. What is the difference between `copy` and `fetch`?
4. Why is `lineinfile` idempotent?
5. When should `replace` be used instead of `lineinfile`?
6. What does `append=yes` protect when modifying user groups?
7. What is the difference between `present`, `latest`, and `absent`?
8. Why was the demonstration repository disabled?
9. What information can the `stat` module return?
10. What is the purpose of the `setup` module?
11. What is the difference between `service` and `systemd`?
12. What does `register` do?
13. Why should a destructive storage playbook use `--limit node1` first?
14. What result demonstrates idempotency on the second playbook run?
15. Why is cleanup itself written as a playbook instead of a broad `rm -rf` command?

---

## Final recommendation

Use purpose-built modules whenever possible:

```text
Desired state → Suitable Ansible module → Predictable change reporting → Idempotency
```

Use `command`, `shell`, `raw`, and `script` only when a more specific module does not fit the requirement. Always test destructive operations with `--check`, `--diff`, and `--limit` before running them across the complete inventory.
