# Ansible Configuration — Complete Study Notes (Roman Urdu)

Yeh notes `ansible.cfg` ko basic se practical level tak explain karti hain. Examples personal Rocky Linux Ansible lab ke mutabiq hain.

## Index

1. [Ansible configuration kya hai?](#1-ansible-configuration-kya-hai)
2. [Inventory aur configuration file mein farq](#2-inventory-aur-configuration-file-mein-farq)
3. [Example project structure](#3-example-project-structure)
4. [Complete ansible.cfg example](#4-complete-ansiblecfg-example)
5. [[defaults] section](#5-defaults-section)
6. [inventory setting](#6-inventory-setting)
7. [host_key_checking setting](#7-host_key_checking-setting)
8. [remote_user setting](#8-remote_user-setting)
9. [ask_pass setting](#9-ask_pass-setting)
10. [private_key_file setting](#10-private_key_file-setting)
11. [roles_path aur collections_paths](#11-roles_path-aur-collections_paths)
12. [[privilege_escalation] section](#12-privilege_escalation-section)
13. [become, sudo aur root](#13-become-sudo-aur-root)
14. [Configuration search order](#14-configuration-search-order)
15. [Configuration precedence ka basic concept](#15-configuration-precedence-ka-basic-concept)
16. [Active configuration kaise check karein](#16-active-configuration-kaise-check-karein)
17. [Configuration test karne ke commands](#17-configuration-test-karne-ke-commands)
18. [Common problems aur troubleshooting](#18-common-problems-aur-troubleshooting)
19. [Security recommendations](#19-security-recommendations)
20. [Quick reference table](#20-quick-reference-table)

---

## 1. Ansible configuration kya hai?

Ansible configuration un settings ka collection hai jo control karti hain ke Ansible kis tarah kaam karega.

Configuration decide kar sakti hai:

- Inventory file kahan mojood hai.
- Managed nodes se kis SSH user ke through connect karna hai.
- Kaunsi private key use karni hai.
- SSH password poochna hai ya nahin.
- SSH host key verify karni hai ya nahin.
- Privilege escalation ke liye `sudo` use karna hai ya koi aur method.
- Privileged user `root` hoga ya koi aur account.
- Roles aur collections kahan search karni hain.

Ansible ki configuration aam tor par `ansible.cfg` file mein likhi jati hai.

### Simple definition

> `ansible.cfg` woh file hai jo Ansible ke default behavior ko control karti hai.

---

## 2. Inventory aur configuration file mein farq

| File | Basic sawal | Kaam |
|---|---|---|
| Inventory | Kin machines ko manage karna hai? | Hosts, groups, IP addresses aur host/group variables define karti hai |
| `ansible.cfg` | Un machines ko manage kaise karna hai? | Default inventory, SSH, key, roles aur privilege-escalation settings define karti hai |

### Inventory example

```ini
[web]
node1 ansible_host=192.168.1.154

[app]
node2 ansible_host=192.168.1.185

[db]
node3 ansible_host=192.168.1.190

[all:vars]
ansible_user=ansibleadmin
ansible_python_interpreter=/usr/bin/python3
```

### Configuration example

```ini
[defaults]
inventory = ./inventory
remote_user = ansibleadmin
private_key_file = /home/ansibleadmin/.ssh/ansible-key
```

Inventory mein `ansible_python_interpreter` is liye rakha jata hai kyun ke yeh managed host ke Python executable ko describe karta hai.

---

## 3. Example project structure

```text
/home/ansibleadmin/automation/
├── ansible.cfg
├── inventory/
│   └── nodes
├── playbooks/
├── roles/
└── collections/
```

Project directory mein `ansible.cfg` rakhne ka faida yeh hai ke project apni required settings ke saath self-contained hota hai.

Project directory mein jayein:

```bash
cd /home/ansibleadmin/automation
```

---

## 4. Complete ansible.cfg example

```ini
[defaults]
inventory = ./inventory/nodes
host_key_checking = True
remote_user = ansibleadmin
ask_pass = False
private_key_file = /home/ansibleadmin/.ssh/ansible-key
roles_path = ./roles
collections_paths = ./collections

[privilege_escalation]
become_method = sudo
become_user = root
become_ask_pass = False
```

> Agar aap ki inventory file ka naam sirf `inventory` hai aur woh project root mein hai, to `inventory = ./inventory` use karein. Path apni actual directory structure ke mutabiq hona chahiye.

---

## 5. `[defaults]` section

```ini
[defaults]
```

Yeh Ansible ki general/default settings ka section hai. Inventory, SSH user, private key, roles aur collections jaisi settings is section mein likhi jati hain.

Section name square brackets mein hota hai. Us ke neeche `key = value` format mein settings hoti hain.

Example:

```ini
remote_user = ansibleadmin
```

Equal sign ke dono taraf spaces optional hain, lekin readability ke liye yeh style behtar hai:

```ini
key = value
```

---

## 6. `inventory` setting

```ini
inventory = ./inventory/nodes
```

Yeh Ansible ko batati hai ke hosts aur groups ki inventory kahan se read karni hai.

`./` ka matlab current project directory hai.

Agar current directory yeh hai:

```text
/home/ansibleadmin/automation
```

To:

```text
./inventory/nodes
```

ka complete path hoga:

```text
/home/ansibleadmin/automation/inventory/nodes
```

Configuration mein inventory define hone ke baad command short ho jati hai:

```bash
ansible all -m ping
```

Inventory configured na ho to:

```bash
ansible all -m ping -i ./inventory/nodes
```

Inventory path check karein:

```bash
ansible-inventory --graph
```

---

## 7. `host_key_checking` setting

```ini
host_key_checking = True
```

Is ka matlab Ansible managed node ki SSH host key verify karega.

SSH host key managed server ki identity hoti hai. Agar host key unexpected tarah change ho jaye to SSH warning deta hai. Yeh man-in-the-middle attack ya rebuilt VM ki nishani ho sakti hai.

Pehli martaba fingerprint manually verify aur accept karne ke liye:

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node1
```

Practice lab mein kabhi yeh use hota hai:

```ini
host_key_checking = False
```

Lekin production aur security-focused lab mein `True` behtar hai.

Known host entry check karein:

```bash
ssh-keygen -F node1
```

Outdated entry remove karni ho to:

```bash
ssh-keygen -R node1
```

IP ke liye:

```bash
ssh-keygen -R 192.168.1.154
```

Fingerprint verify kiye baghair blindly accept na karein.

---

## 8. `remote_user` setting

```ini
remote_user = ansibleadmin
```

Yeh default SSH login user set karti hai.

Ansible ka connection conceptually is command jaisa hai:

```bash
ssh ansibleadmin@node1
```

Test:

```bash
ansible all -m command -a "whoami"
```

Expected output:

```text
ansibleadmin
```

Command line par doosra user specify karna ho to:

```bash
ansible all -m ping -u anotheruser
```

Inventory mein host/group specific user:

```ini
ansible_user=ansibleadmin
```

Inventory variable applicable hosts ke liye configuration ke `remote_user` ko override kar sakti hai.

---

## 9. `ask_pass` setting

```ini
ask_pass = False
```

Is ka matlab Ansible SSH login password nahin poochega. Ansible assume karega ke SSH key authentication configured hai.

Manual key test:

```bash
ssh -i /home/ansibleadmin/.ssh/ansible-key ansibleadmin@node1
```

Agar bina password ke login ho jaye to key authentication kaam kar rahi hai.

Password prompt temporary enable karna ho to:

```bash
ansible all -m ping --ask-pass
```

Short option:

```bash
ansible all -m ping -k
```

SSH key authentication automation ke liye zyada suitable hai.

---

## 10. `private_key_file` setting

```ini
private_key_file = /home/ansibleadmin/.ssh/ansible-key
```

Yeh Ansible ko batati hai ke SSH connection ke liye kaunsi private key use karni hai.

Is ke barabar manual command:

```bash
ssh -i /home/ansibleadmin/.ssh/ansible-key ansibleadmin@node1
```

Key files check karein:

```bash
ls -l /home/ansibleadmin/.ssh/ansible-key*
```

Typical permissions:

```bash
chmod 600 /home/ansibleadmin/.ssh/ansible-key
chmod 644 /home/ansibleadmin/.ssh/ansible-key.pub
```

Private key kisi ke saath share na karein. Managed node ke `authorized_keys` mein sirf public key copy hoti hai.

Command line se key specify karni ho to:

```bash
ansible all -m ping --private-key ~/.ssh/ansible-key
```

---

## 11. `roles_path` aur `collections_paths`

### Roles path

```ini
roles_path = ./roles
```

Yeh Ansible ko batata hai ke local roles kahan search karni hain.

Role aik reusable automation structure hoti hai, jismein tasks, handlers, templates, files aur variables organized form mein rakhe jate hain.

Example:

```text
roles/
└── webserver/
    ├── tasks/
    ├── handlers/
    ├── templates/
    ├── files/
    └── defaults/
```

### Collections path

```ini
collections_paths = ./collections
```

Collection modules, plugins aur roles ka packaged collection hoti hai.

Configured values check karein:

```bash
ansible-config dump --only-changed | grep -E 'COLLECTIONS_PATHS|DEFAULT_ROLES_PATH'
```

> Option ka naam `collections_paths` plural hai, jabke `roles_path` singular hai.

---

## 12. `[privilege_escalation]` section

```ini
[privilege_escalation]
```

Yeh section control karta hai ke Ansible normal SSH user se privileged user kaise banega.

Normal connection:

```text
Control node → SSH → ansibleadmin
```

Privilege escalation ke saath:

```text
Control node → SSH → ansibleadmin → sudo → root
```

---

## 13. `become`, sudo aur root

### `become_method`

```ini
become_method = sudo
```

Ansible privilege escalation ke liye `sudo` use karega.

### `become_user`

```ini
become_user = root
```

Privilege escalation ke baad target account `root` hoga.

### `become_ask_pass`

```ini
become_ask_pass = False
```

Ansible sudo password prompt nahin karega. Is ke liye managed nodes par passwordless sudo configured hona chahiye.

Direct test:

```bash
sudo -n whoami
```

Expected:

```text
root
```

`-n` ka matlab non-interactive hai: password required ho to command prompt karne ke bajaye fail ho jati hai.

### Normal vs become command

Normal user:

```bash
ansible all -m command -a "whoami"
```

Expected:

```text
ansibleadmin
```

Root user:

```bash
ansible all -b -m command -a "whoami"
```

Expected:

```text
root
```

`-b` ka full form `--become` hai.

Sudo password prompt chahiye ho to:

```bash
ansible all -b -K -m command -a "whoami"
```

`-K` ka matlab `--ask-become-pass` hai.

### Optional `become` setting

Agar har task ke liye automatically privilege escalation chahiye ho:

```ini
become = True
```

Lekin learning lab mein isay omit karna behtar ho sakta hai. Phir aap normal aur privileged commands ka farq clearly `-b` ke through dekh sakte hain.

---

## 14. Configuration search order

Ansible aam tor par configuration file is order mein dhoondta hai:

1. `ANSIBLE_CONFIG` environment variable mein diya hua path
2. Current directory ka `ansible.cfg`
3. User home directory ka `~/.ansible.cfg`
4. System-level `/etc/ansible/ansible.cfg`

Ansible pehli milne wali valid configuration file use karta hai. Yeh tamam files ko merge nahin karta.

### 1. Environment variable

```bash
export ANSIBLE_CONFIG=/home/ansibleadmin/automation/ansible.cfg
```

Check:

```bash
echo "$ANSIBLE_CONFIG"
```

Temporary value remove karne ke liye:

```bash
unset ANSIBLE_CONFIG
```

### 2. Current-directory configuration

```text
./ansible.cfg
```

Project-specific configuration ke liye yeh recommended approach hai.

### 3. User-level configuration

```text
~/.ansible.cfg
```

Yeh specific Linux user ke liye apply hoti hai.

### 4. System-level configuration

```text
/etc/ansible/ansible.cfg
```

Yeh system-wide fallback configuration hoti hai.

### Important note

Current directory world-writable ho to Ansible security reasons ki wajah se wahan ka `ansible.cfg` automatically use na kare. Project directory ki ownership aur permissions theek rakhein.

---

## 15. Configuration precedence ka basic concept

Ansible settings mukhtalif jagahon se aa sakti hain. General learning rule:

```text
Configuration default
        ↓
Command-line option
        ↓
Playbook keyword
        ↓
Inventory/Ansible variable
```

Lekin Ansible ka complete precedence system detailed hai aur har category ke apne rules hain. Practical examples:

### SSH user example

Configuration:

```ini
remote_user = ansibleadmin
```

Inventory:

```ini
node1 ansible_user=khalid
```

`node1` par applicable `ansible_user=khalid`, configuration ke default remote user ko override karega.

### Inventory command-line override

```bash
ansible all -m ping -i ./different-inventory
```

Yahan `-i` command ke liye different inventory select karta hai.

### Private key override

```bash
ansible all -m ping --private-key ~/.ssh/another-key
```

Ansible variables aam tor par configuration settings aur command-line options se zyada precedence rakh sakti hain. Is liye troubleshooting mein effective variables check karna zaroori hai.

---

## 16. Active configuration kaise check karein

### Ansible version output

```bash
ansible --version
```

Important line:

```text
config file = /home/ansibleadmin/automation/ansible.cfg
```

Agar yeh `/etc/ansible/ansible.cfg` show kare, to mumkin hai:

- Aap project directory mein nahin hain.
- Project configuration filename/path ghalat hai.
- File permissions ya directory security ka masla hai.
- `ANSIBLE_CONFIG` kisi aur path ko point kar raha hai.

### Current directory

```bash
pwd
```

### Environment override

```bash
echo "${ANSIBLE_CONFIG:-not set}"
```

---

## 17. Configuration test karne ke commands

### Changed settings display karein

```bash
ansible-config dump --only-changed
```

### Complete effective configuration

```bash
ansible-config dump
```

### Configuration options ki list

```bash
ansible-config list
```

### Example configuration generate karein

```bash
ansible-config init --disabled > ansible.cfg.example
```

Yeh commented/disabled example file generate kar sakta hai. Apni active `ansible.cfg` ko accidentally overwrite na karein.

### Inventory graph

```bash
ansible-inventory --graph
```

### Host variables

```bash
ansible-inventory --host node1
```

### Host list

```bash
ansible all --list-hosts
```

### Connectivity

```bash
ansible all -m ping
```

### SSH user test

```bash
ansible all -m command -a "whoami"
```

### Privilege escalation test

```bash
ansible all -b -m command -a "whoami"
```

---

## 18. Common problems aur troubleshooting

### Problem: `No inventory was parsed`

Check:

```bash
pwd
ls -l ./inventory/nodes
ansible --version
ansible-inventory --graph
```

`inventory` setting ke path ko actual file se compare karein.

### Problem: Wrong configuration file use ho rahi hai

```bash
ansible --version
echo "${ANSIBLE_CONFIG:-not set}"
pwd
```

Project directory mein ja kar dobara check karein:

```bash
cd /home/ansibleadmin/automation
ansible --version
```

### Problem: SSH password poocha ja raha hai

Direct key login test karein:

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node1
```

Check karein:

- Private key ka correct path.
- Private key permissions.
- Public key remote `authorized_keys` mein mojood hai.
- Remote user sahi hai.

### Problem: `Permission denied (publickey)`

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/ansible-key
ssh -vvv -i ~/.ssh/ansible-key ansibleadmin@node1
```

Verbose output batata hai ke client kaunsi keys try kar raha hai.

### Problem: Host-key verification failed

Pehle reason samjhein. Agar VM legitimately rebuild hui hai aur fingerprint verify ho gaya hai:

```bash
ssh-keygen -R node1
ssh-keygen -R 192.168.1.154
ssh -i ~/.ssh/ansible-key ansibleadmin@node1
```

### Problem: Become/sudo fail ho raha hai

```bash
ansible all -m command -a "sudo -n whoami"
```

Managed node par direct test:

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node1
sudo -n whoami
```

### Problem: Python interpreter warning

Inventory mein explicitly define kar sakte hain:

```ini
[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

Remote path verify karein:

```bash
ansible all -m raw -a "command -v python3"
```

`raw` module remote Python par depend nahin karta.

---

## 19. Security recommendations

- Ansible commands normal administrative user se run karein, `root` login se nahin.
- Managed nodes ke liye SSH keys use karein.
- Private key kisi student ya doosre user ke saath share na karein.
- Har administrator/student ki apni public key install karna behtar hai.
- `host_key_checking = True` ko production mein enable rakhein.
- Sudo access sirf required commands tak limit karna production mein full `NOPASSWD:ALL` se behtar ho sakta hai.
- `ansible.cfg`, inventory aur playbooks ko version control mein rakhein.
- Private keys, passwords aur vault secrets ko Git mein commit na karein.
- Sensitive variables ke liye Ansible Vault use karein.
- Configuration change ke baad `ansible-config dump --only-changed` se verification karein.

---

## 20. Quick reference table

| Setting/command | Roman Urdu meaning |
|---|---|
| `[defaults]` | General/default settings ka section |
| `inventory` | Hosts wali inventory ka path |
| `host_key_checking` | SSH server identity verify karni hai ya nahin |
| `remote_user` | Default SSH login user |
| `ask_pass` | SSH password prompt karna hai ya nahin |
| `private_key_file` | SSH private key ka path |
| `roles_path` | Roles search directory |
| `collections_paths` | Collections search directories |
| `[privilege_escalation]` | Privileged user banne ki settings |
| `become_method` | Privilege escalation method, jaise `sudo` |
| `become_user` | Escalation ke baad target user |
| `become_ask_pass` | Sudo password prompt karna hai ya nahin |
| `-b` | `--become` enable karta hai |
| `-K` | Sudo/become password poochta hai |
| `-k` | SSH login password poochta hai |
| `-i` | Command ke liye inventory select karta hai |
| `-u` | Command ke liye remote user select karta hai |
| `ansible --version` | Active config file aur versions dikhata hai |
| `ansible-config dump --only-changed` | Changed effective settings dikhata hai |
| `ansible-inventory --graph` | Inventory hierarchy dikhata hai |
| `ansible all -m ping` | Ansible connectivity test karta hai |

## Final summary

Inventory ka jawab hai:

> **Kin machines ko manage karna hai?**

`ansible.cfg` ka jawab hai:

> **Un machines se connect aur unko manage kaise karna hai?**

Recommended workflow:

```bash
cd /home/ansibleadmin/automation
ansible --version
ansible-config dump --only-changed
ansible-inventory --graph
ansible all -m ping
ansible all -m command -a "whoami"
ansible all -b -m command -a "whoami"
```

Is sequence se aap configuration file selection, effective settings, inventory, SSH connectivity, remote user aur privilege escalation sab verify kar lete hain.
