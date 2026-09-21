# Ansible Common Modules — Combined Hands-On Lab (Roman Urdu)

## Lab ka Maqsad

Is lab mein Rocky Linux environment par common Ansible modules ko step-by-step practice kiya jayega. Har important change ke baad verification, idempotency test aur akhir mein complete cleanup bhi ki jayegi.

## Index

1. [Lab environment](#1-lab-environment)
2. [Modules jo cover honge](#2-modules-jo-cover-honge)
3. [Safety rules](#3-safety-rules)
4. [Phase 1 — Pre-checks](#4-phase-1--pre-checks)
5. [Phase 2 — Command, shell aur raw](#5-phase-2--command-shell-aur-raw)
6. [Phase 3 — File, copy, stat aur fetch](#6-phase-3--file-copy-stat-aur-fetch)
7. [Phase 4 — Lineinfile aur replace](#7-phase-4--lineinfile-aur-replace)
8. [Phase 5 — Get URL](#8-phase-5--get-url)
9. [Phase 6 — Package management](#9-phase-6--package-management)
10. [Phase 7 — User aur group management](#10-phase-7--user-aur-group-management)
11. [Phase 8 — Mount module](#11-phase-8--mount-module)
12. [Phase 9 — Setup aur facts](#12-phase-9--setup-aur-facts)
13. [Phase 10 — Complete cleanup](#13-phase-10--complete-cleanup)
14. [Final verification](#14-final-verification)
15. [Module summary](#15-module-summary)
16. [Practice questions](#16-practice-questions)

---

## 1. Lab Environment

| Role | Host | IP address | Inventory group |
|---|---|---|---|
| Control node | `ansible-server` | `192.168.1.233` | `control`, agar configured ho |
| Web node | `node1` | `192.168.1.154` | `web` |
| Application node | `node2` | `192.168.1.185` | `app` |
| Database node | `node3` | `192.168.1.190` | `db` |

Parent group `three_tier_app` mein `web`, `app` aur `db` groups hone chahiye.

`ansibleadmin` user se shuru karein:

```bash
cd ~/automation
whoami
pwd
```

Expected user:

```text
ansibleadmin
```

---

## 2. Modules Jo Cover Honge

| Module | Kaam |
|---|---|
| `ping` | Ansible connectivity test karna |
| `command` | Shell ke baghair simple command chalana |
| `raw` | SSH se direct command bhejna |
| `shell` | Shell ke through command chalana |
| `file` | Files, directories, links aur permissions manage karna |
| `copy` | Control node se managed nodes par file copy karna |
| `fetch` | Managed nodes se control node par file lana |
| `get_url` | URL se managed node par file download karna |
| `lineinfile` | Text file mein ek line manage karna |
| `replace` | Regular expression se text replace karna |
| `group` | Linux groups manage karna |
| `user` | Linux users manage karna |
| `dnf` | Modern Rocky/RHEL packages manage karna |
| `yum` | Yum-compatible package interface use karna |
| `package` | OS-independent package management |
| `stat` | File ya directory ki information lena |
| `mount` | Mounts aur `/etc/fstab` entries manage karna |
| `setup` | System facts gather karna |
| `debug` | Variables aur messages display karna |

Is lab mein short module names use kiye gaye hain.

---

## 3. Safety Rules

1. Commands sirf assigned lab nodes par run karein.
2. Enter press karne se pehle target group zaroor check karein.
3. `-b` sirf wahan use karein jahan root privileges zaroori hon.
4. SSH, firewall, SELinux, network aur hostname settings change na karein.
5. Lab ke unique names `ansible-lab`, `ansiblelab` aur `ansible_lab` hain.
6. Lab se pehle check karein ke `tree` installed tha ya nahi. Cleanup mein sirf tab remove karein jab lab ne install kiya ho.
7. Akhir mein complete cleanup lazmi karein.

---

## 4. Phase 1 — Pre-Checks

### Step 1: Configuration aur inventory verify karein

```bash
ansible --version
ansible-config dump --only-changed
ansible-inventory --graph
ansible three_tier_app --list-hosts
```

Expected managed hosts:

```text
node1
node2
node3
```

### Step 2: `ping` module se connectivity test karein

```bash
ansible three_tier_app -m ping
```

Har node ko yeh result dena chahiye:

```text
"changed": false,
"ping": "pong"
```

Teenon nodes par `SUCCESS` aane se pehle aglay phase par na jayen.

### Step 3: Remote account confirm karein

```bash
ansible three_tier_app -m command -a "whoami"
```

Expected:

```text
ansibleadmin
```

---

## 5. Phase 2 — Command, Shell aur Raw

### Step 1: `command` use karein

```bash
ansible three_tier_app -m command -a "uptime"
ansible three_tier_app -m command -a "uname -r"
```

Jab pipe, redirection, variable expansion ya doosre shell features ki zaroorat na ho to `command` prefer karein.

### Step 2: `shell` use karein

```bash
ansible three_tier_app -m shell -a "ps -ef | systemctl is-active sshd"
```

Pipe `|` shell operator hai, is liye yahan `shell` module chahiye.

### Step 3: `raw` use karein

```bash
ansible three_tier_app -m raw -a "id"
```

`raw` command ko normal Python-based module subsystem ke baghair direct connection se bhejta hai. Isay aksar Python bootstrap karne ke liye use kiya jata hai.

### Comparison

| Feature | `command` | `shell` | `raw` |
|---|---|---|---|
| Linux command execute karta hai | Haan | Haan | Haan |
| Normal Ansible module subsystem | Haan | Haan | Nahi |
| Remote Python required | Aam tor par haan | Aam tor par haan | Nahi |
| Processes `;`,`>`, and `&& | Nahi | Haan | Aam tor par haan |
| Best use | Ordinary commands | Shell features wale commands | Python bootstrap ya emergency access |
| Safety | Safest default | Carefully use karein | Sirf zaroorat par |

### `command` multiple commands kyun nahi chala sakta?

Yeh command use na karein:

```bash
ansible three_tier_app -m command -a "uptime; lsblk"
```

`command` semicolon ko shell separator nahi samajhta. Woh `;` aur `lsblk` ko `uptime` ke arguments samajh sakta hai aur command fail ho sakti hai.

Multiple commands ke liye:

```bash
ansible three_tier_app -m shell -a "uptime; lsblk"
```

`raw` ke saath:

```bash
ansible three_tier_app -m raw -a "uptime; lsblk"
```

`uptime` aur `lsblk` Linux commands hain, Ansible modules nahi.

### Python missing ho to `raw`

```bash
ansible node1 -m raw -a "command -v python3 || echo 'Python is missing'"
```

Approved Rocky Linux node par Python missing ho to:

```bash
ansible node1 -m raw -a "dnf install -y python3" -b
```

Python available hone ke baad regular modules use karein, kyun ke woh structured results aur behtar idempotency dete hain.

> “Python 2.4 or later” wali statement outdated hai. Modern Ansible ko installed `ansible-core` ke supported Python version ki zaroorat hoti hai. Is lab mein `/usr/bin/python3` use ho raha hai.

---

## 6. Phase 3 — File, Copy, Stat aur Fetch

### Step 1: `file` se remote directory banayen

```bash
ansible three_tier_app -m file -a "path=/tmp/ansible-lab state=directory mode=0755"
```

Command dobara run karein. Doosri run par `changed=false` aana chahiye.

### Step 2: Control node par source file banayen

```bash
printf 'environment=practice\nowner=ansibleadmin\n' > module-lab.conf
cat module-lab.conf
```

### Step 3: File sab managed nodes par copy karein

```bash
ansible three_tier_app -m copy -a "src=module-lab.conf dest=/tmp/ansible-lab/module-lab.conf mode=0644"
```

Idempotency dekhne ke liye copy command dobara run karein.

### Step 4: `stat` se file inspect karein

```bash
ansible three_tier_app -m stat -a "path=/tmp/ansible-lab/module-lab.conf"
```

Output mein dekhein:

- `exists: true`
- `isreg: true`
- Mode `0644`
- File owner
- Checksum

### Step 5: Remote content display karein

```bash
ansible three_tier_app -m command -a "cat /tmp/ansible-lab/module-lab.conf"
```

### Step 6: `fetch` se file control node par layen

```bash
ansible three_tier_app -m fetch -a "src=/tmp/ansible-lab/module-lab.conf dest=./lab-output/"
```

`fetch` aam tor par `lab-output` ke andar har host ki separate directory banata hai, taa-ke same-name files overwrite na hon.

```bash
find ./lab-output -type f -name module-lab.conf -print
```

```text
copy:  control node  → managed node
fetch: managed node  → control node
```

---

## 7. Phase 4 — Lineinfile aur Replace

### Step 1: Managed line add karein

```bash
ansible three_tier_app -m lineinfile -a "path=/tmp/ansible-lab/module-lab.conf line='managed_by=ansible' state=present"
```

Dobara run karne par `changed=false` aana chahiye, kyun ke line already present hogi.

### Step 2: Text replace karein

```bash
ansible three_tier_app -m replace -a "path=/tmp/ansible-lab/module-lab.conf regexp='environment=practice' replace='environment=training'"
```

Dobara run par `changed=false` expected hai, kyun ke original text ab match nahi karega.

### Step 3: Verify karein

```bash
ansible three_tier_app -m command -a "cat /tmp/ansible-lab/module-lab.conf"
```

Expected:

```text
environment=training
owner=ansibleadmin
managed_by=ansible
```

---

## 8. Phase 5 — Get URL

`get_url` URL se file ko directly managed node par download karta hai. Is step ke liye `node1` par outbound internet access chahiye.

```bash
ansible web -m get_url -a "url=https://www.example.com/ dest=/tmp/ansible-lab/example.html mode=0644"
```

Verify:

```bash
ansible web -m stat -a "path=/tmp/ansible-lab/example.html"
```

`get_url` command dobara run karein. Agar remote content change nahi hua to Ansible ko nayi change nahi karni chahiye.

> Agar node par internet nahi hai to failure record karke phase skip karein. Download force karne ke liye TLS validation disable na karein.

---

## 9. Phase 6 — Package Management

Is phase mein `tree` package ke zariye `dnf`, `yum` aur `package` compare honge.

### Step 1: Original state record karein

```bash
ansible web -m command -a "rpm -q tree"
```

Note karein ke `tree` pehle se installed tha ya nahi.

### Step 2: `dnf` se install karein

```bash
ansible web -m dnf -a "name=tree state=present" -b
```

### Step 3: Verify karein

```bash
ansible web -m command -a "rpm -q tree"
```

### Step 4: `yum` se wohi desired state check karein

```bash
ansible web -m yum -a "name=tree state=present" -b
```

`tree` already installed hone ki wajah se normally no change expected hai.

### Step 5: `package` se check karein

```bash
ansible web -m package -a "name=tree state=present" -b
```

| Module | Behtar use |
|---|---|
| `dnf` | Modern Rocky Linux aur RHEL |
| `yum` | Yum-compatible RHEL-family environment |
| `package` | Multiple supported operating systems ki generic playbook |

Rocky Linux 9 ke liye `dnf` sab se clear choice hai.

---

## 10. Phase 7 — User aur Group Management

Is phase mein `node2` par temporary group aur user banega.

### Step 1: Group create karein

```bash
ansible app -m group -a "name=ansible_lab state=present" -b
```

### Step 2: User create karein

```bash
ansible app -m user -a "name=ansiblelab group=ansible_lab comment='Temporary Ansible Lab User' create_home=yes state=present" -b
```

Password assign nahi hua, is liye is account ko password login ke liye use na karein.

### Step 3: Verify karein

```bash
ansible app -m command -a "id ansiblelab"
ansible app -m command -a "getent group ansible_lab"
```

### Step 4: Idempotency test

`group` aur `user` creation commands dobara run karein. Dono ko normally `changed=false` report karna chahiye.

---

## 11. Phase 8 — Mount Module

Is phase mein `node3` par chhota temporary `tmpfs` mount banega. Koi disk format ya modify nahi hogi.

### Step 1: Mount point banayen

```bash
ansible db -m file -a "path=/mnt/ansible-lab state=directory mode=0755" -b
```

### Step 2: Temporary filesystem mount karein

```bash
ansible db -m mount -a "path=/mnt/ansible-lab src=tmpfs fstype=tmpfs opts=size=64m state=mounted" -b
```

`state=mounted` filesystem ko mount karta aur `/etc/fstab` entry manage karta hai.

### Step 3: Verify karein

```bash
ansible db -m command -a "findmnt /mnt/ansible-lab"
```

Expected filesystem type:

```text
tmpfs
```

### Step 4: Idempotency check

Mount command dobara run karein. Normally `changed=false` expected hai.

> Jab tak storage administration achhi tarah samajh na ho aur approved unused device na mile, `tmpfs` ko real disk device se replace na karein.

---

## 12. Phase 9 — Setup aur Facts

Distribution facts:

```bash
ansible three_tier_app -m setup -a "filter=ansible_distribution*"
```

Hostname facts:

```bash
ansible three_tier_app -m setup -a "filter=ansible_hostname"
```

Memory facts:

```bash
ansible three_tier_app -m setup -a "filter=ansible_memtotal_mb"
```

Default IPv4 facts:

```bash
ansible three_tier_app -m setup -a "filter=ansible_default_ipv4"
```

`debug` se variables:

```bash
ansible three_tier_app -m debug -a 'msg="{{ inventory_hostname }} connects to {{ ansible_host }}"'
```

| Item | Source |
|---|---|
| `inventory_hostname` | Inventory mein defined naam |
| `ansible_host` | Inventory mein defined connection address |
| `ansible_distribution` | Managed node se gathered fact |
| `ansible_default_ipv4.address` | Managed node se gathered fact |

---

## 13. Phase 10 — Complete Cleanup

Cleanup isi order mein karein.

### Step 1: Temporary user remove karein

```bash
ansible app -m user -a "name=ansiblelab state=absent remove=yes" -b
```

### Step 2: Temporary group remove karein

```bash
ansible app -m group -a "name=ansible_lab state=absent" -b
```

### Step 3: Temporary mount remove karein

```bash
ansible db -m mount -a "path=/mnt/ansible-lab state=absent" -b
```

`state=absent` filesystem unmount karta aur matching `/etc/fstab` entry remove karta hai.

### Step 4: Mount-point directory remove karein

```bash
ansible db -m file -a "path=/mnt/ansible-lab state=absent" -b
```

### Step 5: Remote lab directory remove karein

```bash
ansible three_tier_app -m file -a "path=/tmp/ansible-lab state=absent"
```

### Step 6: Local lab files remove karein

Pehle current directory aur exact paths confirm karein:

```bash
pwd
ls -ld ./lab-output ./module-lab.conf
```

Sirf lab ke banaye hue paths remove karein:

```bash
rm -r ./lab-output
rm ./module-lab.conf
```

### Step 7: `tree` package handle karein

Agar `tree` lab se pehle installed **nahi** tha to remove karein:

```bash
ansible web -m dnf -a "name=tree state=absent" -b
```

Agar package pehle se installed tha to usay installed rehne dein.

---

## 14. Final Verification

### Temporary remote paths absent hon

```bash
ansible three_tier_app -m stat -a "path=/tmp/ansible-lab"
```

Expected:

```text
"exists": false
```

### Temporary user aur group absent hon

```bash
ansible app -m shell -a "getent passwd ansiblelab || true; getent group ansible_lab || true"
```

Koi matching account ya group display nahi hona chahiye.

### Mount absent ho

```bash
ansible db -m shell -a "findmnt /mnt/ansible-lab || true"
```

Koi mounted filesystem display nahi hona chahiye.

### Final connectivity test

```bash
ansible three_tier_app -m ping
```

Teenon nodes ko `SUCCESS` return karna chahiye.

---

## 15. Module Summary

| Module | Pehli run par change? | Typical doosri run |
|---|---|---|
| `ping` | Nahi | `changed=false` |
| `command` | Command par depend; purane versions `changed` report kar sakte hain | Depend karta hai |
| `raw` | Command par depend | Depend karta hai |
| `shell` | Command par depend | Depend karta hai |
| `file` | Path create/remove ho to haan | State match ho to `changed=false` |
| `copy` | Content ya metadata different ho to haan | `changed=false` |
| `fetch` | Remote content locally copy karta hai | Destination state par depend |
| `get_url` | Download required ho to haan | Current ho to aam tor par no change |
| `lineinfile` | Line missing ho to haan | `changed=false` |
| `replace` | Expression match ho to haan | Replacement ke baad `changed=false` |
| `group` | Group create/remove ho to haan | `changed=false` |
| `user` | User create/remove ho to haan | `changed=false` |
| `dnf`, `yum`, `package` | Package state different ho to haan | `changed=false` |
| `stat` | Nahi | `changed=false` |
| `mount` | Mount state different ho to haan | `changed=false` |
| `setup` | Nahi | `changed=false` |
| `debug` | Nahi | `changed=false` |

---

## 16. Practice Questions

1. `copy` aur `fetch` mein kya farq hai?
2. Ordinary commands ke liye `shell` ke bajaye `command` kyun prefer hota hai?
3. `raw` kab useful hota hai?
4. `lineinfile` aur `replace` mein kya farq hai?
5. Package, user, group aur mount tasks ke liye `-b` kyun chahiye?
6. `dnf` aur `package` mein kya farq hai?
7. `state=present` ka kya matlab hai?
8. `state=absent` ka kya matlab hai?
9. System facts kaunsa module gather karta hai?
10. Idempotent task ki doosri run ne kya report kiya?
11. Cleanup se pehle original package state record karna kyun zaroori hai?
12. Agar poori lab repeat karni ho to ad-hoc commands ke bajaye playbook kyun behtar hai?

## Completion Checklist

- [ ] Teenon nodes ne `pong` return kiya
- [ ] Read-only commands test kiye
- [ ] Remote files aur directories create ki
- [ ] File content edit aur verify kiya
- [ ] Managed nodes se file fetch ki
- [ ] Package modules compare kiye
- [ ] Temporary user aur group create kiye
- [ ] Temporary mount create kiya
- [ ] Facts aur variables display kiye
- [ ] Idempotency observe ki
- [ ] Tamam temporary resources remove kiye
- [ ] Final connectivity test successful raha
