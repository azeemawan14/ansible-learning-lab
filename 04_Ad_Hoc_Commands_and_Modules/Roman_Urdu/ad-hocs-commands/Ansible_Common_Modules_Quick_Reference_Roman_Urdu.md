# Ansible Common Modules — Roman Urdu Quick Reference

## Fehrist (Table of Contents)

1. [Is guide ka maqsad](#1-is-guide-ka-maqsad)
2. [`ansible-doc` ka istemal](#2-ansible-doc-ka-istemal)
3. [Common modules ka reference](#3-common-modules-ka-reference)
4. [Sahi module select karne ki guide](#4-sahi-module-select-karne-ki-guide)
5. [Collection-based modules](#5-collection-based-modules)
6. [Personal lab ke practice commands](#6-personal-lab-ke-practice-commands)
7. [Safety aur idempotency](#7-safety-aur-idempotency)
8. [Quick revision questions](#8-quick-revision-questions)

---

## 1. Is guide ka maqsad

Ansible **module** code ka ek reusable unit hota hai jo managed node par koi khaas kaam karta hai—jaise file copy karna, package install karna, user banana ya service start karna.

Is guide mein aapke lab ki yeh information istemal ki gayi hai:

- Inventory group: `three_tier_app`
- Managed nodes: `node1`, `node2`, aur `node3`
- Remote user: `ansibleadmin`
- Managed nodes ka OS: Rocky Linux
- Tez typing ke liye short module names

Ad-hoc command ka aam structure:

```bash
ansible <host-pattern> [-b] -m <module> -a "<arguments>"
```

| Hissa | Matlab |
|---|---|
| `three_tier_app` | Inventory ka host ya group pattern |
| `-b` | Privilege escalation yani `become` istemal karein |
| `-m` | Module select karein |
| `-a` | Module ko arguments dein |

---

## 2. `ansible-doc` ka istemal

### Module ki mukammal documentation dekhein

```bash
ansible-doc copy
```

### Short syntax aur main options dekhein

```bash
ansible-doc -s copy
```

### Tamam available modules ki list dekhein

```bash
ansible-doc -l
```

### Module list mein search karein

```bash
ansible-doc -l | grep -i mount
```

Full documentation mein examples dhoondhne ke liye:

```bash
ansible-doc copy
```

Output ke andar yeh type karein:

```text
/EXAMPLES
```

Documentation viewer se bahar nikalne ke liye `q` press karein.

> **Behtar tareeqa:** Sirf main parameters aur syntax chahiye ho to `ansible-doc -s <module>` chalayein. Tafseeli description, notes, requirements aur examples ke liye `ansible-doc <module>` chalayein.

---

## 3. Common modules ka reference

| # | Module | Ek-line definition aur istemal | Documentation command |
|---:|---|---|---|
| 1 | `copy` | Control node se file ya content managed nodes par copy karta hai. | `ansible-doc copy` |
| 2 | `command` | Shell istemal kiye baghair seedha command execute karta hai. | `ansible-doc command` |
| 3 | `raw` | Managed node par Python ki zaroorat ke baghair command seedha SSH ke zariye bhejta hai. | `ansible-doc raw` |
| 4 | `shell` | Shell ke zariye command chalata hai aur pipes, redirects, variables aur command chaining support karta hai. | `ansible-doc shell` |
| 5 | `file` | Files, directories, links, ownership, permissions aur file state manage karta hai. | `ansible-doc file` |
| 6 | `fetch` | Managed nodes se files control node par download karta hai. | `ansible-doc fetch` |
| 7 | `get_url` | HTTP, HTTPS ya FTP URL se file managed node par download karta hai. | `ansible-doc get_url` |
| 8 | `lineinfile` | Text file mein ek khaas line add, replace ya remove karta hai. | `ansible-doc lineinfile` |
| 9 | `replace` | File ke andar regular expression se match hone wale tamam text ko replace karta hai. | `ansible-doc replace` |
| 10 | `user` | User accounts create, modify, lock ya remove karta hai. | `ansible-doc user` |
| 11 | `group` | Operating-system groups create, modify ya remove karta hai. | `ansible-doc group` |
| 12 | `yum` / `dnf` / `apt` | Khaas package manager ke zariye packages install, update ya remove karta hai. | `ansible-doc dnf` |
| 13 | `yum_repository` | YUM/DNF repository definition add, modify, enable, disable ya remove karta hai. | `ansible-doc yum_repository` |
| 14 | `package` | Managed node par detect hone wale package manager ke zariye packages manage karta hai. | `ansible-doc package` |
| 15 | `stat` | Baghair tabdeeli kiye file, directory ya symbolic link ki information hasil karta hai. | `ansible-doc stat` |
| 16 | `mount` | Active filesystem mounts aur `/etc/fstab` entries manage karta hai. | `ansible-doc mount` |
| 17 | `setup` | Managed nodes se system information jama karta hai jise Ansible facts kehte hain. | `ansible-doc setup` |
| 18 | `service` | Generic interface se services start, stop, restart, enable ya disable karta hai. | `ansible-doc service` |
| 19 | `systemd` | Systemd services, units, daemon reload aur masking manage karta hai. | `ansible-doc systemd` |
| 20 | `debug` | Playbook ke andar variables, values aur custom messages display karta hai. | `ansible-doc debug` |
| 21 | `uri` | Managed node se websites aur APIs ko HTTP/HTTPS requests bhejta hai. | `ansible-doc uri` |
| 22 | `parted` | Disk partitions create, modify, resize ya remove karta hai. | `ansible-doc parted` |
| 23 | `filesystem` | Block device par XFS ya ext4 jaisa filesystem banata hai. | `ansible-doc filesystem` |
| 24 | `lvg` | LVM volume group create, modify ya remove karta hai. | `ansible-doc lvg` |
| 25 | `lvol` | LVM logical volume create, resize ya remove karta hai. | `ansible-doc lvol` |
| 26 | `cron` | Scheduled cron jobs create, modify ya remove karta hai. | `ansible-doc cron` |

---

## 4. Sahi module select karne ki guide

### 4.1 `command` vs `shell` vs `raw`

| Module | Kab istemal karein | Aham baat |
|---|---|---|
| `command` | `uptime`, `lsblk` ya `hostname` jaisa normal executable chalana ho | `|`, `>`, `&&`, `;`, `$VAR` aur shell wildcards interpret nahi karta |
| `shell` | Command ko pipes, redirects, shell variables ya multiple commands ki zaroorat ho | Shell ke zariye chalta hai, is liye input ehtiyat se dein |
| `raw` | Managed node par Python missing ho ya kaam na kar raha ho | Normal Python-based module system ko bypass karta hai |

```bash
ansible three_tier_app -m command -a "uptime"
ansible three_tier_app -m shell -a "uptime; lsblk"
ansible three_tier_app -m raw -a "command -v python3"
```

Yeh command fail hogi kyun ke `command` module `uptime;` ko executable ka naam samjhega:

```bash
ansible three_tier_app -m command -a "uptime; lsblk"
```

### 4.2 `service` vs `systemd`

| Module | Behtar istemal |
|---|---|
| `service` | Mukhtalif init systems par portable service management |
| `systemd` | Systemd-specific features, jaise `daemon_reload` aur masking |

### 4.3 `package` vs `dnf`/`yum`/`apt`

| Module | Behtar istemal |
|---|---|
| `package` | Aisi portable playbooks jo mukhtalif Linux distributions par chal sakein |
| `dnf` ya `yum` | RHEL, Rocky Linux, AlmaLinux ya Fedora ke specific options |
| `apt` | Debian ya Ubuntu ke specific package options |

### 4.4 `lineinfile` vs `replace`

| Module | Behtar istemal |
|---|---|
| `lineinfile` | Configuration file ki ek specific line manage karna |
| `replace` | Regular expression se match hone wala tamam text replace karna |

---

## 5. Collection-based modules

Kuch modules sirf `ansible-core` ka hissa nahi hote, balkeh collections ke zariye milte hain.

| Short name | Collection name |
|---|---|
| `mount` | `ansible.posix.mount` |
| `parted` | `community.general.parted` |
| `filesystem` | `community.general.filesystem` |
| `lvg` | `community.general.lvg` |
| `lvol` | `community.general.lvol` |

Check karein ke modules available hain ya nahi:

```bash
ansible-doc -l | grep -E 'mount|parted|filesystem|lvg|lvol'
```

Installed collections ki list:

```bash
ansible-galaxy collection list
```

Zaroorat ho to collections install karein:

```bash
ansible-galaxy collection install ansible.posix community.general
```

Jab required collection installed ho aur Ansible module ko resolve kar sake to aap short names istemal kar sakte hain. Fully qualified collection name ambiguity door karne ya documentation ke mutabiq exact module batane mein madad deta hai.

---

## 6. Personal lab ke practice commands

> Users, disks, LVM, repositories, services ya cron jobs ko modify karne wale commands chalane se pehle unhein zaroor review karein.

### 6.1 Content copy karein

```bash
ansible three_tier_app -m copy \
  -a 'content="Hello from Ansible\n" dest=/tmp/hello.txt mode=0644'
```

### 6.2 Simple command chalayein

```bash
ansible three_tier_app -m command -a "uptime"
```

### 6.3 `raw` se Python check karein

```bash
ansible three_tier_app -m raw -a "command -v python3"
```

### 6.4 `shell` ke zariye pipe istemal karein

```bash
ansible three_tier_app -m shell -a "ps -ef | systemctl is-active sshd"
```

### 6.5 Directory banayein

```bash
ansible three_tier_app -m file \
  -a "path=/tmp/ansible-lab state=directory mode=0755"
```

### 6.6 File control node par fetch karein

```bash
ansible three_tier_app -m fetch \
  -a "src=/tmp/hello.txt dest=./lab-output/"
```

`fetch` aam tor par destination ke andar har host ki alag directory banata hai taa-ke same-name files overwrite na hon.

### 6.7 URL se file download karein

```bash
ansible three_tier_app -m get_url \
  -a "url=https://example.com/ dest=/tmp/example.html mode=0644"
```

### 6.8 SSH banner ki line manage karein

```bash
ansible three_tier_app -b -m lineinfile -a \
  'path=/etc/ssh/sshd_config regexp="^\s*#?\s*Banner\s+.*$" line="Banner /etc/ssh/banner.txt" backup=yes validate="/usr/sbin/sshd -t -f %s"'
```

### 6.9 Matching text replace karein

```bash
ansible three_tier_app -m replace \
  -a 'path=/tmp/hello.txt regexp="Ansible" replace="Automation" backup=yes'
```

### 6.10 Practice user banayein

```bash
ansible three_tier_app -b -m user \
  -a "name=labuser state=present create_home=yes shell=/bin/bash"
```

### 6.11 Practice group banayein

```bash
ansible three_tier_app -b -m group \
  -a "name=labgroup state=present"
```

### 6.12 Rocky Linux par package install karein

```bash
ansible three_tier_app -b -m dnf \
  -a "name=httpd state=present"
```

### 6.13 DNF repository module ka syntax dekhein

```bash
ansible-doc -s yum_repository
```

Repository change package sources ko affect karta hai. Trusted URL istemal karein aur pehle sirf `node1` par test karein:

```bash
ansible three_tier_app -b -m yum_repository --limit node1 -a \
  'name=example description="Example Repository" baseurl=https://repo.example.com/rocky/9/x86_64 enabled=no gpgcheck=yes'
```

### 6.14 Generic `package` module se Git install karein

```bash
ansible three_tier_app -b -m package \
  -a "name=git state=present"
```

### 6.15 File ki information hasil karein

```bash
ansible three_tier_app -m stat \
  -a "path=/tmp/hello.txt"
```

### 6.16 Mount module ka syntax dekhein

```bash
ansible-doc -s mount
```

Prepared device aur mount point ki misaal:

```bash
ansible three_tier_app -b -m mount --limit node1 -a \
  "path=/data src=/dev/mapper/vg_lab-lv_data fstype=xfs state=mounted"
```

### 6.17 Operating-system facts jama karein

```bash
ansible three_tier_app -m setup -a "filter=ansible_distribution*"
```

### 6.18 Generic interface se service manage karein

```bash
ansible three_tier_app -b -m service \
  -a "name=sshd state=started enabled=yes"
```

### 6.19 Systemd service manage karein

```bash
ansible three_tier_app -b -m systemd \
  -a "name=sshd state=restarted enabled=yes"
```

### 6.20 `debug` se variable display karein

`debug` zyada tar playbooks ke andar istemal hota hai:

```yaml
- name: Inventory hostname display karein
  debug:
    var: inventory_hostname
```

### 6.21 Web endpoint check karein

```bash
ansible web -m uri \
  -a "url=http://localhost status_code=200 return_content=no"
```

### 6.22–6.25 Storage modules

Ghalat device select hone par yeh modules data destroy kar sakte hain:

```bash
ansible-doc -s parted
ansible-doc -s filesystem
ansible-doc -s lvg
ansible-doc -s lvol
```

Pehle ek node ke disks verify karein:

```bash
ansible three_tier_app -m command -a "lsblk -f" --limit node1
```

Aam storage workflow:

1. `parted` partition banata hai.
2. `lvg` volume group banata hai.
3. `lvol` logical volume banata hai.
4. `filesystem` filesystem banata hai.
5. `mount` filesystem mount karta aur `/etc/fstab` manage karta hai.

### 6.26 Cron job banayein

```bash
ansible three_tier_app -b -m cron -a \
  'name="daily lab cleanup" minute=0 hour=0 job="/usr/local/sbin/lab-cleanup.sh" state=present'
```

---

## 7. Safety aur idempotency

### Idempotency kya hai?

Operation **idempotent** tab hota hai jab usko baar-baar chalane se system requested state mein rahe aur be-wajah dobara change report na ho.

`copy`, `file`, `user`, `group`, `dnf`, `service` aur `lineinfile` jaise modules aam tor par change se pehle current state check karte hain.

`command`, `shell` aur `raw` hamesha yeh nahi samajh sakte ke command ne system change kiya ya nahi. Is liye yeh execute hone par `CHANGED` report kar sakte hain.

### Support available ho to `--check` istemal karein

```bash
ansible three_tier_app -b -m dnf \
  -a "name=httpd state=present" --check
```

Har module aur command complete check-mode support nahi karta.

### Pehle ek node par test karein

```bash
ansible three_tier_app -b -m dnf \
  -a "name=httpd state=present" --limit node1
```

### `-b` sirf zaroorat ke waqt istemal karein

Package installation, service management, user management aur `/etc` ke andar changes ke liye administrative privileges chahiye hote hain. Aise kaamon ke liye `-b` istemal karein.

---

## 8. Quick revision questions

1. Control node ki local file managed nodes par kaunsa module copy karta hai?
2. Managed nodes se file control node par kaunsa module lata hai?
3. `command` module `|`, `>` aur `;` ko process kyun nahi karta?
4. `raw` ko `command` ki jagah kab istemal karna chahiye?
5. `lineinfile` aur `replace` mein kya farq hai?
6. `package` aur `dnf` mein kya farq hai?
7. Ansible facts kaunsa module collect karta hai?
8. Aam LVM storage workflow mein kaun se modules istemal hote hain?
9. Storage command pehle `--limit node1` ke saath kyun test karna chahiye?
10. `shell` har execution par `CHANGED` kyun report kar sakta hai?

### Mukhtasar jawab

1. `copy`
2. `fetch`
3. Kyun ke woh shell ke baghair program seedha execute karta hai.
4. Jab managed node par Python missing ho ya kaam na kar raha ho.
5. `lineinfile` ek specific line manage karta hai; `replace` tamam matching text ko change karta hai.
6. `package` generic hai; `dnf` DNF-specific behavior aur options deta hai.
7. `setup`
8. `parted`, `lvg`, `lvol`, `filesystem` aur `mount`
9. Risk kam karne aur sab nodes par apply karne se pehle operation verify karne ke liye.
10. Kyun ke yeh aam tor par determine nahi kar sakta ke arbitrary shell command ne system change kiya ya nahi.

---

## Aakhri recommendation

Har module ke tamam parameters yaad karne ki zaroorat nahi. Har module ka maqsad samjhein, common arguments ki practice karein, aur exact syntax ki zaroorat par `ansible-doc -s <module>` istemal karein.
